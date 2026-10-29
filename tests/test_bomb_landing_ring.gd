extends Node2D


func _ready() -> void:
	var scene := preload("res://scenes/ability/bomb_ability/bomb_ability.tscn")
	var bomb := scene.instantiate() as BombAbility
	bomb.configure(Vector2(10, 20), Vector2(80, 60), 15.0, 30.0, 0, false, false)
	bomb.is_giant = true
	add_child(bomb)
	bomb.set_process(false)
	var ring := bomb.get_node("LandingRing") as Line2D
	assert(ring != null and ring.closed and ring.points.size() == 32)
	assert(not ring.z_as_relative and ring.z_index == -1)
	assert(ring.global_position.is_equal_approx(Vector2(80, 60)))
	assert(is_equal_approx(ring.points[0].length(), bomb.get_explosion_radius()))
	bomb._process(bomb.FLIGHT_DURATION * 0.5)
	assert(ring.global_position.is_equal_approx(Vector2(80, 60)))
	assert(ring.visible and ring.modulate.a > 0.25)
	bomb._process(bomb.FLIGHT_DURATION * 0.5)
	assert(bomb.exploding and not ring.visible)
	var mini := scene.instantiate() as BombAbility
	mini.configure(Vector2.ZERO, Vector2(50, 50), 5.0, 9.0, 0, false, false, true)
	add_child(mini)
	assert(is_equal_approx(mini.landing_ring.points[0].length(), 9.0))
	assert(mini.landing_ring.width < ring.width)
	print("BOMB_LANDING_RING_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
