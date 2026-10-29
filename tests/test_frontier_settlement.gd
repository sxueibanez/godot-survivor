extends Node


func start_run() -> Node:
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	mode.set_process(false)
	mode.player.set_process(false)
	return mode


func finish_run(mode: Node) -> void:
	get_tree().paused = false
	mode.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	MetaProgression.save_data["meta_upgrade_currency"] = 11
	MetaProgression.save()
	var mode := start_run()
	mode.gold = 9
	mode.on_player_died()
	assert(mode.finished and int(MetaProgression.save_data["meta_upgrade_currency"]) == 11)
	mode.end_game("重复调用")
	assert(int(MetaProgression.save_data["meta_upgrade_currency"]) == 11)
	await finish_run(mode)
	mode = start_run()
	mode.gold = 19
	mode.start_defense()
	mode.damage_tower(mode.tower_health)
	assert(mode.finished and int(MetaProgression.save_data["meta_upgrade_currency"]) == 12)
	var box: VBoxContainer = mode.screen.get_child(0).get_child(0).get_child(0)
	assert((box.get_child(2) as Label).text.contains("1 瓶"))
	mode.end_game("重复调用")
	assert(int(MetaProgression.save_data["meta_upgrade_currency"]) == 12)
	MetaProgression.load_save_file()
	assert(int(MetaProgression.save_data["meta_upgrade_currency"]) == 12)
	await finish_run(mode)
	mode = start_run()
	mode.gold = 10
	mode.on_player_died()
	assert(mode.finished and int(MetaProgression.save_data["meta_upgrade_currency"]) == 13)
	await finish_run(mode)
	mode = start_run()
	mode.gold = 128
	mode.show_pause()
	box = mode.screen.get_child(0).get_child(0).get_child(0)
	assert((box.get_child(2) as Button).text == "结束本局并结算")
	(box.get_child(2) as Button).pressed.emit()
	assert(mode.finished and int(MetaProgression.save_data["meta_upgrade_currency"]) == 25)
	mode.end_game("重复调用")
	MetaProgression.load_save_file()
	assert(int(MetaProgression.save_data["meta_upgrade_currency"]) == 25)
	box = mode.screen.get_child(0).get_child(0).get_child(0)
	assert((box.get_child(2) as Label).text.contains("12 瓶"))
	print("FRONTIER_SETTLEMENT_OK")
	await finish_run(mode)
	get_tree().quit()
