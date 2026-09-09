extends SceneTree


func _init() -> void:
	assert(load("res://assets/enemies/cyclops_bat_walk_frames.png") is Texture2D)
	assert(load("res://scenes/game_object/cyclops_bat/cyclops_bat.gd") is Script)
	assert(load("res://scenes/game_object/cyclops_laser/cyclops_laser.gd") is Script)
	quit()
