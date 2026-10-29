extends Node


func _ready() -> void:
	GameEvents.reset_run_stats()
	var manager := preload("res://scenes/manager/enemy_manager.tscn").instantiate()
	var arena := ArenaTimeManager.new()
	manager.arena_time_manager = arena
	var enemy_scenes: Array[PackedScene] = [
		preload("res://scenes/game_object/basic_enemy/basic_enemy.tscn"),
		preload("res://scenes/game_object/wizard_enemy/wizard_enemy.tscn"),
	]
	for mode: String in ["campaign", "endless"]:
		GameEvents.game_mode = mode
		for difficulty: int in [0, 12]:
			GameEvents.arena_difficulty = difficulty
			arena.arena_difficulty = difficulty
			for enemy_scene: PackedScene in enemy_scenes:
				var expected_health := -1.0
				for map_id in range(1, 6):
					manager.level = map_id
					GameEvents.campaign_completed_maps = 2
					var enemy := enemy_scene.instantiate() as Node2D
					manager.apply_difficulty(enemy)
					add_child(enemy)
					var health := enemy.get_node("HealthComponent") as HealthComponent
					if expected_health < 0.0:
						expected_health = health.max_health
					assert(is_equal_approx(health.max_health, expected_health), "%s difficulty %d map %d" % [mode, difficulty, map_id])
					assert(is_equal_approx(health.current_health, health.max_health))
					enemy.queue_free()
	manager.free()
	arena.free()
	await get_tree().process_frame
	GameEvents.reset_run_stats()
	print("ENEMY_HEALTH_ACROSS_MAPS_OK")
	get_tree().quit()
