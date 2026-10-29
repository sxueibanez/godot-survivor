extends Node2D


func _ready() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(380, 380)
	add_child(player)
	var camera := preload("res://scenes/game_object/game_camera/game_camera.tscn").instantiate()
	add_child(camera)
	camera.set_process(false)
	camera._process(0.016)
	assert(camera.global_position == player.global_position)
	player.position.x += 10.0
	camera._process(0.016)
	assert(camera.position.x > 380.0 and camera.position.x < 390.0)
	player.position = Vector2(900, 600)
	camera._process(0.016)
	assert(camera.global_position == player.global_position)
	player.remove_from_group("player")
	camera._process(0.016)
	player.position = Vector2(920, 600)
	player.add_to_group("player")
	camera._process(0.016)
	assert(camera.global_position == player.global_position)
	print("CAMERA_FOLLOW_OK")
	get_tree().quit()
