extends Node


class MockUpgradeManager extends Node:
	var current_upgrades: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.reset_run_stats()
	var sword := load("res://resources/upgrades/sword.tres") as Ability
	var axe := load("res://resources/upgrades/axe.tres") as Ability
	var manager := MockUpgradeManager.new()
	manager.name = "UpgradeManager"
	manager.current_upgrades = {"sword": {"resource": sword}, "axe": {"resource": axe}}
	add_child(manager)
	GameEvents.record_weapon_damage("sword", 150.0)
	GameEvents.record_weapon_damage("axe", 50.0)
	var screen := preload("res://scenes/ui/end_screen.tscn").instantiate()
	add_child(screen)
	assert(screen.get_node("%Weapon1Label").text.contains("输出 150（75%）"))
	assert(screen.get_node("%Weapon2Label").text.contains("输出 50（25%）"))
	GameEvents.weapon_damage.clear()
	screen.update_summary()
	assert(screen.get_node("%Weapon1Label").text.contains("输出 0（0%）"))
	assert(screen.get_node("%Weapon2Label").text.contains("输出 0（0%）"))
	print("WEAPON_DAMAGE_SHARE_OK")
	get_tree().paused = false
	GameEvents.reset_run_stats()
	screen.queue_free()
	await get_tree().process_frame
	get_tree().quit()
