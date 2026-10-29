extends Node2D

const IceMap = preload("res://scenes/environment/level_4_ice.gd")


func _ready() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var movement := VelocityComponent.new()
	movement.name = "VelocityComponent"
	player.add_child(movement)
	movement.set_process(false)
	var ice := IceMap.new()
	add_child(ice)
	ice.set_process(false)

	var warning := IceMap.WindWarning.new(Vector2.RIGHT)
	ice.add_child(warning)
	warning.set_process(false)
	player.global_position = Vector2(200, 150)
	warning._process(0.5)
	assert(warning.global_position == player.global_position)
	assert(warning.z_index == -19 and not warning.z_as_relative)
	assert(movement.knockback_time_left == 0.0)
	warning._process(0.5)
	assert(movement.knockback_velocity == Vector2(135, 0))
	assert(is_equal_approx(movement.knockback_time_left, 0.42))
	await get_tree().process_frame
	assert(not is_instance_valid(warning))

	movement.knockback_time_left = 0.0
	var interrupted := IceMap.WindWarning.new(Vector2.LEFT)
	ice.add_child(interrupted)
	interrupted.set_process(false)
	var patch := IceMap.IcePatch.new()
	ice.add_child(patch)
	patch.set_process(false)
	patch.global_position = player.global_position
	ice.patch_time = 1.0
	ice.wind_time = 1.0
	ice.hide()
	interrupted._process(2.0)
	patch._process(0.1)
	assert(movement.knockback_time_left == 0.0 and movement.slippery_time_left == 0.0)
	assert(is_equal_approx(ice.patch_time, 0.4) and ice.wind_time == 4.0)
	await get_tree().process_frame
	assert(not is_instance_valid(interrupted) and not is_instance_valid(patch))
	print("ICE_WIND_WARNING_OK")
	get_tree().quit()
