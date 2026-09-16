extends SceneTree


func _init() -> void:
	call_deferred("run")


func run() -> void:
	GameEvents.game_mode = "campaign"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.set("map_order", [4, 3, 2, 1])
	main.call("begin_level_1")
	assert(main.get_node("IceMap").visible)
	main.call("begin_level_2")
	assert(main.get_node("MineMap").visible)
	assert(not main.get_node("IceMap").visible)
	assert(main.get("previous_map_id") == 4)
	main.get_node("ArenaTimeManager").set("time_elapsed", 5.0 * 60.0)
	main.call("_process", 0.0)
	assert(get_tree().get_nodes_in_group("boss").any(func(boss: Node): return boss.get_meta("display_name", "") == "铁臂矿工"))
	main.call("begin_level_4")
	main.get_node("ArenaTimeManager").set("time_elapsed", 5.0 * 60.0)
	main.call("_process", 0.0)
	assert(main.get("waiting_for_entrance"))
	main.call("begin_level", 5)
	assert(main.get("current_level") == 5)
	assert(main.get("current_map_id") in [1, 2, 3, 4])
	quit()
