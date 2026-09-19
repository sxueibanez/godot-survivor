extends Node

const ATTACK_RANGE := 73.5
const BASE_RADIUS := 38.5
const HEAVY_CHARGE_TIME := 10.0
const COMBAT_RANGE := 375.0

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
var lava_enabled := false
var pull_enabled := false
var heavy_enabled := false
var aftershock_enabled := false
var quake_charge := 0.0
var charge_label: Label
var character_damage_multiplier := 1.0


@onready var attack_cooldown = preload("res://scenes/ability/attack_cooldown.gd").new($Timer)

func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01 + MetaProgression.get_weapon_tree_bonus("heaven_shaking_hammer", "damage")) * character_damage_multiplier
	permanent_attack_speed_multiplier = maxf(0.1, 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03 - MetaProgression.get_weapon_tree_bonus("heaven_shaking_hammer", "attack_speed")) / GameEvents.get_character_attack_speed_multiplier()
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05 + MetaProgression.get_weapon_tree_bonus("heaven_shaking_hammer", "size")
	damage_multiplier = permanent_damage_multiplier
	size_multiplier = permanent_size_multiplier
	attack_count = GameEvents.weapon_attack_count
	$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func _process(delta: float) -> void:
	if not heavy_enabled:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var in_combat := false
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if player.global_position.distance_squared_to(enemy.global_position) <= COMBAT_RANGE * COMBAT_RANGE:
			in_combat = true
			break
	quake_charge = minf(HEAVY_CHARGE_TIME, quake_charge + delta) if in_combat else 0.0
	if not is_instance_valid(charge_label):
		charge_label = Label.new()
		charge_label.position = Vector2(-28, 20)
		charge_label.add_theme_font_size_override("font_size", 8)
		charge_label.z_as_relative = false
		charge_label.z_index = 40
		player.add_child(charge_label)
	charge_label.text = "震势 %d/10" % floori(quake_charge)
	charge_label.modulate = Color("ffda68") if quake_charge >= HEAVY_CHARGE_TIME else Color.WHITE


func on_timer_timeout() -> void:
	if attack_cooldown.active_count > 0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("player_projectiles_layer") as Node2D
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
		var is_heavy := heavy_enabled and quake_charge >= HEAVY_CHARGE_TIME
		hammer.configure(player.global_position, target.global_position, base_damage * damage_multiplier, BASE_RADIUS * size_multiplier, extra_wave_count, lava_enabled, pull_enabled, is_heavy)
		hammer.aftershock_enabled = aftershock_enabled
		if is_heavy:
			quake_charge = 0.0
		attack_cooldown.track(hammer)
		foreground.add_child(hammer)


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"heaven_shaking_hammer_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"heaven_shaking_hammer_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"heaven_shaking_hammer_rate":
			$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier * (1.0 - current_upgrades[upgrade.id]["quantity"] * 0.05)
			attack_cooldown.restart()
		"heaven_shaking_hammer_extra_wave":
			extra_wave_count = int(current_upgrades[upgrade.id]["quantity"])
		"heaven_shaking_hammer_lava":
			lava_enabled = true
		"heaven_shaking_hammer_pull":
			pull_enabled = true
		"heaven_shaking_hammer_heavy":
			heavy_enabled = true
		"heaven_shaking_hammer_aftershock":
			aftershock_enabled = true
		"attack_count":
			attack_count = GameEvents.weapon_attack_count
