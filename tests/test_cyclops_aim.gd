extends Node


func _ready() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(100, 0)
	add_child(player)
	var layer := Node2D.new()
	layer.add_to_group("enemy_projectiles_layer")
	add_child(layer)
	var bat := preload("res://scenes/game_object/cyclops_bat/cyclops_bat.tscn").instantiate()
	add_child(bat)
	bat.set_process(false)
	bat.cooldown = 0.0
	bat._process(0.01)
	assert(bat.aim_time > 0.0 and layer.get_child_count() == 0)
	player.position = Vector2(0, 100)
	bat._process(0.2)
	assert(bat.aim_direction.y > 0.99)
	bat._process(0.25)
	var locked_direction: Vector2 = bat.aim_direction
	player.position = Vector2(-100, 0)
	bat._process(0.14)
	assert(layer.get_child_count() == 0 and bat.aim_direction == locked_direction)
	bat._process(0.02)
	assert(layer.get_child_count() == 1)
	assert(layer.get_child(0).direction == locked_direction)
	assert(is_equal_approx(bat.cooldown, bat.FIRE_INTERVAL))
	var laser := layer.get_child(0)
	laser.reflect_to_enemy()
	assert(laser.reflected and laser.modulate == Color(0.5, 1.0, 0.8))
	bat.cooldown = 0.0
	bat._process(0.01)
	assert(bat.aim_time > 0.0)
	player.remove_from_group("player")
	bat._process(0.1)
	assert(bat.aim_time == 0.0 and layer.get_child_count() == 1)
	player.add_to_group("player")
	bat._process(0.01)
	assert(bat.aim_time > 0.0)
	bat.health_component.damage(9999.0)
	bat._process(1.0)
	assert(layer.get_child_count() == 1)
	print("CYCLOPS_AIM_TEST_PASSED")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
