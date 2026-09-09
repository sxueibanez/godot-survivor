extends Node2D
class_name LightningChainAbility

const RANGE := 100.0
const TARGET_COUNT := 2
const TRIGGER_CHANCE := 0.5
const MAX_CHAIN_DEPTH := 3

@export var source: Node2D
@export var source_position := Vector2.ZERO
@export var target: Node2D
@export var damage := 4.0
@export var chain_enabled := false

@onready var chain_animation: AnimatedSprite2D = $Sprite2D

var visited_enemy_ids: Array[int] = []
var chain_origin := Vector2.ZERO
var chain_depth := 1
var lightning_chain_scene := preload("res://scenes/ability/lightning_chain_ability/lightning_chain_ability.tscn")


func _ready() -> void:
	if !is_instance_valid(target):
		queue_free()
		return
	if visited_enemy_ids.has(target.get_instance_id()):
		queue_free()
		return
	visited_enemy_ids.append(target.get_instance_id())

	global_position = source.global_position if is_instance_valid(source) else source_position
	var target_offset := target.global_position - global_position
	chain_origin = target.global_position
	$Sprite2D.position = target_offset * 0.5
	var should_chain := false
	var hurtbox := target.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox != null:
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		hurtbox.health_component.damage(critical_hit["damage"])
		GameEvents.record_weapon_damage("lightning_whip", critical_hit["damage"])
		GameEvents.heal_from_damage(critical_hit["damage"])
		hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
		hurtbox.hit.emit()
		should_chain = chain_enabled and chain_depth < MAX_CHAIN_DEPTH and randf() <= TRIGGER_CHANCE

	await chain_animation.animation_finished
	if should_chain:
		spawn_chains()
	queue_free()


func spawn_chains() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return is_instance_valid(enemy) and not visited_enemy_ids.has(enemy.get_instance_id()) and enemy.global_position.distance_squared_to(chain_origin) <= RANGE * RANGE
	)
	if enemies.is_empty():
		return
	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(chain_origin) < b.global_position.distance_squared_to(chain_origin)
	)
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	for index in min(TARGET_COUNT, enemies.size()):
		var chain := lightning_chain_scene.instantiate() as LightningChainAbility
		chain.source_position = chain_origin
		chain.target = enemies[index] as Node2D
		chain.damage = damage
		chain.chain_enabled = true
		chain.chain_depth = chain_depth + 1
		chain.visited_enemy_ids = visited_enemy_ids.duplicate()
		foreground.add_child(chain)
