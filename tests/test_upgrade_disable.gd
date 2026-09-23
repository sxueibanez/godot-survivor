extends SceneTree


func _initialize() -> void:
	var manager := preload("res://scenes/manager/upgrade_manager.gd").new()
	var upgrade := load("res://resources/upgrades/sword_damage.tres") as AbilityUpgrade
	manager.upgrade_pool.add_item(upgrade, 10)
	manager.weapon_pool.add_item(upgrade, 10)
	manager.disable_upgrade_for_run(upgrade)
	assert(manager.disabled_upgrade_ids.has(upgrade.id))
	assert(manager.upgrade_pool.items.is_empty())
	assert(manager.weapon_pool.items.is_empty())
	quit()
