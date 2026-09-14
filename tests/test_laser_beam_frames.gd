extends SceneTree


func _initialize() -> void:
	var texture := load("res://assets/abilities/laser_beam_frames.png") as Texture2D
	assert(texture != null)
	assert(texture.get_width() % 2 == 0)
	assert(texture.get_height() % 4 == 0)
	quit()
