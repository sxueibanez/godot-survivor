extends Node

func _ready() -> void:
	GameEvents.game_mode = "normal"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.begin_level_5()
	var boss: Node2D = main.spawn_boss_for_map(5)
	assert(boss != null)
	print("FORGE_COMPILE_OK")
	get_tree().quit()
