extends Node

const ATTACK_RANGE := 73.5
const BASE_RADIUS := 38.5

@export var hammer_ability_scene: PackedScene

var base_damage := 12.0
var base_wait_time := 3.9
var damage_multiplier := 1.0
var size_multiplier := 1.0
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var attack_count := 1
var extra_wave_count := 0
var character_damage_multiplier := 1.0


func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01 + MetaProgression.get_weapon_tree_bonus("heaven_shaking_hammer", "damage")) * character_damage_multiplier
	permanent_attack_speed_multiplier = maxf(0.1, 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03 - MetaProgression.get_weapon_tree_bonus("heaven_shaking_hammer", "attack_speed"))
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05 + MetaProgression.get_weapon_tree_bonus("heaven_shaking_hammer", "size")
	damage_multiplier = permanent_damage_multiplier
	size_multiplier = permanent_size_multiplier
	attack_count = GameEvents.weapon_attack_count
	$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	var attack_range := ATTACK_RANGE * size_multiplier
	var enemies: Array = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) <= attack_range * attack_range
	)
	if enemies.is_empty():
		return
	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)
	for index in attack_count:
		var target := enemies[index % enemies.size()] as Node2D
		var hammer := hammer_ability_scene.instantiate() as HeavenShakingHammerAbility
		hammer.configure(player.global_position, target.global_position, base_damage * damage_multiplier, BASE_RADIUS * size_multiplier, extra_wave_count)
		foreground.add_child(hammer)


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"heaven_shaking_hammer_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"heaven_shaking_hammer_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"heaven_shaking_hammer_rate":
			$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier * (1.0 - current_upgrades[upgrade.id]["quantity"] * 0.05)
			$Timer.start()
		"heaven_shaking_hammer_extra_wave":
			extra_wave_count = int(current_upgrades[upgrade.id]["quantity"])
		"attack_count":
			attack_count = GameEvents.weapon_attack_count
