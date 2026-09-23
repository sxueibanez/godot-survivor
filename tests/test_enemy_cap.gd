extends Node


func _ready() -> void:
	GameEvents.game_mode = "campaign"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.call("begin_level_1")
	main.set_process(false)
	main.get_node("ArenaTimeManager").set_process(false)
	var spawner: Node = main.get_node("EnemyManager")
	spawner.start_level_1()
	assert(spawner.elite_timer.wait_time == 15.0 and not spawner.elite_timer.is_stopped())
	spawner.stop_spawning()
	var events: Node = main.get("challenges")
	events.set_process(false)
	get_tree().paused = false
	spawner.spawning = true
	var elite: Node2D = spawner.spawn_elite()
	assert(elite != null and elite.is_in_group("elite"))
	assert(elite.scale == Vector2.ONE * 1.5)
	var elite_health := elite.get_node("HealthComponent") as HealthComponent
	assert(is_equal_approx(elite_health.max_health, GameEvents.get_campaign_enemy_health(elite_health.enemy_base_health) * MetaProgression.get_enemy_health_multiplier() * 5.0))
	assert(GameEvents.get_enemy_damage(elite, 10.0) == 15.0)
	assert(elite.get_node("VelocityComponent").max_speed == 28.0)
	assert(elite.get_node("VialDropComponent").disabled)
	elite_health.damage(100000.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var elite_vials := get_tree().get_nodes_in_group("experience_vial")
	assert(elite_vials.size() >= 5 and elite_vials.size() <= 10)
	for vial: Node in elite_vials:
		vial.queue_free()
	spawner.stop_spawning()
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
