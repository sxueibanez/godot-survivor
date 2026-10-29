extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	mode.set_process(false)
	mode.player.set_process(false)
	mode.player.global_position = Vector2(1000, 500)
	var map := preload("res://scenes/frontier/minimap.gd").new()
	map.mode = mode
	add_child(map)
	assert(map.MAP_SIZE == 88.0 and map.VIEW_RADIUS == 1000.0)
	assert(map.map_point(mode.player.global_position) == Vector2(44, 44))
	assert(map.in_view(mode.player.global_position + Vector2(1000, 0)))
	assert(not map.in_view(mode.player.global_position + Vector2(1000.1, 0)))
	assert(not map.in_view(mode.player.global_position + Vector2(800, 800)))
	assert(map.map_point(mode.player.global_position + Vector2(1000, 0)) == Vector2(84, 44))
	var exploration_enemy: Node2D = get_tree().get_first_node_in_group("enemy")
	assert(exploration_enemy.get_node("HealthComponent").max_health == 60.0)
	var replenished: Node2D = mode.spawn_enemy(Vector2(1000, 600), "normal", false)
	assert(replenished.get_node("HealthComponent").max_health == 60.0)
	mode.player.global_position = Vector2(mode.TOWER_TOUCH_RANGE + 1.0, 0)
	mode.exploration_spawn_timer = 100.0
	mode._process(0.01)
	assert(not mode.defense_active)
	mode.shrinking = true
	mode.player.global_position = Vector2(mode.TOWER_TOUCH_RANGE, 0)
	get_tree().paused = true
	mode._process(0.01)
	assert(not mode.defense_active)
	get_tree().paused = false
	mode._process(0.01)
	assert(mode.defense_active and not mode.shrinking and mode.safe_radius == mode.FINAL_RADIUS)
	assert(mode.target_radius == mode.FINAL_RADIUS and mode.previous_radius == mode.FINAL_RADIUS)
	await get_tree().process_frame
	var defender: Node2D = mode.spawn_enemy(Vector2(100, 0), "normal", true)
	assert(defender.get_node("HealthComponent").max_health >= 20.0 and defender.get_node("HealthComponent").max_health < 21.0)
	assert(mode.boss_timer > 0.0 and mode.elite_timer > 0.0)
	print("FRONTIER_LOCAL_MAP_EARLY_DEFENSE_OK")
	get_tree().quit()
