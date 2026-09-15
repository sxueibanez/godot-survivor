extends Node


func _ready() -> void:
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	(main.get_node("CheatUI/SpawnRandomEnemiesButton") as Button).pressed.emit()
	assert(get_tree().get_nodes_in_group("enemy").size() == enemy_count + 20)
	var boss_count := get_tree().get_nodes_in_group("boss").size()
	(main.get_node("CheatUI/SpawnIronArmMinerButton") as Button).pressed.emit()
	assert(get_tree().get_nodes_in_group("boss").size() == boss_count + 1)
	var level_select := main.get_node("CheatUI/LevelSelect") as OptionButton
	level_select.item_selected.emit(1)
	assert(main.get("current_level") == 2)
	level_select.item_selected.emit(2)
	assert(main.get("current_level") == 3)
	var slime_count := get_tree().get_nodes_in_group("boss").filter(func(boss: Node): return boss.get_meta("display_name", "") == "史莱姆王").size()
	(main.get_node("CheatUI/SpawnBossButton") as Button).pressed.emit()
	assert(get_tree().get_nodes_in_group("boss").filter(func(boss: Node): return boss.get_meta("display_name", "") == "史莱姆王").size() == slime_count + 1)
	level_select.item_selected.emit(0)
	assert(main.get("current_level") == 1)
	get_tree().quit()
