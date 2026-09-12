extends Node

const MAX_RANGE := 50.0

@export var lightning_whip_ability_scene: PackedScene

var base_damage := 8.0
var damage_multiplier := 1.0
var size_multiplier := 1.0
var base_wait_time := 2.0 / 2.0
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var attack_count := 1
var chain_enabled := false
var cloud_enabled := false
var wide_arc_enabled := false
var character_damage_multiplier := 1.0


func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	permanent_attack_speed_multiplier = 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	damage_multiplier = permanent_damage_multiplier
	size_multiplier = permanent_size_multiplier
	attack_count = GameEvents.weapon_attack_count
	$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var attack_range := MAX_RANGE * size_multiplier
	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) <= attack_range * attack_range
	)
	if enemies.is_empty():
		return

	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)
	var foreground = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	for index in attack_count:
		var whip := lightning_whip_ability_scene.instantiate() as LightningWhipAbility
		whip.global_position = player.global_position
		whip.direction = (enemies[index % enemies.size()].global_position - player.global_position).normalized()
		whip.damage = base_damage * damage_multiplier
		whip.size_multiplier = size_multiplier
		whip.chain_enabled = chain_enabled
		whip.cloud_enabled = cloud_enabled
		whip.wide_arc_enabled = wide_arc_enabled
		foreground.add_child(whip)


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"lightning_whip_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"lightning_whip_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"lightning_whip_rate":
			$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier * (1.0 - current_upgrades[upgrade.id]["quantity"] * 0.05)
			$Timer.start()
		"lightning_chain":
			chain_enabled = true
		"lightning_cloud":
			cloud_enabled = true
		"lightning_wide_arc":
			wide_arc_enabled = true
		"attack_count":
			attack_count = GameEvents.weapon_attack_count
