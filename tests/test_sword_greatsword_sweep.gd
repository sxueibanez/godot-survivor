extends SceneTree


func _initialize() -> void:
	var upgrade := load("res://resources/upgrades/sword_greatsword_sweep.tres") as AbilityUpgrade
	assert(upgrade != null)
	assert(upgrade.max_quantity == 1)
	assert(is_equal_approx(SwordGreatswordSweep.get_damage(5.0), 17.5))
	quit()
