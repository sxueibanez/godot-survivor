extends Node


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var required_ids := {
		"sword": ["sword_damage", "sword_size", "sword_rate"],
		"axe": ["axe_damage", "axe_size", "axe_rate"],
		"laser_gun": ["laser_gun_damage", "laser_gun_size", "laser_gun_cooldown"],
		"lightning_whip": ["lightning_whip_damage", "lightning_whip_size", "lightning_whip_rate"],
		"bomb": ["bomb_damage", "bomb_size", "bomb_rate"],
		"thunder_orb_book": ["thunder_orb_damage", "thunder_orb_size", "thunder_orb_rate"],
		"azure_dragon": ["azure_dragon_damage", "azure_dragon_size", "azure_dragon_rate"],
		"nine_treasure_pagoda": ["nine_treasure_pagoda_damage", "nine_treasure_pagoda_size", "nine_treasure_pagoda_rate"],
	}
	for weapon_id: String in required_ids:
		for upgrade_id: String in required_ids[weapon_id]:
			assert(load("res://resources/upgrades/%s.tres" % upgrade_id) is AbilityUpgrade)

	var sword: Variant = create_controller("res://scenes/ability/sword_ability_controller/sword_ability_controller.gd", 1.5)
	apply_upgrade(sword, "sword_damage")
	apply_upgrade(sword, "sword_size")
	apply_upgrade(sword, "sword_rate")
	assert(is_equal_approx(sword.additional_damage_percent, sword.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(sword.size_multiplier, sword.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(sword.get_node("Timer").wait_time, sword.base_wait_time * sword.permanent_attack_speed_multiplier * 0.95))
	sword.free()

	var axe: Variant = create_controller("res://scenes/ability/axe_ability_controller/axe_ability_controller.gd", 3.5)
	apply_upgrade(axe, "axe_damage")
	apply_upgrade(axe, "axe_size")
	apply_upgrade(axe, "axe_rate")
	assert(is_equal_approx(axe.additional_damage_percent, axe.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(axe.size_multiplier, axe.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(axe.get_node("Timer").wait_time, axe.base_wait_time * axe.permanent_attack_speed_multiplier * 0.95))
	axe.free()

	var laser: Variant = create_controller("res://scenes/ability/laser_gun_ability_controller/laser_gun_ability_controller.gd", 4.0)
	apply_upgrade(laser, "laser_gun_damage")
	apply_upgrade(laser, "laser_gun_size")
	apply_upgrade(laser, "laser_gun_cooldown")
	assert(is_equal_approx(laser.damage_multiplier, laser.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(laser.beam_size_multiplier, laser.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(laser.cooldown_reduction, 0.05))
	laser.free()

	var whip: Variant = create_controller("res://scenes/ability/lightning_whip_ability_controller/lightning_whip_ability_controller.gd", 2.0)
	apply_upgrade(whip, "lightning_whip_damage")
	apply_upgrade(whip, "lightning_whip_size")
	apply_upgrade(whip, "lightning_whip_rate")
	assert(is_equal_approx(whip.damage_multiplier, whip.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(whip.size_multiplier, whip.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(whip.get_node("Timer").wait_time, whip.base_wait_time * whip.permanent_attack_speed_multiplier * 0.95))
	whip.free()

	var bomb: Variant = create_controller("res://scenes/ability/bomb_ability_controller/bomb_ability_controller.gd", 2.0)
	apply_upgrade(bomb, "bomb_damage")
	apply_upgrade(bomb, "bomb_size")
	apply_upgrade(bomb, "bomb_rate")
	assert(is_equal_approx(bomb.damage_multiplier, bomb.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(bomb.size_multiplier, bomb.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(bomb.get_node("Timer").wait_time, bomb.base_wait_time * bomb.permanent_attack_speed_multiplier * 0.95))
	bomb.free()

	var thunder: Variant = create_controller("res://scenes/ability/thunder_orb_book_controller/thunder_orb_book_controller.gd", 4.0)
	apply_upgrade(thunder, "thunder_orb_damage")
	apply_upgrade(thunder, "thunder_orb_size")
	apply_upgrade(thunder, "thunder_orb_rate")
	assert(is_equal_approx(thunder.damage_multiplier, thunder.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(thunder.size_multiplier, thunder.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(thunder.get_node("Timer").wait_time, thunder.base_cooldown * thunder.permanent_attack_speed_multiplier * 0.95))
	thunder.free()

	var dragon: Variant = create_controller("res://scenes/ability/azure_dragon_controller/azure_dragon_controller.gd", 4.0)
	apply_upgrade(dragon, "azure_dragon_damage")
	apply_upgrade(dragon, "azure_dragon_size")
	apply_upgrade(dragon, "azure_dragon_rate")
	assert(is_equal_approx(dragon.damage_multiplier, dragon.permanent_damage_multiplier * 1.05))
	assert(is_equal_approx(dragon.size_multiplier, dragon.permanent_size_multiplier * 1.05))
	assert(is_equal_approx(dragon.get_node("Timer").wait_time, dragon.base_cooldown * dragon.permanent_attack_speed_multiplier * 0.95))
	dragon.free()
	print("WEAPON_BASE_UPGRADES_TEST_PASSED")
	get_tree().quit()


func apply_upgrade(controller: Node, upgrade_id: String) -> void:
	var upgrade := load("res://resources/upgrades/%s.tres" % upgrade_id) as AbilityUpgrade
	controller.call("on_ability_upgrade_added", upgrade, {upgrade_id: {"quantity": 1}})


func create_controller(script_path: String, wait_time: float) -> Node:
	var controller := Node.new()
	controller.set_script(load(script_path))
	var timer := Timer.new()
	timer.name = "Timer"
	timer.wait_time = wait_time
	controller.add_child(timer)
	if script_path.contains("azure_dragon"):
		var ultimate_timer := Timer.new()
		ultimate_timer.name = "FourBeastsTimer"
		controller.add_child(ultimate_timer)
	add_child(controller)
	return controller
