extends Node
class_name NineTreasurePagodaController

const STANDING_DELAY := 0.35
const BASE_DAMAGE_BONUS := 0.15
const BASE_ATTACK_SPEED_BONUS := 0.20
const BASE_HEALTH_BONUS := 0.20

@export var pagoda_scene: PackedScene

var player: CharacterBody2D
var pagoda: NineTreasurePagodaAbility
var character_damage_multiplier := 1.0
var stationary_time := 0.0
var stationary := false
var common_damage_levels := 0
var common_size_levels := 0
var common_rate_levels := 0
var damage_skill := false
var attack_speed_skill := false
var health_skill := false
var move_speed_skill := false
var extra_attack_skill := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	spawn_pagoda()
	apply_support_buffs()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if player.velocity.length_squared() <= 1.0:
		stationary_time += delta
	else:
		stationary_time = 0.0
	var now_stationary := stationary_time >= STANDING_DELAY
	if now_stationary != stationary:
		stationary = now_stationary
		apply_support_buffs()
	apply_attack_speed_to_weapon_timers()
	apply_size_to_weapon_controllers()
	apply_attack_count_to_weapon_controllers()


static func get_bonus_multiplier(base_bonus: float, extra_bonus: float, is_stationary: bool) -> float:
	return 1.0 + (base_bonus + extra_bonus) * (2.0 if is_stationary else 1.0)


func spawn_pagoda() -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null or pagoda_scene == null:
		return
	pagoda = pagoda_scene.instantiate() as NineTreasurePagodaAbility
	foreground.add_child(pagoda)


func apply_support_buffs() -> void:
	var standing_multiplier := 2.0 if stationary else 1.0
	var damage_bonus := (0.15 if damage_skill else 0.0) + common_damage_levels * 0.10
	var attack_speed_bonus := 0.20 if attack_speed_skill else 0.0
	GameEvents.support_damage_multiplier = get_bonus_multiplier(BASE_DAMAGE_BONUS, damage_bonus, stationary)
	GameEvents.support_health_multiplier = get_bonus_multiplier(BASE_HEALTH_BONUS, 0.20 if health_skill else 0.0, stationary)
	GameEvents.support_move_speed_multiplier = get_bonus_multiplier(0.0, 0.20 if move_speed_skill else 0.0, stationary)
	GameEvents.support_size_multiplier = 1.0 + common_size_levels * 0.10 * standing_multiplier
	GameEvents.support_attack_interval_multiplier = (1.0 / get_bonus_multiplier(BASE_ATTACK_SPEED_BONUS, attack_speed_bonus, stationary)) * maxf(0.1, 1.0 - common_rate_levels * 0.10 * standing_multiplier)
	GameEvents.support_weapon_attack_count_bonus = 1 if extra_attack_skill else 0
	refresh_weapon_attack_count()
	if player != null and player.has_method("refresh_support_stats"):
		player.call("refresh_support_stats")
	if is_instance_valid(pagoda):
		pagoda.set_size_multiplier(GameEvents.support_size_multiplier)


func refresh_weapon_attack_count() -> void:
	GameEvents.weapon_attack_count = GameEvents.base_weapon_attack_count + GameEvents.support_weapon_attack_count_bonus


func apply_attack_speed_to_weapon_timers() -> void:
	for timer: Timer in get_weapon_attack_timers():
		var last_applied := float(timer.get_meta("pagoda_applied_wait", -1.0))
		var base_wait := float(timer.get_meta("pagoda_base_wait", timer.wait_time))
		if last_applied >= 0.0 and not is_equal_approx(timer.wait_time, last_applied):
			base_wait = timer.wait_time
		var target_wait := maxf(0.05, base_wait * GameEvents.support_attack_interval_multiplier)
		timer.set_meta("pagoda_base_wait", base_wait)
		timer.set_meta("pagoda_applied_wait", target_wait)
		timer.wait_time = target_wait


func get_weapon_attack_timers() -> Array[Timer]:
	var timers: Array[Timer] = []
	var abilities := player.get_node_or_null("Abilities")
	if abilities != null:
		for controller: Node in abilities.get_children():
			var timer := controller.get_node_or_null("Timer") as Timer
			if timer != null:
				timers.append(timer)
	var foreground := get_tree().get_first_node_in_group("foreground_layer")
	if foreground != null:
		for companion: Node in foreground.get_children():
			var timer := companion.get_node_or_null("AttackTimer") as Timer
			if timer != null:
				timers.append(timer)
	return timers


func apply_size_to_weapon_controllers() -> void:
	var abilities := player.get_node_or_null("Abilities")
	if abilities == null:
		return
	for controller: Node in abilities.get_children():
		var size_property := "size_multiplier" if has_property(controller, "size_multiplier") else "beam_size_multiplier"
		if not has_property(controller, size_property):
			continue
		var current_size := float(controller.get(size_property))
		var last_applied := float(controller.get_meta("pagoda_applied_size", -1.0))
		var base_size := float(controller.get_meta("pagoda_base_size", current_size))
		if last_applied >= 0.0 and not is_equal_approx(current_size, last_applied):
			base_size = current_size
		var target_size := base_size * GameEvents.support_size_multiplier
		controller.set_meta("pagoda_base_size", base_size)
		controller.set_meta("pagoda_applied_size", target_size)
		controller.set(size_property, target_size)
		if controller.has_method("refresh_dragon"):
			controller.call("refresh_dragon")


func apply_attack_count_to_weapon_controllers() -> void:
	var abilities := player.get_node_or_null("Abilities")
	if abilities == null:
		return
	for controller: Node in abilities.get_children():
		for property: Dictionary in controller.get_property_list():
			if property["name"] == "attack_count":
				controller.set("attack_count", GameEvents.weapon_attack_count)
				break


func has_property(node: Node, property_name: String) -> bool:
	for property: Dictionary in node.get_property_list():
		if property["name"] == property_name:
			return true
	return false


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"nine_treasure_pagoda_damage":
			common_damage_levels = int(current_upgrades[upgrade.id]["quantity"])
		"nine_treasure_pagoda_size":
			common_size_levels = int(current_upgrades[upgrade.id]["quantity"])
		"nine_treasure_pagoda_rate":
			common_rate_levels = int(current_upgrades[upgrade.id]["quantity"])
		"nine_treasure_damage":
			damage_skill = true
		"nine_treasure_attack_speed":
			attack_speed_skill = true
		"nine_treasure_health":
			health_skill = true
		"nine_treasure_move_speed":
			move_speed_skill = true
		"nine_treasure_extra_attack":
			extra_attack_skill = true
		_:
			return
	apply_support_buffs()
