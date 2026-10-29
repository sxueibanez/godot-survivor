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
	assert(mode.world.HALF_SIZE == 3200.0 and mode.active_enemy_count() == 100)
	assert(mode.SHRINK_INTERVAL == 60.0 and mode.SHRINK_DURATION == 20.0)
	mode.player.global_position = Vector2.ZERO
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		enemy.global_position = Vector2(2000, 2000)
		enemy.set_process(false)
	mode.process_exploration(4.0)
	assert(mode.active_enemy_count() == 105)
	for index in 20:
		mode.spawn_enemy(Vector2(1000, 1000), "normal", false)
	assert(mode.active_enemy_count() == mode.MAX_ENEMIES - 2)
	assert(not GameEvents.can_spawn_enemy())
	var reserved_boss: Node2D = mode.spawn_enemy(Vector2(1000, 1000), "boss", false)
	assert(reserved_boss != null and mode.active_enemy_count() == mode.MAX_ENEMIES - 1)
	mode.boss_count = 0
	mode.start_defense()
	await get_tree().process_frame
	mode.elite_timer = 999.0
	mode.boss_timer = 999.0
	mode.process_defense(0.01)
	assert(mode.active_enemy_count() == 3)
	mode.defense_time = 180.0
	mode.wave_timer = 0.0
	mode.process_defense(0.01)
	assert(mode.active_enemy_count() == 9 and mode.wave_timer < 1.0)
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	await get_tree().process_frame
	for index in mode.ENEMY_SCENES.size():
		mode.rng.seed = seed_for_index(index, mode.ENEMY_SCENES.size())
		var monster: Node2D = mode.spawn_enemy(Vector2(30, 0), "normal", true)
		monster.set_process(false)
		assert(monster.scene_file_path == mode.ENEMY_SCENES[index].resource_path)
		assert(monster.is_in_group("frontier_siege"))
		var before: float = mode.tower_health
		monster.get_node("FrontierEnemyAI")._process(0.01)
		assert(mode.tower_health < before)
		mode.tower_health = mode.tower_max_health
		monster.queue_free()
	await get_tree().process_frame
	var methods := ["perform_slime_spray", "ice_shard_fan", "cast_divine_punishment", "ground_slam", "start_skill"]
	for index in mode.BOSS_SCENES.size():
		var boss: Node2D = mode.spawn_enemy(Vector2(50, 0), "boss", true)
		boss.set_process(false)
		boss.get_node("FrontierEnemyAI").set_process(false)
		assert(boss.scene_file_path == mode.BOSS_SCENES[index].resource_path)
		assert(boss.is_in_group("boss") and boss.has_method(methods[index]))
		await get_tree().process_frame
		var movement := boss.get_node("VelocityComponent") as VelocityComponent
		movement.velocity = Vector2.ZERO
		movement.accelerate_in_direction(Vector2.RIGHT)
		assert(movement.velocity.x < 0.0)
		var before: float = mode.tower_health
		boss.get_node("FrontierEnemyAI")._process(0.1)
		assert(mode.tower_health == before - 28.0)
		mode.tower_health = mode.tower_max_health
		if index == 0:
			var count_before: int = mode.active_enemy_count()
			boss.perform_slime_spray()
			assert(mode.active_enemy_count() > count_before)
			for summon: Node in get_tree().get_nodes_in_group("enemy"):
				if summon != boss:
					assert(summon.is_in_group("frontier_siege") and summon.has_node("FrontierEnemyAI"))
					summon.queue_free()
			var previous_gold: int = mode.gold
			var boss_health := boss.get_node("HealthComponent") as HealthComponent
			boss_health.damage(boss_health.current_health + 1.0)
			await get_tree().process_frame
			await get_tree().process_frame
			assert(mode.gold == previous_gold + 60)
		elif index == 1:
			var projectiles := mode.get_node("EnemyProjectiles")
			var count_before: int = projectiles.get_child_count()
			boss.ice_shard_fan()
			await get_tree().create_timer(0.6).timeout
			assert(projectiles.get_child_count() > count_before)
		if is_instance_valid(boss):
			boss.queue_free()
		await get_tree().process_frame
	print("FRONTIER_BALANCE_BOSSES_OK monsters=%d bosses=%d" % [mode.ENEMY_SCENES.size(), mode.BOSS_SCENES.size()])
	get_tree().quit()
