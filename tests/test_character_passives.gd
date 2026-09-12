extends SceneTree


func _init() -> void:
	var warrior := load("res://resources/characters/warrior.tres") as Resource
	var elf_ranger := load("res://resources/characters/elf_ranger.tres") as Resource
	var blooddrinker := load("res://resources/characters/blooddrinker.tres") as Resource
	var sword := load("res://resources/upgrades/sword.tres") as Ability
	var axe := load("res://resources/upgrades/axe.tres") as Ability
	var laser := load("res://resources/upgrades/laser_gun.tres") as Ability
	var whip := load("res://resources/upgrades/lightning_whip.tres") as Ability
	var bomb := load("res://resources/upgrades/bomb.tres") as Ability
	var thunder_orb_book := load("res://resources/upgrades/thunder_orb_book.tres") as Ability
	var pagoda := load("res://resources/upgrades/nine_treasure_pagoda.tres") as Ability
	assert(sword.weapon_type == Ability.WeaponType.MELEE)
	assert(whip.weapon_type == Ability.WeaponType.MELEE)
	assert(axe.weapon_type == Ability.WeaponType.RANGED)
	assert(laser.weapon_type == Ability.WeaponType.RANGED)
	assert(bomb.weapon_type == Ability.WeaponType.RANGED)
	assert(thunder_orb_book.weapon_type == Ability.WeaponType.RANGED)
	assert(pagoda.weapon_type == Ability.WeaponType.SUPPORT)
	assert(is_equal_approx(float(warrior.call("get_weapon_damage_multiplier", pagoda)), 1.0))
	assert(is_equal_approx(float(warrior.call("get_weapon_damage_multiplier", sword)), 1.15))
	assert(is_equal_approx(float(warrior.call("get_weapon_damage_multiplier", axe)), 1.0))
	assert(is_equal_approx(float(elf_ranger.call("get_weapon_damage_multiplier", sword)), 1.0))
	assert(is_equal_approx(float(elf_ranger.call("get_weapon_damage_multiplier", axe)), 1.15))
	assert(float(warrior.get("max_health")) == 130.0)
	assert(int(warrior.get("move_speed")) == 75)
	assert(float(elf_ranger.get("max_health")) == 100.0)
	assert(int(elf_ranger.get("move_speed")) == 100)
	assert(float(blooddrinker.get("max_health")) == 150.0)
	assert(int(blooddrinker.get("move_speed")) == 70)
	assert(is_equal_approx(float(blooddrinker.get("missing_health_damage_bonus_per_10")), 0.03))
	assert(int(blooddrinker.get("missing_health_speed_bonus_per_10")) == 3)
	var player_script := load("res://scenes/game_object/player/player.gd") as GDScript
	assert(player_script.get_missing_health_stacks(150.0, 150.0) == 0)
	assert(player_script.get_missing_health_stacks(150.0, 140.0) == 1)
	assert(player_script.get_missing_health_stacks(150.0, 119.9) == 3)
	assert(is_equal_approx(player_script.get_speed_damage_multiplier(19), 1.0))
	assert(is_equal_approx(player_script.get_speed_damage_multiplier(20), 1.1))
	assert(is_equal_approx(player_script.get_speed_damage_multiplier(75), 1.3))
	assert(!bool(elf_ranger.get("custom_walk_animation")))
	quit()
