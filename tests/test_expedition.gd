extends Node

var main: Node
var expedition: Node
var upgrades: Node


func select_upgrades() -> int:
	var selections := 0
	while upgrades.choice_screen_open:
		var screen: Node = upgrades.get_child(upgrades.get_child_count() - 1)
		var card: Node = screen.card_container.get_child(0)
		card.selected.emit()
		await screen.tree_exited
		await get_tree().process_frame
		selections += 1
	return selections


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "expedition"
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	expedition = main.get_node("ExpeditionManager")
	upgrades = main.get_node("UpgradeManager")
	expedition.maps.assign([4, 1, 5, 2, 3])
	expedition.patterns.assign(["rush", "ranged", "swift", "rush", "ranged"])
	assert(not main.get_node("EnemyManager").spawning)
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	await select_upgrades()
	assert(expedition.stage == expedition.Stage.WAVE and main.current_map_id == 4)
	var player: Node = main.get_node("Entities/Player")
	for room in 5:
		assert(expedition.stage == expedition.Stage.WAVE)
		assert(main.current_map_id == expedition.maps[room])
		assert(GameEvents.campaign_completed_maps == room)
		var spawner: Node = main.get_node("EnemyManager")
		if expedition.wave_pattern == "rush":
			assert(is_equal_approx(spawner.base_spawn_time, 0.9 * 0.65))
		elif expedition.wave_pattern == "ranged":
			assert(spawner.enemy_table.items.any(func(entry: Dictionary): return entry["item"] == spawner.ranged_enemy_scene and entry["weight"] == 30))
		else:
			var enemy := spawner.basic_enemy_scene.instantiate() as Node2D
			var movement := enemy.get_node("VelocityComponent") as VelocityComponent
			var original_speed := movement.max_speed
			spawner.apply_difficulty(enemy)
			assert(is_equal_approx(movement.max_speed, roundi(original_speed) * 1.35))
			enemy.free()
		main.get_node("ArenaTimeManager").time_elapsed = expedition.WAVE_DURATION
		expedition._process(0.0)
		assert(expedition.stage == expedition.Stage.BOSS and is_instance_valid(expedition.active_boss))
		var boss_health: HealthComponent = expedition.active_boss.get_node("HealthComponent")
		assert(is_equal_approx(boss_health.max_health, expedition.BOSS_BASE_HEALTH * (1.0 + room * expedition.BOSS_HEALTH_GROWTH) * MetaProgression.get_enemy_health_multiplier()))
		boss_health.damage(boss_health.current_health + 1.0)
		await get_tree().process_frame
		await get_tree().process_frame
		assert(expedition.defeated_bosses == room + 1)
		if room == 4:
			assert(expedition.stage == expedition.Stage.FINISHED and get_tree().paused)
			break
		assert(expedition.stage == expedition.Stage.CONTRACT and get_tree().paused)
		var choice: String = ["fury", "bulwark", "hunter", "supply"][room]
		var previous_crit := GameEvents.critical_disabled
		GameEvents.critical_disabled = true
		var damage_before := float(GameEvents.get_critical_damage(10.0)["damage"])
		if choice == "supply":
			player.health_component.current_health = player.health_component.max_health * 0.5
		var event := InputEventKey.new()
		event.keycode = KEY_1 + room
		event.pressed = true
		get_viewport().push_input(event, true)
		assert(expedition.stage == expedition.Stage.REWARD and get_tree().paused)
		var expected_damage_factor := 1.25 if choice == "fury" else (0.85 if choice == "bulwark" else 1.0)
		assert(is_equal_approx(float(GameEvents.get_critical_damage(10.0)["damage"]), damage_before * expected_damage_factor))
		GameEvents.critical_disabled = previous_crit
		assert(expedition.selected_contracts.size() == room + 1)
		if choice == "supply":
			assert(is_equal_approx(player.health_component.current_health, player.health_component.max_health * 0.85))
		var selections: int = await select_upgrades()
		assert(selections == (2 if choice == "supply" else 1))
		assert(expedition.stage == expedition.Stage.WAVE)
		if choice == "fury":
			var health_before: float = player.health_component.current_health
			player.health_component.set_shield(0.0)
			player.health_component.set_temporary_shield(0.0, 0.0)
			player.health_component.damage(5.0)
			assert(is_equal_approx(player.health_component.current_health, health_before - 6.0))
			player.health_component.heal(6.0)
	assert(is_equal_approx(GameEvents.expedition_damage_multiplier, 1.25 * 0.85))
	assert(is_equal_approx(GameEvents.expedition_incoming_multiplier, 1.2))
	assert(is_equal_approx(player.health_component.max_health, player.get_upgraded_max_health()))
	assert(GameEvents.expedition_speed_multiplier == 1.2)
	assert(expedition.selected_contracts.size() == 4)
	get_tree().paused = false
	GameEvents.reset_run_stats()
	assert(GameEvents.expedition_damage_multiplier == 1.0 and GameEvents.expedition_health_multiplier == 1.0)
	assert(GameEvents.expedition_speed_multiplier == 1.0 and GameEvents.expedition_incoming_multiplier == 1.0)
	assert(GameEvents.expedition_enemy_speed_multiplier == 1.0)
	print("EXPEDITION_OK")
	get_tree().quit()
