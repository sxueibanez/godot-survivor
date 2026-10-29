extends Node2D
class_name LightningWhipAbility

const DURATION := 0.4
const RANGE := 50.0
const BASE_HALF_ANGLE := PI / 4.0
const WIDE_HALF_ANGLE := PI / 2.0
const CHAIN_TRIGGER_CHANCE := 0.5
const CHAIN_TARGET_COUNT := 2
const CHAIN_DAMAGE_MULTIPLIER := 0.5
const CLOUD_TRIGGER_CHANCE := 0.1
const Paralysis = preload("res://scenes/ability/lightning_paralysis.gd")

@export var damage := 8.0
@export var size_multiplier := 0.5
@export var chain_enabled := false
@export var cloud_enabled := false
@export var wide_arc_enabled := false
@export var paralysis_enabled := false

var direction := Vector2.RIGHT
var time_left := DURATION
var attack_half_angle := BASE_HALF_ANGLE
var lightning_chain_scene := preload("res://scenes/ability/lightning_chain_ability/lightning_chain_ability.tscn")
var lightning_cloud_scene := preload("res://scenes/ability/lightning_cloud_ability/lightning_cloud_ability.tscn")


func _ready() -> void:
	$LaunchSound.play()
	rotation = direction.angle()
	scale = Vector2.ONE * size_multiplier
	attack_half_angle = WIDE_HALF_ANGLE if wide_arc_enabled else BASE_HALF_ANGLE
	$Visuals.rotation = -attack_half_angle
	create_tween().tween_property($Visuals, "rotation", attack_half_angle, DURATION)
	strike()


func _draw() -> void:
	var fade := clampf(time_left / DURATION, 0.0, 1.0)
	var points := PackedVector2Array([Vector2.ZERO])
	for index in 25:
		var angle := lerpf(-attack_half_angle, attack_half_angle, index / 24.0)
		points.append(Vector2.RIGHT.rotated(angle) * RANGE)
	draw_colored_polygon(points, Color(0.35, 0.75, 1.0, 0.1 * fade))
	draw_arc(Vector2.ZERO, RANGE, -attack_half_angle, attack_half_angle, 24, Color(0.65, 0.93, 1.0, 0.65 * fade), 1.5)
	var sweep_angle := lerpf(-attack_half_angle, attack_half_angle, 1.0 - fade)
	var sweep_direction := Vector2.RIGHT.rotated(sweep_angle)
	draw_line(sweep_direction * 12.0, sweep_direction * RANGE, Color(0.8, 0.97, 1.0, 0.55 * fade), 1.5)


func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0:
		queue_free()
	else:
		queue_redraw()


func strike() -> void:
	var attack_range := RANGE * size_multiplier
	var hit_any_enemy := false
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length_squared() > attack_range * attack_range || abs(direction.angle_to(offset.normalized())) > attack_half_angle:
			continue

		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null || hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		hurtbox.health_component.damage(critical_hit["damage"], "", global_position, "direct", "lightning_whip")
		GameEvents.record_weapon_damage("lightning_whip", critical_hit["damage"])
		GameEvents.heal_from_damage(critical_hit["damage"])
		hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
		hurtbox.hit.emit()
		hit_any_enemy = true
		var velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
		if velocity != null:
			velocity.apply_slow(0.25, 3.0)
		Paralysis.try_apply(enemy, paralysis_enabled)
		if cloud_enabled and randf() <= CLOUD_TRIGGER_CHANCE:
			spawn_cloud(enemy)
		if chain_enabled and randf() <= CHAIN_TRIGGER_CHANCE:
			spawn_chains(enemy)
	if hit_any_enemy:
		$HitSound.play()


func spawn_chains(source_enemy: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy != source_enemy && enemy.global_position.distance_squared_to(source_enemy.global_position) <= 100 * 100
	)
	if enemies.is_empty():
		return

	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(source_enemy.global_position) < b.global_position.distance_squared_to(source_enemy.global_position)
	)
	var foreground := get_tree().get_first_node_in_group("combat_effects_layer") as Node2D
	if foreground == null:
		return
	for index in min(CHAIN_TARGET_COUNT, enemies.size()):
		var chain := lightning_chain_scene.instantiate() as LightningChainAbility
		chain.source = source_enemy
		chain.target = enemies[index] as Node2D
		chain.damage = damage * CHAIN_DAMAGE_MULTIPLIER
		chain.chain_enabled = true
		chain.chain_depth = 1
		chain.visited_enemy_ids = [source_enemy.get_instance_id()]
		chain.paralysis_enabled = paralysis_enabled
		foreground.add_child(chain)


func spawn_cloud(enemy: Node2D) -> void:
	var foreground := get_tree().get_first_node_in_group("combat_effects_layer") as Node2D
	if foreground == null:
		return
	var cloud := lightning_cloud_scene.instantiate() as LightningCloudAbility
	cloud.damage = damage * LightningCloudAbility.DAMAGE_MULTIPLIER
	cloud.paralysis_enabled = paralysis_enabled
	cloud.global_position = enemy.global_position + Vector2.UP * LightningCloudAbility.HOVER_HEIGHT
	foreground.add_child(cloud)
