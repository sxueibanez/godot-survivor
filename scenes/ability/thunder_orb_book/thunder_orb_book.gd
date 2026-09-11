extends Node2D
class_name ThunderOrbBookAbility

const MAX_DISTANCE := LaserGunAbility.BEAM_LENGTH
const SPEED := 65.0
const TOUCH_RADIUS := 20.0
const CHAIN_RANGE := 120.0
const CHAIN_TARGET_COUNT := 3
const HIT_INTERVAL_MS := 1000
const TOUCH_COOLDOWN_META := &"thunder_orb_touch_ms"
const CHAIN_INTERVAL := 1.0
const GROWTH_SCALE := 1.8
const EXPLOSION_MULTIPLIER := 2.0
const PLASMA_MULTIPLIER := 0.3
const EXPLOSION_RADIUS := 55.0
const PLASMA_RADIUS := 30.0
const FRAME_COUNT := 16
const FRAME_DURATION := 0.08
const BASE_SPRITE_SCALE := 0.18

var plasma_scene := preload("res://scenes/ability/thunder_plasma/thunder_plasma.tscn")
var chain_texture := preload("res://assets/abilities/thunder_orb_chain.png")

@onready var orb_sprite: Sprite2D = $OrbSprite

var direction := Vector2.RIGHT
var damage := 10.0
var chain_enabled := false
var growth_enabled := false
var plasma_enabled := false
var boss_tracking_enabled := false
var normal_direction := Vector2.RIGHT
var base_size_multiplier := 1.0
var distance_traveled := 0.0
var animation_time := 0.0
var chain_time_left := CHAIN_INTERVAL
var exploding := false


func configure(start: Vector2, travel_direction: Vector2, weapon_damage: float, chains: bool, grows: bool, plasma: bool, tracks_boss: bool = false, size_multiplier: float = 1.0) -> void:
	global_position = start
	normal_direction = travel_direction.normalized()
	direction = normal_direction
	damage = weapon_damage
	chain_enabled = chains
	growth_enabled = grows
	plasma_enabled = plasma
	boss_tracking_enabled = tracks_boss
	base_size_multiplier = size_multiplier


func _process(delta: float) -> void:
	if exploding:
		return
	update_boss_tracking()
	var movement := minf(SPEED * delta, MAX_DISTANCE - distance_traveled)
	global_position += direction * movement
	distance_traveled += movement
	animation_time += delta
	orb_sprite.frame = floori(animation_time / FRAME_DURATION) % FRAME_COUNT
	orb_sprite.scale = Vector2.ONE * BASE_SPRITE_SCALE * base_size_multiplier * get_visual_scale(distance_traveled / MAX_DISTANCE, growth_enabled)
	damage_touching_enemies()
	if chain_enabled:
		chain_time_left -= delta
		if chain_time_left <= 0.0:
			chain_time_left += CHAIN_INTERVAL
			release_chains()
	if distance_traveled >= MAX_DISTANCE:
		finish_travel()


func update_boss_tracking() -> void:
	direction = normal_direction
	if not boss_tracking_enabled:
		return
	var boss := get_tree().get_first_node_in_group("boss") as Node2D
	if is_instance_valid(boss):
		direction = global_position.direction_to(boss.global_position)


func damage_touching_enemies() -> void:
	var radius := TOUCH_RADIUS * base_size_multiplier * get_visual_scale(distance_traveled / MAX_DISTANCE, growth_enabled)
	var now := Time.get_ticks_msec()
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		if now - int(enemy.get_meta(TOUCH_COOLDOWN_META, -HIT_INTERVAL_MS)) < HIT_INTERVAL_MS:
			continue
		if damage_enemy(enemy, damage):
			enemy.set_meta(TOUCH_COOLDOWN_META, now)


func release_chains() -> void:
	var targets: Array = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return is_instance_valid(enemy) and global_position.distance_squared_to(enemy.global_position) <= CHAIN_RANGE * CHAIN_RANGE
	)
	targets.sort_custom(func(a: Node2D, b: Node2D):
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	for index in mini(CHAIN_TARGET_COUNT, targets.size()):
		var target := targets[index] as Node2D
		if damage_enemy(target, damage):
			show_chain(target.global_position)


func show_chain(target_position: Vector2) -> void:
	var chain := Sprite2D.new()
	chain.texture = chain_texture
	chain.global_position = (global_position + target_position) * 0.5
	chain.global_rotation = global_position.direction_to(target_position).angle()
	chain.scale = Vector2(global_position.distance_to(target_position) / chain_texture.get_width(), 0.15)
	get_parent().add_child(chain)
	var tween := chain.create_tween()
	tween.tween_property(chain, "modulate:a", 0.0, 0.18)
	tween.tween_callback(chain.queue_free)


func finish_travel() -> void:
	exploding = true
	if not plasma_enabled:
		queue_free()
		return
	var radius := EXPLOSION_RADIUS * base_size_multiplier * get_visual_scale(1.0, growth_enabled)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) <= radius * radius:
			damage_enemy(enemy, damage * EXPLOSION_MULTIPLIER)
	var plasma := plasma_scene.instantiate()
	plasma.configure(global_position, damage * PLASMA_MULTIPLIER, PLASMA_RADIUS)
	get_parent().add_child(plasma)
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(orb_sprite, "scale", orb_sprite.scale * 2.0, 0.2)
	tween.tween_property(orb_sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)


func damage_enemy(enemy: Node2D, amount: float) -> bool:
	var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
		return false
	var critical_hit: Dictionary = GameEvents.get_critical_damage(amount)
	hurtbox.health_component.damage(critical_hit["damage"])
	GameEvents.record_weapon_damage("thunder_orb_book", critical_hit["damage"])
	GameEvents.heal_from_damage(critical_hit["damage"])
	hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
	hurtbox.hit.emit()
	return true


static func get_visual_scale(progress: float, enabled: bool) -> float:
	return lerpf(1.0, GROWTH_SCALE, clampf(progress, 0.0, 1.0)) if enabled else 1.0
