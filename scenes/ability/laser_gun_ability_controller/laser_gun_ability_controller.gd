extends Node

const MAX_RANGE := 300.0
const BEAM_DURATION := 2.0

@export var laser_gun_ability_scene: PackedScene

var base_damage_per_second := 8.0
var base_beam_width := 8.0
var base_cooldown := 2.0
var damage_multiplier := 1.0
var beam_size_multiplier := 1.0
var cooldown_reduction := 0.0
var attack_count := 1
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var damage_ramp_enabled := false
var reflection_enabled := false
var stun_enabled := false
var auto_aim_enabled := false
var kill_duration_extension_enabled := false
var character_damage_multiplier := 1.0


func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	permanent_attack_speed_multiplier = 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	damage_multiplier = permanent_damage_multiplier
	beam_size_multiplier = permanent_size_multiplier
	attack_count = GameEvents.weapon_attack_count
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	update_cooldown()


func on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) <= MAX_RANGE * MAX_RANGE
	)
	if enemies.is_empty():
		return

	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)

	var base_direction: Vector2 = (enemies[0].global_position - player.global_position).normalized()
	var foreground = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	for index in attack_count:
		var laser := laser_gun_ability_scene.instantiate() as LaserGunAbility
		laser.source = player
		laser.direction = base_direction.rotated(deg_to_rad((index - (attack_count - 1) * 0.5) * 10))
		laser.damage_per_second = base_damage_per_second * damage_multiplier
		laser.beam_width = base_beam_width * beam_size_multiplier
		laser.damage_ramp_enabled = damage_ramp_enabled
		laser.reflection_enabled = reflection_enabled
		laser.stun_enabled = stun_enabled
		laser.auto_aim_enabled = auto_aim_enabled
		laser.kill_duration_extension_enabled = kill_duration_extension_enabled
		foreground.add_child(laser)


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"laser_gun_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.2)
		"laser_gun_size":
			beam_size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.2)
		"laser_gun_cooldown":
			cooldown_reduction = current_upgrades[upgrade.id]["quantity"] * 0.15
			update_cooldown()
		"laser_gun_damage_ramp":
			damage_ramp_enabled = true
		"laser_gun_reflect":
			reflection_enabled = true
		"laser_gun_stun":
			stun_enabled = true
		"laser_gun_auto_aim":
			auto_aim_enabled = true
		"laser_gun_kill_duration":
			kill_duration_extension_enabled = true
		"attack_count":
			attack_count = GameEvents.weapon_attack_count


func update_cooldown() -> void:
	$Timer.wait_time = (BEAM_DURATION + base_cooldown * (1.0 - cooldown_reduction)) * permanent_attack_speed_multiplier
