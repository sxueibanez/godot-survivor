extends SceneTree


func _initialize() -> void:
	var weapon := load("res://resources/upgrades/sniper_rifle.tres") as Ability
	var diamond_bullet := load("res://resources/upgrades/sniper_rifle_diamond_bullet.tres") as AbilityUpgrade
	var shadowless_bullet := load("res://resources/upgrades/sniper_rifle_shadowless_bullet.tres") as AbilityUpgrade
	var ricochet := load("res://resources/upgrades/sniper_rifle_ricochet.tres") as AbilityUpgrade
	var explosive_bullet := load("res://resources/upgrades/sniper_rifle_explosive_bullet.tres") as AbilityUpgrade
	assert(weapon != null and weapon.id == "sniper_rifle")
	assert(diamond_bullet != null and diamond_bullet.max_quantity == 1)
	assert(shadowless_bullet != null and shadowless_bullet.max_quantity == 1)
	assert(ricochet != null and ricochet.max_quantity == 1)
	assert(explosive_bullet != null and explosive_bullet.max_quantity == 1)
	assert(load("res://scenes/ability/sniper_rifle_controller/sniper_rifle_controller.tscn") != null)
	assert(is_equal_approx(SniperRifleBullet.get_fragment_damage(100.0), 25.0))
	assert(is_equal_approx(SniperRifleBullet.get_explosion_damage(100.0), 50.0))
	quit()
