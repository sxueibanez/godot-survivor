extends SceneTree


func _init() -> void:
	assert(load("res://assets/enemies/cyclops_bat_walk_frames.png") is Texture2D)
	assert(load("res://scenes/game_object/cyclops_bat/cyclops_bat.gd") is Script)
	assert(load("res://scenes/game_object/cyclops_laser/cyclops_laser.gd") is Script)
	var laser := load("res://scenes/game_object/cyclops_laser/cyclops_laser.tscn").instantiate() as Node2D
	root.add_child(laser)
	laser.set("direction", Vector2.RIGHT)
	laser.call("reflect_to_enemy")
	assert(bool(laser.get("reflected")) and laser.get("direction") == Vector2.LEFT)
	quit()
