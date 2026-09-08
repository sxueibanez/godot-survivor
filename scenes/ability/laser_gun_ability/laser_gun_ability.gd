extends Node2D
class_name LaserGunAbility

const BEAM_START := 24.0
const BEAM_LENGTH := 260.0
const DURATION := 2.0
const FLOATING_TEXT_INTERVAL := 0.2
const STUN_HIT_INTERVAL := 0.2
const STUN_HIT_WINDOW := 1.0
const AUTO_AIM_INTERVAL := 0.1
const AUTO_AIM_RANGE := 300.0
const CLUSTER_RADIUS := 54.0
const KILL_DURATION_EXTENSION := 0.3

@export var source: Node2D
@export var damage_per_second := 8.0
@export var beam_width := 8.0
@export var damage_ramp_enabled := false
@export var reflection_enabled := false
@export var stun_enabled := false
@export var auto_aim_enabled := false
@export var kill_duration_extension_enabled := false

@onready var beam: Line2D = $Beam
@onready var collision_shape: CollisionShape2D = $LaserArea/CollisionShape2D
@onready var laser_area: Area2D = $LaserArea
@onready var bounce_collision_shape: CollisionShape2D = $LaserBounceArea/CollisionShape2D
@onready var laser_bounce_area: Area2D = $LaserBounceArea

var direction := Vector2.RIGHT
var time_left := DURATION
var floating_text_time_left := FLOATING_TEXT_INTERVAL
var damage_totals := {}
var critical_damage_totals := {}
var stun_hit_times := {}
var stun_hit_cooldowns := {}
var auto_aim_time_left := AUTO_AIM_INTERVAL


func _ready() -> void:
	rotation = direction.angle()
	beam.width = beam_width
	(collision_shape.shape as RectangleShape2D).size.y = beam_width
	(bounce_collision_shape.shape as RectangleShape2D).size.y = beam_width
	laser_bounce_area.monitoring = false


func _physics_process(delta: float) -> void:
	if !is_instance_valid(source):
		queue_free()
		return

	global_position = source.global_position
	update_auto_aim(delta)
	configure_beam()
	for area in laser_area.get_overlapping_areas():
		apply_damage(area, delta)
	if laser_bounce_area.monitoring:
		for area in laser_bounce_area.get_overlapping_areas():
			apply_damage(area, delta)

	floating_text_time_left -= delta
	if floating_text_time_left <= 0:
		show_damage_numbers()
		floating_text_time_left = FLOATING_TEXT_INTERVAL

	time_left -= delta
	if time_left <= 0:
		show_damage_numbers()
		queue_free()


func update_auto_aim(delta: float) -> void:
	if !auto_aim_enabled:
		return
	auto_aim_time_left -= delta
	if auto_aim_time_left > 0:
		return
	auto_aim_time_left = AUTO_AIM_INTERVAL
	var enemies: Array = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return is_instance_valid(enemy) and global_position.distance_squared_to(enemy.global_position) <= AUTO_AIM_RANGE * AUTO_AIM_RANGE
	)
	var target: Node2D = find_densest_enemy(enemies)
	if target != null:
		direction = global_position.direction_to(target.global_position)
		rotation = direction.angle()


func find_densest_enemy(enemies: Array) -> Node2D:
	var densest_enemy: Node2D
	var highest_count := 0
	# ponytail: O(n²) candidate scan; spatial indexing only matters for much larger enemy caps.
	for candidate_value: Variant in enemies:
		var candidate: Node2D = candidate_value as Node2D
		if candidate == null:
			continue
		var nearby_count := 0
		for enemy_value: Variant in enemies:
			var enemy: Node2D = enemy_value as Node2D
			if enemy != null and candidate.global_position.distance_squared_to(enemy.global_position) <= CLUSTER_RADIUS * CLUSTER_RADIUS:
				nearby_count += 1
		if nearby_count > highest_count:
			highest_count = nearby_count
			densest_enemy = candidate
	return densest_enemy


