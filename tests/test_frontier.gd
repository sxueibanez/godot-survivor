extends Node


func seed_for_roll(minimum: int, maximum: int) -> int:
	var rng := RandomNumberGenerator.new()
	for seed in range(1, 1000):
		rng.seed = seed
		var value := rng.randi_range(1, 100)
		if value >= minimum and value <= maximum:
			return seed
	return -1


func make_chest(mode: Node, level: int) -> Node2D:
	var chest := preload("res://scenes/frontier/map_marker.gd").new()
	chest.level = level
	chest.add_to_group("frontier_chest")
	mode.get_node("Entities").add_child(chest)
	return chest


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "frontier"
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	assert(get_tree().paused and mode.world.rocks.size() >= 300)
	var obstacle := mode.world.get_child(0) as StaticBody2D
	assert(obstacle != null and obstacle.collision_layer == 1 and obstacle.get_child(0) is CollisionShape2D)
	assert(mode.player.global_position.length() > 2700.0)
	assert(get_tree().get_nodes_in_group("frontier_chest").size() == 100)
	assert(get_tree().get_nodes_in_group("frontier_shop").size() == 10)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	assert(not get_tree().paused and mode.started)
	mode.player.set_process(false)
	assert(mode.inventory.items[0] != null and mode.inventory.items[1] == null)
	mode.rng.seed = seed_for_roll(1, 40)
	var chest := make_chest(mode, 3)
	chest.global_position = mode.player.global_position
	var interact_key := InputEventKey.new()
	interact_key.keycode = KEY_E
	interact_key.pressed = true
	mode._unhandled_key_input(interact_key)
	assert(mode.gold >= 60 and mode.gold <= 110)
	mode.rng.seed = seed_for_roll(41, 65)
	mode.open_chest(make_chest(mode, 2))
	assert(mode.potions == 2)
	var health: HealthComponent = mode.player.health_component
	health.current_health = health.max_health * 0.5
	health.health_changed.emit()
	mode.use_potion()
	assert(mode.potions == 1 and is_equal_approx(health.current_health, health.max_health * 0.75))
	mode.rng.seed = seed_for_roll(66, 100)
	mode.open_chest(make_chest(mode, 1))
	assert(mode.inventory.items[1] != null)
	mode.rng.seed = seed_for_roll(66, 100)
	mode.open_chest(make_chest(mode, 2))
	assert(get_tree().paused and is_instance_valid(mode.screen))
	var box := mode.screen.get_child(0).get_child(0).get_child(0) as VBoxContainer
	(box.get_child(box.get_child_count() - 2) as Button).pressed.emit()
	assert(not get_tree().paused)
	mode.gold = 500
	mode.show_forge_item(0)
	var old_skills: Array = mode.inventory.items[0].skills.duplicate()
	mode.buy_upgrade(0, 60)
	assert(mode.gold == 440 and mode.inventory.items[0].rarity == 2)
	assert(mode.inventory.items[0].skills.size() == 2 and mode.inventory.items[0].skills.has(old_skills[0]))
	mode.buy_upgrade(0, 60)
	assert(mode.gold == 440 and mode.inventory.items[0].rarity == 2)
	mode.buy_reroll(0, 50)
	assert(mode.gold == 390 and mode.inventory.items[0].skills.size() == 2)
	mode.close_panel()
	var inventory_key := InputEventKey.new()
	inventory_key.keycode = KEY_I
	inventory_key.pressed = true
	mode._unhandled_key_input(inventory_key)
	assert(get_tree().paused and is_instance_valid(mode.screen))
	mode.close_panel()
	var enemy: CharacterBody2D = mode.spawn_enemy(mode.player.global_position + Vector2(400, 0), "normal", false)
	assert(enemy != null)
	var ai: Node = enemy.get_node("FrontierEnemyAI")
	enemy.global_position = mode.player.global_position + Vector2(400, 0)
	ai._process(0.1)
	assert(not enemy.is_processing())
	enemy.global_position = mode.player.global_position + Vector2(300, 0)
	ai._process(0.1)
	assert(enemy.is_processing() and ai.alerted)
	enemy.global_position = mode.player.global_position + Vector2(450, 0)
	ai._process(0.1)
	assert(enemy.is_processing() and ai.alerted)
	enemy.global_position = mode.player.global_position + Vector2(451, 0)
	ai._process(0.1)
	assert(not enemy.is_processing() and not ai.alerted)
	enemy.global_position = mode.player.global_position + Vector2(350, 0)
	ai._process(0.1)
	assert(not enemy.is_processing())
	enemy.global_position = mode.player.global_position + Vector2(50, 0)
	ai._process(0.1)
	assert(enemy.is_processing())
	var paused_position := enemy.global_position
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	assert(enemy.global_position == paused_position)
	get_tree().paused = false
	mode.player.global_position = Vector2(mode.INITIAL_RADIUS + 100, 0)
	var before := health.current_health
	mode._process(0.1)
	assert(is_equal_approx(health.current_health, before - health.max_health * 0.05))
	mode.safe_radius = mode.FINAL_RADIUS + 250.0
	mode.cycle_elapsed = mode.SHRINK_INTERVAL
	mode.advance_zone(0.01)
	mode.advance_zone(mode.SHRINK_DURATION)
	assert(mode.defense_active and mode.safe_radius == mode.FINAL_RADIUS)
	await get_tree().process_frame
	var attacker: Node = mode.spawn_enemy(Vector2(20, 0), "normal", true)
	assert(attacker != null)
	var tower_before: float = mode.tower_health
	attacker.get_node("FrontierEnemyAI")._process(0.1)
	assert(mode.tower_health < tower_before)
	mode.inventory.equip({"id": "axe", "rarity": 1, "skills": ["axe_return"]}, 1)
	await get_tree().process_frame
	await get_tree().process_frame
	health.set_shield(0.0)
	health.set_temporary_shield(0.0, 0.0)
	health.invulnerable_time_left = 0.0
	health.damage(health.current_health + 1.0)
	await get_tree().process_frame
	assert(mode.respawning and not mode.finished and not get_tree().paused)
	var while_downed: float = mode.tower_health
	attacker.get_node("FrontierEnemyAI")._process(1.1)
	assert(mode.tower_health < while_downed)
	mode._process(mode.RESPAWN_TIME)
	assert(not mode.respawning and is_equal_approx(health.current_health, health.max_health * 0.5))
	assert(health.invulnerable_time_left >= 2.0 and mode.player.visible)
	mode.damage_tower(mode.tower_health)
	assert(mode.finished and get_tree().paused and is_instance_valid(mode.screen))
	get_tree().paused = false
	mode.queue_free()
	await get_tree().process_frame
	var new_run := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(new_run)
	for child: Node in new_run.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/one_armed.tres"))
	assert(new_run.gold == 0 and new_run.potions == 0)
	assert(new_run.inventory.items[0].rarity == 1 and new_run.inventory.items[1] == null)
	assert(new_run.get_weapon_limit() == 1)
	assert(not new_run.inventory.can_equip(new_run.inventory.items[0], 1))
	print("FRONTIER_OK")
	get_tree().quit()
