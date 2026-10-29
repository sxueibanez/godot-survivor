extends Node


func _ready() -> void:
	GameEvents.reset_run_stats()
	var manager := preload("res://scenes/manager/enemy_manager.tscn").instantiate()
	var arena := ArenaTimeManager.new()
	manager.arena_time_manager = arena
	var scenes: Array[PackedScene] = [
		preload("res://scenes/game_object/basic_enemy/basic_enemy.tscn"),
		preload("res://scenes/game_object/wizard_enemy/wizard_enemy.tscn"),
		preload("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn"),
		preload("res://scenes/game_object/ranged_enemy/ranged_enemy.tscn"),
		preload("res://scenes/game_object/cyclops_bat/cyclops_bat.tscn"),
		preload("res://scenes/game_object/iron_golem/iron_golem.tscn"),
		preload("res://scenes/game_object/stone_slime/stone_slime.tscn"),
		preload("res://scenes/game_object/frost_wisp/frost_wisp.tscn"),
		preload("res://scenes/game_object/frost_boar/frost_boar.tscn"),
		preload("res://scenes/game_object/snowball_monster/snowball_monster.tscn"),
		preload("res://scenes/game_object/forge_enemy/cinder.tscn"),
		preload("res://scenes/game_object/forge_enemy/worker.tscn"),
		preload("res://scenes/game_object/forge_enemy/guard.tscn"),
	]
	for mode: String in ["campaign", "endless", "expedition"]:
		GameEvents.game_mode = mode
		GameEvents.campaign_completed_maps = 2
		GameEvents.arena_difficulty = 12
		arena.arena_difficulty = 12
		var expected := 12.0 * 2.3 * 1.15 if mode in ["campaign", "expedition"] else 10.0 * 0.5 * 1.6
		expected *= MetaProgression.get_enemy_health_multiplier()
		for scene: PackedScene in scenes:
			var enemy := scene.instantiate() as Node2D
			manager.apply_difficulty(enemy)
			add_child(enemy)
			var health := enemy.get_node("HealthComponent") as HealthComponent
			assert(is_equal_approx(health.max_health, expected), "%s %s: %s vs %s" % [mode, scene.resource_path, health.max_health, expected])
			assert(is_equal_approx(health.current_health, expected))
			if enemy.has_method("configure_small"):
				enemy.configure_small()
				assert(is_equal_approx(health.max_health, expected * 0.35))
			enemy.queue_free()
	manager.free()
	arena.free()
	await get_tree().process_frame
	GameEvents.reset_run_stats()
	print("EQUAL_ENEMY_BASE_HEALTH_OK")
	get_tree().quit()
