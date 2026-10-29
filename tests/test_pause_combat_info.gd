extends Node


class MockUpgrades extends Node:
	var current_upgrades: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var host := Node.new()
	add_child(host)
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	host.add_child(player)
	var upgrades := MockUpgrades.new()
	upgrades.name = "UpgradeManager"
	var sword: AbilityUpgrade = load("res://resources/upgrades/sword.tres")
	upgrades.current_upgrades[sword.id] = {"resource": sword, "quantity": 1}
	host.add_child(upgrades)
	player.health_component.set_shield(7.0)
	player.health_component.set_temporary_shield(3.0, 10.0)
	GameEvents.weapon_damage[sword.id] = 123.0
	var menu := preload("res://scenes/ui/pause_menu.tscn").instantiate()
	host.add_child(menu)
	assert(menu.attributes_label.text.contains("护盾  10"))
	assert(menu.skills_label.text.contains("累计伤害 123"))
	get_tree().paused = false
	print("PAUSE_COMBAT_INFO_OK")
	get_tree().quit()
