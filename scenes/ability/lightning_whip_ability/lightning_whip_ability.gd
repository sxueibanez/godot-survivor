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

@export var damage := 8.0
@export var size_multiplier := 1.0
@export var chain_enabled := false
@export var cloud_enabled := false
@export var wide_arc_enabled := false

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


func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0:
		queue_free()


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
		hurtbox.health_component.damage(critical_hit["damage"])
		GameEvents.record_weapon_damage("lightning_whip", critical_hit["damage"])
		GameEvents.heal_from_damage(critical_hit["damage"])
		hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
		hurtbox.hit.emit()
		hit_any_enemy = true
		var velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
		if velocity != null:
			velocity.apply_slow(0.25, 3.0)
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
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
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
		foreground.add_child(chain)


func spawn_cloud(enemy: Node2D) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var cloud := lightning_cloud_scene.instantiate() as LightningCloudAbility
	cloud.damage = damage * LightningCloudAbility.DAMAGE_MULTIPLIER
	cloud.global_position = enemy.global_position + Vector2.UP * LightningCloudAbility.HOVER_HEIGHT
	foreground.add_child(cloud)
