extends Node


func _ready() -> void:
	GameEvents.game_mode = "campaign"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.call("begin_level_1")
	main.set_process(false)
	main.get_node("ArenaTimeManager").set_process(false)
	var spawner: Node = main.get_node("EnemyManager")
	spawner.stop_spawning()
	var events: Node = main.get("challenges")
	events.set_process(false)
	get_tree().paused = false
	var snowball := preload("res://scenes/game_object/snowball_monster/snowball_monster.tscn").instantiate()
	main.get_node("Entities").add_child(snowball)
	var fillers: Array[Node] = []
	for index in 26:
		var enemy := Node2D.new()
		enemy.add_to_group("enemy")
		main.get_node("Entities").add_child(enemy)
		fillers.append(enemy)
	assert(GameEvents.get_enemy_count() == 27)
	spawner.spawn_test_enemies(100)
	assert(GameEvents.get_enemy_count() == 28)
	assert(events.make_elite(Vector2.ZERO) == null)
	events.spawn_wave()
	snowball.call("split")
	assert(not snowball.is_queued_for_deletion())
	assert(GameEvents.get_enemy_count() == 28)
	var miner: Node2D = main.spawn_iron_arm_miner()
	var king: Node2D = main.spawn_slime_king()
	assert(miner != null and king != null)
	assert(GameEvents.get_enemy_count() == 30)
	assert(main.spawn_frost_queen() == null)
	miner.call("summon_golems")
	king.call("perform_slime_spray")
	spawner.spawning = true
	spawner.on_timer_timeout()
	assert(GameEvents.get_enemy_count() == 30)
	spawner.stop_spawning()
	events.finish_overload()
	assert(events.pending_overload_elite)
	for index in 3:
		fillers[index].queue_free()
	assert(GameEvents.get_enemy_count() == 27)
	events.call("_process", 0.01)
	assert(not events.pending_overload_elite)
	assert(GameEvents.get_enemy_count() == 28)
	spawner.spawn_test_enemies(100)
	assert(GameEvents.get_enemy_count() == 30)
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("ENEMY_CAP_TEST_PASSED")
	get_tree().quit()
