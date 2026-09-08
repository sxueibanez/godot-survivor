extends SceneTree


func _init() -> void:
	var laser := load("res://scenes/ability/laser_gun_ability/laser_gun_ability.tscn").instantiate() as LaserGunAbility
	laser.beam_width = 16.0
	root.add_child(laser)
	assert(is_equal_approx(laser.beam.width, 16.0))
	assert(is_equal_approx((laser.collision_shape.shape as RectangleShape2D).size.y, 16.0))
	assert(is_equal_approx(laser.get_node("Sprite2D").scale.x, 0.75))
	quit()
