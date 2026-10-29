extends Node


func seed_for_index(index: int, count: int) -> int:
	var rng := RandomNumberGenerator.new()
	for seed in range(1, 1000):
		rng.seed = seed
		if rng.randi_range(0, count - 1) == index:
			return seed
	return -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	mode.set_process(false)
	mode.player.set_process(false)
	mode.player.abilities.process_mode = Node.PROCESS_MODE_DISABLED
	mode.player.health_component.set_invulnerable(1000.0)
	mode.start_defense()
	await get_tree().process_frame
	Engine.time_scale = 8.0
	for index in [3, 4, 7, 9, 11]:
		mode.player.global_position = Vector2.ZERO
		mode.tower_health = mode.tower_max_health
		mode.rng.seed = seed_for_index(index, mode.ENEMY_SCENES.size())
		var enemy: Node2D = mode.spawn_enemy(Vector2(282, 0), "normal", true)
		await get_tree().create_timer(16.0).timeout
		assert(mode.tower_health < mode.tower_max_health, "Siege enemy failed to reach the tower: " + enemy.scene_file_path)
		for unit: Node in get_tree().get_nodes_in_group("enemy"):
			unit.queue_free()
		await get_tree().process_frame
	mode.player.global_position = Vector2.ZERO
	mode.tower_health = mode.tower_max_health
	mode.boss_count = 3
	var boss: Node2D = mode.spawn_enemy(Vector2(282, 0), "boss", true)
	await get_tree().create_timer(18.0).timeout
	assert(mode.tower_health < mode.tower_max_health, "Iron arm miner failed to reach the tower")
	Engine.time_scale = 1.0
	print("FRONTIER_SIEGE_AI_OK")
	get_tree().quit()
