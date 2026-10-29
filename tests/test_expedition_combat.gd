extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "expedition"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	var expedition: Node = main.get_node("ExpeditionManager")
	expedition.maps.assign([1, 2, 3, 4, 5])
	expedition.patterns.assign(["rush", "ranged", "swift", "rush", "ranged"])
	var upgrades: Node = main.get_node("UpgradeManager")
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	var health: HealthComponent = main.get_node("Entities/Player/HealthComponent")
	health.set_invulnerable(100.0)
	var start_ms := Time.get_ticks_msec()
	var saw_enemy := false
	var max_count := 0
	Engine.time_scale = 6.0
	while Time.get_ticks_msec() - start_ms < 18000 and expedition.stage != expedition.Stage.BOSS:
		if upgrades.choice_screen_open:
			var screen: Node = upgrades.get_child(upgrades.get_child_count() - 1)
			if not screen.closing and screen.card_container.get_child_count() > 0:
				screen.card_container.get_child(0).selected.emit()
		if expedition.stage == expedition.Stage.WAVE:
			var count := GameEvents.get_enemy_count()
			max_count = maxi(max_count, count)
			saw_enemy = saw_enemy or count > 0
		await get_tree().process_frame
	Engine.time_scale = 1.0
	assert(saw_enemy and max_count <= GameEvents.MAX_ENEMIES)
	assert(expedition.stage == expedition.Stage.BOSS and is_instance_valid(expedition.active_boss))
	assert(main.get_node("ArenaTimeManager").time_elapsed >= expedition.WAVE_DURATION)
	assert(not main.get_node("EnemyManager").spawning)
	get_tree().paused = false
	print("EXPEDITION_COMBAT_OK max_enemies=%d" % max_count)
	get_tree().quit()
