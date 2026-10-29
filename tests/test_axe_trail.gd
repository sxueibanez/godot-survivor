extends Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := Node2D.new()
	player.add_to_group("player")
	player.global_position = Vector2(100, 50)
	add_child(player)
	var axe := preload("res://scenes/ability/axe_ability/axe_ability.tscn").instantiate() as AxeAbility
	axe.process_mode = Node.PROCESS_MODE_PAUSABLE
	axe.base_damage = 10.0
	add_child(axe)
	axe.base_rotation = Vector2.RIGHT
	for index in 30:
		axe.move_along_arc(index * 4.0, 0.0)
	assert(axe.trail.top_level and axe.trail.global_position == Vector2.ZERO)
	assert(axe.trail.get_point_count() == axe.TRAIL_POINTS)
	assert(axe.trail.get_point_position(axe.trail.get_point_count() - 1).is_equal_approx(axe.global_position))
	assert(axe.hitbox_component.damage == 10.0)
	player.position += Vector2(40, 20)
	axe.move_along_arc(100.0, 0.0)
	assert(axe.trail.get_point_position(axe.trail.get_point_count() - 1).is_equal_approx(player.global_position + Vector2(100, 0)))
	player.position += Vector2(500, 0)
	axe.move_along_arc(100.0, 0.0)
	assert(axe.trail.get_point_count() == 1)
	get_tree().paused = true
	var last := axe.global_position
	await get_tree().create_timer(0.1, true).timeout
	assert(axe.global_position == last)
	get_tree().paused = false
	await get_tree().create_timer(0.15).timeout
	assert(axe.global_position != last and axe.trail.get_point_count() > 1)
	var trail := axe.trail
	axe.queue_free()
	await get_tree().process_frame
	assert(not is_instance_valid(trail))
	print("AXE_TRAIL_OK")
	get_tree().quit()
