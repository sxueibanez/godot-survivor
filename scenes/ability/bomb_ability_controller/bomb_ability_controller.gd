extends Node
class_name BombAbilityController

const MAX_RANGE := 320.0
const CLUSTER_RADIUS := 70.0
const BASE_RADIUS := 30.0

@export var bomb_ability_scene: PackedScene

var base_damage := 15.0
var base_wait_time := 2.0
var damage_multiplier := 1.0
var size_multiplier := 1.0
var attack_count := 1
var bounce_level := 0
var burn_enabled := false
var cluster_enabled := false
var character_damage_multiplier := 1.0


func _ready() -> void:
	damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	attack_count = GameEvents.weapon_attack_count
	$Timer.wait_time = base_wait_time * (1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03)
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	var enemies: Array = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return not enemy.is_in_group("boss") and enemy.global_position.distance_squared_to(player.global_position) <= MAX_RANGE * MAX_RANGE
	)
	var target := find_densest_enemy(enemies)
	if target == null:
		return
	for index in attack_count:
		var bomb := bomb_ability_scene.instantiate() as BombAbility
		var offset := Vector2.RIGHT.rotated(TAU * index / attack_count) * (8.0 if attack_count > 1 else 0.0)
		bomb.configure(player.global_position, target.global_position + offset, base_damage * damage_multiplier, BASE_RADIUS * size_multiplier, bounce_level, burn_enabled, cluster_enabled)
		foreground.add_child(bomb)


static func find_densest_enemy(enemies: Array) -> Node2D:
	var densest: Node2D
	var highest_count := 0
	# ponytail: O(n²) cluster scan; use spatial buckets only if enemy caps grow substantially.
	for candidate_value: Variant in enemies:
		var candidate := candidate_value as Node2D
		if candidate == null:
			continue
		var nearby_count := 0
		for enemy_value: Variant in enemies:
			var enemy := enemy_value as Node2D
			if enemy != null and candidate.global_position.distance_squared_to(enemy.global_position) <= CLUSTER_RADIUS * CLUSTER_RADIUS:
				nearby_count += 1
		if nearby_count > highest_count:
			highest_count = nearby_count
			densest = candidate
	return densest


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"bomb_bounce":
			bounce_level = int(current_upgrades[upgrade.id]["quantity"])
		"bomb_burn":
			burn_enabled = true
		"bomb_cluster":
			cluster_enabled = true
		"attack_count":
			attack_count = GameEvents.weapon_attack_count
