extends SceneTree


func _init() -> void:
	var warrior := load("res://resources/characters/warrior.tres") as Resource
	var elf_ranger := load("res://resources/characters/elf_ranger.tres") as Resource
	var sword := load("res://resources/upgrades/sword.tres") as Ability
	var axe := load("res://resources/upgrades/axe.tres") as Ability
	var laser := load("res://resources/upgrades/laser_gun.tres") as Ability
	var whip := load("res://resources/upgrades/lightning_whip.tres") as Ability
	assert(sword.weapon_type == Ability.WeaponType.MELEE)
	assert(whip.weapon_type == Ability.WeaponType.MELEE)
	assert(axe.weapon_type == Ability.WeaponType.RANGED)
	assert(laser.weapon_type == Ability.WeaponType.RANGED)
	assert(is_equal_approx(float(warrior.call("get_weapon_damage_multiplier", sword)), 1.15))
	assert(is_equal_approx(float(warrior.call("get_weapon_damage_multiplier", axe)), 1.0))
	assert(is_equal_approx(float(elf_ranger.call("get_weapon_damage_multiplier", sword)), 1.0))
	assert(is_equal_approx(float(elf_ranger.call("get_weapon_damage_multiplier", axe)), 1.15))
	assert(!bool(elf_ranger.get("custom_walk_animation")))
	quit()
