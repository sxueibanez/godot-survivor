extends Node

var main: Node
var rush: Node
var upgrades: Node
var selections := 0


func select_upgrades(count: int) -> void:
	for index in count:
		assert(get_tree().paused)
		assert(GameEvents.get_enemy_count(true) == 0)
		var screen: Node = upgrades.get_child(upgrades.get_child_count() - 1)
		var card: Node = screen.card_container.get_child(0)
		card.selected.emit()
		await screen.tree_exited
		await get_tree().process_frame
		selections += 1


func press_number(key: int, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.echo = echo
	get_viewport().push_input(event)
	event = InputEventKey.new()
	event.keycode = key
	get_viewport().push_input(event)


func _ready() -> void:
	GameEvents.game_mode = "boss_rush"
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	rush = main.boss_rush
	upgrades = main.get_node("UpgradeManager")
	assert(rush.combat_time == 0.0)
	assert(main.get_node("ArenaTimeManager").time_elapsed == 0.0)
	# Even stale ordinary-mode counters must not affect this mode's difficulty.
	GameEvents.arena_difficulty = 1000
	GameEvents.campaign_completed_maps = 99
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	await select_upgrades(5)
	assert(selections == 5 and rush.stage == rush.Stage.FIGHT)
	var player: Node = main.get_node("Entities/Player")
	var health: HealthComponent = player.health_component
	var companion: Node = preload("res://scenes/ability/azure_dragon/azure_dragon.tscn").instantiate()
	main.get_node("Foreground").add_child(companion)
	var controllers: int = player.abilities.get_child_count()
	for battle in 5:
		assert(main.current_map_id == battle + 1)
		assert(GameEvents.get_enemy_count(true) == 1)
		assert(rush.active_boss.get_node("HealthComponent").max_health == rush.BOSS_HEALTH[battle])
		assert(not main.get_node("EnemyManager").spawning)
		assert(main.spawn_boss_for_map(1) == null)
		rush.start_fight()
		assert(GameEvents.get_enemy_count(true) == 1)
		var summon: Node = preload("res://scenes/game_object/iron_golem/iron_golem.tscn").instantiate()
		main.get_node("Entities").add_child(summon)
		assert(summon.get_node("HealthComponent").max_health == 25.0)
		var projectile := Node2D.new()
		main.get_node("Foreground").add_child(projectile)
		rush._process(2.0)
		var before: float = rush.combat_time
		rush.active_boss.get_node("HealthComponent").damage(100000.0)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		assert(not is_instance_valid(summon) and not is_instance_valid(projectile))
		assert(is_instance_valid(companion))
		assert(player.abilities.get_child_count() >= controllers)
		assert(rush.defeated_bosses == battle + 1)
		rush.on_boss_died()
		assert(rush.defeated_bosses == battle + 1)
		assert(rush.combat_time < before + 0.1)
		if battle == 4:
			break
		await select_upgrades(1)
		assert(rush.stage == rush.Stage.REST and get_tree().paused)
		var rest_time: float = rush.combat_time
		await get_tree().create_timer(0.1).timeout
		assert(rush.combat_time == rest_time)
		health.current_health = health.max_health * 0.9
		press_number(KEY_1, true)
		assert(rush.stage == rush.Stage.REST)
		if battle == 1:
			press_number(KEY_2)
			assert(rush.stage == rush.Stage.EXTRA and upgrades.choice_screen_open)
			assert(health.current_health == health.max_health * 0.9)
			await select_upgrades(1)
		else:
			press_number(KEY_KP_1 if battle == 2 else KEY_1)
			assert(health.current_health == health.max_health)
		assert(rush.stage == rush.Stage.FIGHT)
	assert(selections == 10)
	assert(rush.stage == rush.Stage.ROUND_COMPLETE and get_tree().paused)
	assert(main.get_child(main.get_child_count() - 1) is EndScreen)
	assert(main.get_child(main.get_child_count() - 1).get_node("%DefeatReasonLabel").text.contains("累计击败 5"))
	var result: EndScreen = rush.result_screen
	result.get_node("%Weapon1Label").text = "超长战报\n".repeat(100)
	await get_tree().create_timer(0.4).timeout
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	for button_name: String in ["ContinueButton", "QuitButton"]:
		var rect: Rect2 = result.get_node("%" + button_name).get_global_rect()
		assert(rect.position.y >= 0 and rect.end.y <= viewport_size.y)
		assert(rect.position.x >= 0 and rect.end.x <= viewport_size.x)
	var previous_time: float = rush.combat_time
	var previous_health: float = health.current_health
	result.on_continue_button_pressed()
	rush.continue_round()
	assert(rush.round_number == 2 and upgrades.initial_choices_remaining == 3)
	assert(get_tree().paused and health.current_health == previous_health)
	await select_upgrades(3)
	assert(rush.combat_time < previous_time + 0.1)
	for battle in 5:
		assert(rush.stage == rush.Stage.FIGHT)
		assert(GameEvents.get_enemy_count(true) == 2)
		assert(rush.remaining_bosses == 2)
		assert(main.current_map_id == battle + 1)
		var bosses: Array[Node] = get_tree().get_nodes_in_group("boss")
		assert(bosses[0].scene_file_path != bosses[1].scene_file_path)
		var first_id: int = bosses[0].get_instance_id()
		bosses[0].get_node("HealthComponent").damage(100000.0)
		await get_tree().process_frame
		await get_tree().process_frame
		assert(rush.stage == rush.Stage.FIGHT and rush.remaining_bosses == 1)
		rush.on_boss_died(first_id)
		assert(rush.remaining_bosses == 1)
		assert(not upgrades.choice_screen_open)
		bosses[1].get_node("HealthComponent").damage(100000.0)
		for frame in 4:
			await get_tree().process_frame
		if battle < 4:
			await select_upgrades(1)
			rush.choose_rest(true)
	assert(rush.stage == rush.Stage.ROUND_COMPLETE and rush.defeated_bosses == 15)
	assert(rush.result_screen.get_node("%ContinueButton").text.contains("第3轮"))
	assert(rush.result_screen.get_node("%ContinueButton").text.contains("再选3次"))
	rush.result_screen.on_continue_button_pressed()
	await select_upgrades(3)
	assert(rush.round_number == 3 and rush.remaining_bosses == 3)
	assert(GameEvents.get_enemy_count(true) == 3)
	var third_bosses: Array[Node] = get_tree().get_nodes_in_group("boss")
	var boss_types: Dictionary = {}
	for boss in third_bosses:
		boss_types[boss.scene_file_path] = true
	assert(boss_types.size() == 3)
	for index in 3:
		third_bosses[index].get_node("HealthComponent").damage(100000.0)
		for frame in 4:
			await get_tree().process_frame
		if index < 2:
			assert(rush.stage == rush.Stage.FIGHT)
			assert(not upgrades.choice_screen_open)
	assert(rush.stage == rush.Stage.REWARD and rush.defeated_bosses == 18)
	rush.finish(false)
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	rush = main.boss_rush
	rush.round_number = 31
	upgrades = main.get_node("UpgradeManager")
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	await select_upgrades(5)
	assert(GameEvents.get_enemy_count(true) == 30)
	assert(rush.pending_boss_maps.size() == 1)
	get_tree().get_first_node_in_group("boss").get_node("HealthComponent").damage(100000.0)
	for frame in 4:
		await get_tree().process_frame
	assert(rush.remaining_bosses == 30 and rush.pending_boss_maps.is_empty())
	assert(GameEvents.get_enemy_count(true) == 30)
	get_tree().paused = false
	main.get_node("Entities/Player/HealthComponent").damage(100000.0)
	await get_tree().process_frame
	assert(rush.stage == rush.Stage.FINISHED)
	assert(GameEvents.get_enemy_count(true) == 0)
	assert(main.get_child(main.get_child_count() - 1).get_node("%TitleLabel").text == "失败")
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	for mode: String in ["campaign", "endless"]:
		GameEvents.game_mode = mode
		main = preload("res://scenes/main/main.tscn").instantiate()
		add_child(main)
		assert(main.boss_rush == null)
		upgrades = main.get_node("UpgradeManager")
		for child: Node in main.get_children():
			if child.has_signal("character_selected"):
				child.select_character(preload("res://resources/characters/warrior.tres"))
		var rounds: int = upgrades.initial_choices_remaining
		assert(rounds == (5 if mode == "endless" else 1) + clampi(MetaProgression.get_upgrade_count("meta_initial_choices"), 0, 1))
		await select_upgrades(rounds)
		assert(main.get_node("EnemyManager").spawning)
		if mode == "endless":
			main.get_node("ArenaTimeManager").time_elapsed = 60.0
			main._process(0.0)
			assert(GameEvents.get_enemy_count(true) == 1)
			assert(main.next_endless_boss_time == 120.0)
			get_tree().get_first_node_in_group("boss").get_node("HealthComponent").damage(100000.0)
			await get_tree().process_frame
			assert(upgrades.choice_screen_open)
		main.queue_free()
		await get_tree().process_frame
		get_tree().paused = false
	print("Boss rush checks passed: 3 upgrades per new round, 1/2/3 bosses, all-dead gate, 30-enemy cap, bounded report/buttons, healing, cleanup, duplicate guards, defeat")
	print("Campaign and endless entry / initial upgrades / spawning regression checks passed")
	get_tree().quit()
