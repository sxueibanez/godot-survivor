extends Node2D
class_name SniperRifleBullet

const SPEED := 650.0
const MAX_DISTANCE := 720.0
const MAX_HITS := 3
const DAMAGE_FALLOFF := 0.5
const HIT_RADIUS := 10.0
const FRAME_COUNT := 4
const FRAME_TIME := 0.06
const FRAGMENT_DAMAGE_MULTIPLIER := 0.25
const EXPLOSION_DAMAGE_MULTIPLIER := 0.05
const EXPLOSION_RADIUS := 10.0
const EXPLOSION_TEXTURE: Texture2D = preload("res://assets/abilities/bomb_explosion.png")
const BULLET_SCENE: PackedScene = preload("res://scenes/ability/sniper_rifle_bullet/sniper_rifle_bullet.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var launch_sound: AudioStreamPlayer2D = $LaunchSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

var direction := Vector2.RIGHT
var weapon_damage := 35.0
var size_multiplier := 1.0
var no_damage_falloff := false
var split_at_endpoint := false
var ricochet_enabled := false
var explosive_hit := false
var max_hits := MAX_HITS
var travelled_distance := 0.0
var elapsed := 0.0
var hit_count := 0
var hit_enemy_ids: Dictionary = {}
var finished := false


func configure(from: Vector2, new_direction: Vector2, new_damage: float, new_size_multiplier: float, diamond_bullet: bool, shadowless_bullet: bool = false, ricochet: bool = false, explosive_bullet: bool = false, fragment: bool = false) -> void:
	global_position = from
	direction = Vector2.RIGHT if new_direction == Vector2.ZERO else new_direction
	weapon_damage = new_damage
	size_multiplier = new_size_multiplier
	no_damage_falloff = diamond_bullet
	split_at_endpoint = shadowless_bullet and not fragment
	ricochet_enabled = ricochet and not fragment
	explosive_hit = explosive_bullet and not fragment
	max_hits = 1 if fragment else MAX_HITS


func _ready() -> void:
	rotation = direction.angle()
	sprite.scale = Vector2.ONE * 0.06 * size_multiplier
	launch_sound.play()


func _process(delta: float) -> void:
	if finished:
		if not hit_sound.playing:
			queue_free()
		return
	elapsed += delta
	sprite.frame = floori(elapsed / FRAME_TIME) % FRAME_COUNT
	var previous_position := global_position
	var movement := direction * SPEED * delta
	var next_position := global_position + movement
	var wall_hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(previous_position, next_position, 1))
	if not wall_hit.is_empty():
		next_position = wall_hit["position"]
	global_position = next_position
	travelled_distance += previous_position.distance_to(global_position)
	damage_crossed_enemies(previous_position, global_position)
	if not wall_hit.is_empty():
		if ricochet_enabled:
			direction = direction.bounce(wall_hit["normal"])
			rotation = direction.angle()
			global_position += direction * 2.0
		else:
			finish_at_endpoint()
		return
	if travelled_distance >= MAX_DISTANCE:
		finish_at_endpoint()


func damage_crossed_enemies(from: Vector2, to: Vector2) -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var enemy_id := enemy.get_instance_id()
		if hit_enemy_ids.has(enemy_id):
			continue
		var closest_point := Geometry2D.get_closest_point_to_segment(enemy.global_position, from, to)
		if closest_point.distance_squared_to(enemy.global_position) > pow(HIT_RADIUS * size_multiplier, 2):
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		hit_enemy_ids[enemy_id] = true
		var hit_damage := get_damage_for_hit(weapon_damage, hit_count, no_damage_falloff)
		var critical_hit: Dictionary = GameEvents.get_critical_damage(hit_damage, "sniper_rifle")
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("sniper_rifle", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
		hit_sound.play()
		if explosive_hit:
			explode_at(enemy.global_position, get_explosion_damage(hit_damage))
		hit_count += 1
		if hit_count >= max_hits:
			spawn_fragments()
			finished = true
			sprite.visible = false
			return


func finish_at_endpoint() -> void:
	spawn_fragments()
	queue_free()


func spawn_fragments() -> void:
	if split_at_endpoint:
		split_at_endpoint = false
		for fragment_direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
			var fragment := BULLET_SCENE.instantiate() as SniperRifleBullet
			fragment.configure(global_position, fragment_direction, get_fragment_damage(weapon_damage), size_multiplier, true, false, false, false, true)
			if has_meta("attack_cooldown"):
				get_meta("attack_cooldown").track(fragment)
			get_parent().add_child(fragment)


func explode_at(center: Vector2, explosion_damage: float) -> void:
	show_explosion(center)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if center.distance_squared_to(enemy.global_position) > pow(EXPLOSION_RADIUS * size_multiplier, 2):
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(explosion_damage, "sniper_rifle")
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("sniper_rifle", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()


func show_explosion(center: Vector2) -> void:
	var effect := Sprite2D.new()
	effect.texture = EXPLOSION_TEXTURE
	effect.hframes = 4
	effect.vframes = 4
	effect.global_position = center
	effect.scale = Vector2.ONE * EXPLOSION_RADIUS * size_multiplier / 150.0
	get_tree().get_first_node_in_group("combat_effects_layer").add_child(effect)
	var tween := effect.create_tween()
	tween.tween_property(effect, "frame", 15, 0.3)
	tween.tween_callback(effect.queue_free)


static func get_damage_for_hit(base_damage: float, hit_index: int, diamond_bullet: bool) -> float:
	return base_damage if diamond_bullet else base_damage * pow(DAMAGE_FALLOFF, hit_index)


static func get_fragment_damage(base_damage: float) -> float:
	return base_damage * FRAGMENT_DAMAGE_MULTIPLIER


static func get_explosion_damage(hit_damage: float) -> float:
	return hit_damage * EXPLOSION_DAMAGE_MULTIPLIER
