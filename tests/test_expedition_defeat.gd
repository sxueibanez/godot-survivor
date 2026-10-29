extends Node

var upgrades: Node


func select_upgrades() -> void:
	while upgrades.choice_screen_open:
		var screen: Node = upgrades.get_child(upgrades.get_child_count() - 1)
		screen.card_container.get_child(0).selected.emit()
		await screen.tree_exited
		await get_tree().process_frame


func press_number(number: int) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_1 + number - 1
	event.pressed = true
	get_viewport().push_input(event, true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "expedition"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	var expedition: Node = main.get_node("ExpeditionManager")
	upgrades = main.get_node("UpgradeManager")
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	await select_upgrades()
	var life_steal_before := GameEvents.life_steal_percent
	get_tree().paused = true
	expedition.show_contracts()
	press_number(5)
	assert(is_equal_approx(GameEvents.life_steal_percent, life_steal_before + 0.05))
	assert(is_equal_approx(GameEvents.expedition_health_multiplier, 0.8))
	await select_upgrades()
	var player_health: HealthComponent = main.get_node("Entities/Player/HealthComponent")
	var health_before := player_health.current_health
	get_tree().paused = true
	expedition.show_contracts()
	press_number(6)
	assert(is_equal_approx(player_health.current_health, health_before * 0.6))
	assert(is_equal_approx(GameEvents.expedition_damage_multiplier, 1.4))
	await select_upgrades()
	main.get_node("ArenaTimeManager").time_elapsed = expedition.WAVE_DURATION
	expedition._process(0.0)
	assert(expedition.stage == expedition.Stage.BOSS)
	player_health.current_health = 0.0
	expedition.on_boss_died()
	assert(expedition.defeated_bosses == 0 and expedition.stage == expedition.Stage.BOSS)
	player_health.check_death()
	assert(expedition.stage == expedition.Stage.FINISHED)
	await get_tree().create_timer(2.0, true, false, true).timeout
	var report: EndScreen
	for child: Node in main.get_children():
		if child is EndScreen:
			report = child
	assert(report != null and report.get_node("%TitleLabel").text == "失败")
	assert(report.get_node("%DefeatReasonLabel").text.contains("击败 0 / 5"))
	assert(get_tree().paused)
	get_tree().paused = false
	print("EXPEDITION_DEFEAT_OK")
	get_tree().quit()
