extends Node2D
class_name AxeAbility

const MAX_RADIUS := 100
const MAX_ROTATION := 2
const MAX_DISTANCE_MULTIPLIER := 2.0
const PROJECTILE_REFLECT_RANGE := 20.0
const KNOCKBACK_SPEED := 220.0

@onready var hitbox_component: HitboxComponent = $HitboxComponent


var base_rotation: Vector2
var reflect_projectiles := false
var return_to_player := false
var knockback_enabled := false
var distance_scaling_enabled := false
var base_scale := Vector2.ONE
var base_damage := 0.0


func _ready() -> void:
	base_rotation = Vector2.RIGHT.rotated(randf_range(0, TAU))
	base_scale = scale
	hitbox_component.damage = base_damage
	hitbox_component.area_entered.connect(on_hitbox_area_entered)

	var tween: Tween = create_tween()
	tween.tween_method(move_outward, 0.0, 1.0, 1.5)
	if return_to_player:
		tween.tween_method(move_returning, 0.0, 1.0, 1.0)
	tween.tween_callback(queue_free)


func move_outward(percent: float) -> void:
	move_along_arc(percent * MAX_RADIUS, percent * MAX_ROTATION)


func move_returning(percent: float) -> void:
	move_along_arc((1.0 - percent) * MAX_RADIUS, MAX_ROTATION + percent * MAX_ROTATION)


func move_along_arc(current_radius: float, rotations: float) -> void:
	var current_direction: Vector2 = base_rotation.rotated(rotations * TAU)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	global_position = player.global_position + (current_direction * current_radius)
	if distance_scaling_enabled:
		var multiplier := get_distance_multiplier(global_position.distance_to(player.global_position))
		scale = base_scale * multiplier
		hitbox_component.damage = base_damage * multiplier
	if reflect_projectiles:
		reflect_enemy_projectiles()


static func get_distance_multiplier(distance: float) -> float:
	return 1.0 + clampf(distance / MAX_RADIUS, 0.0, MAX_DISTANCE_MULTIPLIER - 1.0)


func on_hitbox_area_entered(other_area: Area2D) -> void:
	if not knockback_enabled or not other_area is HurtboxComponent:
		return
	var target: Node2D = other_area.get_parent() as Node2D
	if target == null:
		return
	var target_velocity: VelocityComponent = target.get_node_or_null("VelocityComponent") as VelocityComponent
	if target_velocity != null:
		target_velocity.velocity = (target.global_position - global_position).normalized() * KNOCKBACK_SPEED


func reflect_enemy_projectiles() -> void:
	for projectile: Node2D in get_tree().get_nodes_in_group("enemy_projectile"):
		if global_position.distance_squared_to(projectile.global_position) <= PROJECTILE_REFLECT_RANGE * PROJECTILE_REFLECT_RANGE and projectile.has_method("reflect_to_enemy"):
			projectile.reflect_to_enemy()
