extends SceneTree


func _init() -> void:
	assert(load("res://scenes/environment/level_3_mine.gd") is Script)
	assert(load("res://assets/environment/tilemap_packed.png") is Texture2D)
	quit()
