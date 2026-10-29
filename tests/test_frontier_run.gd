extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "frontier"
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	mode.player.global_position = Vector2(60, 0)
	mode.player.health_component.set_invulnerable(1000.0)
	var observed_shrink := false
	var saw_elite := false
	var saw_boss := false
	var saw_tower_damage := false
	var max_enemy_count := 0
	var start_ms := Time.get_ticks_msec()
	Engine.time_scale = 24.0
	while Time.get_ticks_msec() - start_ms < 50000 and (not saw_boss or not saw_elite or not saw_tower_damage):
		observed_shrink = observed_shrink or mode.safe_radius < mode.INITIAL_RADIUS
		if mode.defense_active:
			max_enemy_count = maxi(max_enemy_count, GameEvents.get_enemy_count())
			saw_elite = saw_elite or not get_tree().get_nodes_in_group("elite").is_empty()
			saw_boss = saw_boss or not get_tree().get_nodes_in_group("boss").is_empty()
			saw_tower_damage = saw_tower_damage or mode.tower_health < mode.tower_max_health
			mode.tower_health = mode.tower_max_health
		await get_tree().process_frame
	Engine.time_scale = 1.0
	assert(observed_shrink and mode.defense_active)
	assert(saw_elite and saw_boss and saw_tower_damage)
	assert(max_enemy_count <= mode.MAX_ENEMIES)
	print("FRONTIER_RUN_OK defense=%.1fs max_enemies=%d" % [mode.defense_time, max_enemy_count])
	get_tree().paused = false
	get_tree().quit()