func configure_beam() -> void:
	var start: Vector2 = global_position + direction * BEAM_START
	var end: Vector2 = global_position + direction * (BEAM_START + BEAM_LENGTH)
	var first_length: float = BEAM_LENGTH
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, end, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	var hit_position: Vector2 = Vector2.ZERO
	var hit_normal: Vector2 = Vector2.ZERO
	if not hit.is_empty():
		hit_position = hit["position"]
		hit_normal = hit["normal"]
		first_length = start.distance_to(hit_position)
	(collision_shape.shape as RectangleShape2D).size.x = first_length
	collision_shape.position = Vector2(BEAM_START + first_length * 0.5, 0)
	beam.points = PackedVector2Array([Vector2(BEAM_START, 0), Vector2(BEAM_START + first_length, 0)])
	laser_bounce_area.monitoring = reflection_enabled and not hit.is_empty()
	if not laser_bounce_area.monitoring:
		return

	var bounce_direction: Vector2 = direction.bounce(hit_normal)
	var bounce_end: Vector2 = hit_position + bounce_direction * BEAM_LENGTH * 0.5
	var bounce_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(hit_position, bounce_end, 1)
	var bounce_hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(bounce_query)
	var bounce_length: float = BEAM_LENGTH * 0.5
	if not bounce_hit.is_empty():
		var bounce_hit_position: Vector2 = bounce_hit["position"]
		bounce_length = hit_position.distance_to(bounce_hit_position)
	laser_bounce_area.global_position = hit_position
	laser_bounce_area.global_rotation = bounce_direction.angle()
	(bounce_collision_shape.shape as RectangleShape2D).size.x = bounce_length
	bounce_collision_shape.position = Vector2(bounce_length * 0.5, 0)
	beam.points = PackedVector2Array([Vector2(BEAM_START, 0), to_local(hit_position), to_local(hit_position + bounce_direction * bounce_length)])


func apply_damage(area: Area2D, delta: float) -> void:
	if not area is HurtboxComponent:
		return
	var damage_multiplier: float = 1.0
	if damage_ramp_enabled:
		damage_multiplier += (DURATION - time_left) / DURATION
	var damage: float = damage_per_second * damage_multiplier * delta
	var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
	var killed: bool = area.health_component.damage(critical_hit["damage"])
	GameEvents.heal_from_damage(critical_hit["damage"])
	if kill_duration_extension_enabled and killed and !area.get_parent().is_in_group("boss"):
		time_left += KILL_DURATION_EXTENSION
	damage_totals[area] = damage_totals.get(area, 0.0) + critical_hit["damage"]
	critical_damage_totals[area] = critical_damage_totals.get(area, false) or critical_hit["critical"]
	if stun_enabled:
		apply_stun_hit(area)


func apply_stun_hit(hurtbox: HurtboxComponent) -> void:
	var cooldown: float = stun_hit_cooldowns.get(hurtbox, 0.0)
	var current_time: float = DURATION - time_left
	if current_time < cooldown:
		return
	stun_hit_cooldowns[hurtbox] = current_time + STUN_HIT_INTERVAL
	var hits: Array = stun_hit_times.get(hurtbox, [])
	hits.append(current_time)
	hits = hits.filter(func(hit_time: float) -> bool: return current_time - hit_time <= STUN_HIT_WINDOW)
	stun_hit_times[hurtbox] = hits
	if hits.size() < 5:
		return
	hits.clear()
	var velocity_component: VelocityComponent = hurtbox.get_parent().get_node_or_null("VelocityComponent") as VelocityComponent
	if velocity_component != null:
		velocity_component.apply_stun(0.5)


func show_damage_numbers() -> void:
	for hurtbox in damage_totals:
		if is_instance_valid(hurtbox):
			hurtbox.show_damage(damage_totals[hurtbox], critical_damage_totals[hurtbox])
	damage_totals.clear()
	critical_damage_totals.clear()
