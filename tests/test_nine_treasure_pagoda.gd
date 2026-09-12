extends Node

const CONTROLLER = preload("res://scenes/ability/nine_treasure_pagoda_controller/nine_treasure_pagoda_controller.gd")


func _ready() -> void:
	GameEvents.reset_run_stats()
	var weapon := load("res://resources/upgrades/nine_treasure_pagoda.tres") as Ability
	assert(weapon != null and weapon.weapon_type == Ability.WeaponType.SUPPORT and weapon.icon != null)
	assert(is_equal_approx(CONTROLLER.get_bonus_multiplier(0.15, 0.0, false), 1.15))
	assert(is_equal_approx(CONTROLLER.get_bonus_multiplier(0.15, 0.15, false), 1.30))
	assert(is_equal_approx(CONTROLLER.get_bonus_multiplier(0.15, 0.15, true), 1.60))
	for upgrade_id: String in ["damage", "attack_speed", "health", "move_speed", "extra_attack"]:
		assert(load("res://resources/upgrades/nine_treasure_%s.tres" % upgrade_id) is AbilityUpgrade)
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	add_child(foreground)
	var player := load("res://scenes/game_object/player/player.tscn").instantiate() as CharacterBody2D
	add_child(player)
	var dummy_weapon := Node.new()
	dummy_weapon.name = "DummyWeapon"
	var timer := Timer.new()
	timer.name = "Timer"
	timer.wait_time = 1.0
	dummy_weapon.add_child(timer)
	player.get_node("Abilities").add_child(dummy_weapon)
	var controller := load("res://scenes/ability/nine_treasure_pagoda_controller/nine_treasure_pagoda_controller.tscn").instantiate() as NineTreasurePagodaController
	player.get_node("Abilities").add_child(controller)
	assert(is_equal_approx(GameEvents.support_damage_multiplier, 1.15))
	assert(is_equal_approx(GameEvents.support_health_multiplier, 1.20))
	for upgrade_id: String in ["damage", "size", "rate"]:
		var id := "nine_treasure_pagoda_%s" % upgrade_id
		controller.on_ability_upgrade_added(load("res://resources/upgrades/%s.tres" % id), {id: {"quantity": 1}})
	controller._process(0.0)
	assert(is_equal_approx(GameEvents.support_damage_multiplier, 1.25))
	assert(is_equal_approx(GameEvents.support_size_multiplier, 1.10))
	assert(is_equal_approx(timer.wait_time, 0.90 / 1.20))
	controller._process(CONTROLLER.STANDING_DELAY)
	assert(controller.stationary and is_equal_approx(GameEvents.support_damage_multiplier, 1.50))
	assert(is_equal_approx(GameEvents.support_health_multiplier, 1.40))
	assert(is_equal_approx(GameEvents.support_size_multiplier, 1.20))
	assert(is_equal_approx(timer.wait_time, 0.80 / 1.40))
	assert(is_equal_approx(player.get_node("HealthComponent").get_health_percent(), 1.0))
	for upgrade_id: String in ["damage", "attack_speed", "health", "move_speed"]:
		var id := "nine_treasure_%s" % upgrade_id
		controller.on_ability_upgrade_added(load("res://resources/upgrades/%s.tres" % id), {id: {"quantity": 1}})
	controller._process(0.0)
	assert(is_equal_approx(GameEvents.support_damage_multiplier, 1.80))
	assert(is_equal_approx(GameEvents.support_health_multiplier, 1.80))
	assert(is_equal_approx(GameEvents.support_move_speed_multiplier, 1.40))
	assert(is_equal_approx(timer.wait_time, 0.80 / 1.80))
	controller.on_ability_upgrade_added(load("res://resources/upgrades/nine_treasure_extra_attack.tres"), {"nine_treasure_extra_attack": {"quantity": 1}})
	assert(GameEvents.weapon_attack_count == 2)
	GameEvents.emit_ability_upgrade_added(load("res://resources/upgrades/attack_count.tres"), {"attack_count": {"quantity": 1}})
	assert(GameEvents.weapon_attack_count == 3)
	var pagoda := foreground.get_child(0) as NineTreasurePagodaAbility
	assert(pagoda != null and pagoda.z_index < player.z_index and pagoda.sprite.region_enabled)
	assert(is_equal_approx(pagoda.get_node("WhiteLightTimer").wait_time, 5.0))
	var enemy := CharacterBody2D.new()
	enemy.add_to_group("enemy")
	enemy.global_position = pagoda.global_position + Vector2.RIGHT * 50.0
	var enemy_velocity := VelocityComponent.new()
	enemy_velocity.name = "VelocityComponent"
	enemy.add_child(enemy_velocity)
	add_child(enemy)
	pagoda.emit_white_light()
	assert(is_equal_approx(enemy_velocity.stun_time_left, NineTreasurePagodaAbility.STUN_DURATION))
	print("NINE_TREASURE_PAGODA_TEST_PASSED")
	get_tree().quit()
