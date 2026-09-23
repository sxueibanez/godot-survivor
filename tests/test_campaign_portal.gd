extends Node


func _ready() -> void:
	GameEvents.game_mode = "campaign"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.call("begin_level_4")
	main.call("spawn_level_entrance")
	var entities := main.get_node("Entities")
	var entrance := entities.get_child(entities.get_child_count() - 1) as Node2D
	assert(main.get("completed_maps") == 1)
	assert((entrance.get_child(0) as Label).text == "第2关入口")
	main.call("spawn_level_entrance")
	assert(main.get("completed_maps") == 1)
	(main.get_node("Entities/Player") as Node2D).global_position = entrance.global_position
	await get_tree().process_frame
	await get_tree().process_frame
	assert(main.get("current_level") == 2)
	main.call("spawn_level_entrance")
	entrance = entities.get_child(entities.get_child_count() - 1) as Node2D
	assert(main.get("completed_maps") == 2)
	assert((entrance.get_child(0) as Label).text == "第3关入口")
	(main.get_node("Entities/Player") as Node2D).global_position = entrance.global_position
	await get_tree().process_frame
	await get_tree().process_frame
	assert(main.get("current_level") == 3)
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
