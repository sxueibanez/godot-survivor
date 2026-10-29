extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	mode.set_process(false)
	mode.start_defense()
	assert(mode.potions == 1)
	mode.gold = 0
	mode.tower_health = 1000
	mode.grant_defense_supply()
	assert(mode.gold == 25 and mode.tower_health == 1050 and mode.supply_count == 1)
	mode.grant_defense_supply()
	assert(mode.gold == 55 and mode.potions == 2)
	mode.buy_potion()
	assert(mode.gold == 25 and mode.potions == 3)
	mode.buy_potion()
	assert(mode.gold == 25 and mode.potions == 3)
	mode.gold = 100
	mode.repair_tower()
	assert(mode.gold == 50 and mode.tower_health == 1300)
	mode.close_panel()
	mode.salvage_weapon({"salvage_value": 45})
	assert(mode.gold == 95)
	mode.tower_health = 200
	mode.damage_tower(1)
	assert(mode.tower_warned)
	mode.repair_tower()
	assert(not mode.tower_warned and mode.tower_health == 399)
	mode.close_panel()
	mode.gold = 0
	mode.tower_health = 1000
	var boss: Node2D = mode.spawn_enemy(Vector2(282, 0), "boss", true)
	assert(boss != null)
	mode.on_enemy_died(boss)
	assert(mode.gold == 60 and mode.bosses_defeated == 1 and mode.tower_health == 1120)
	mode.potions = mode.MAX_POTIONS
	mode.gold = 0
	for seed in range(1, 1000):
		mode.rng.seed = seed
		var roll: int = mode.rng.randi_range(1, 100)
		if roll > 40 and roll <= 65:
			mode.rng.seed = seed
			break
	var chest := Node2D.new()
	chest.set_script(preload("res://scenes/frontier/map_marker.gd"))
	chest.level = 3
	mode.add_child(chest)
	mode.open_chest(chest)
	assert(mode.gold == 30 and mode.chests_opened == 1)
	print("FRONTIER_IMPROVEMENTS_OK")
	get_tree().paused = false
	get_tree().quit()

