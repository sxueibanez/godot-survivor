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
	quit()
