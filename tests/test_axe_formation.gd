extends Node2D


func _ready() -> void:
	GameEvents.reset_run_stats()
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(100, 50)
	add_child(player)
	var projectiles := Node2D.new()
	projectiles.add_to_group("player_projectiles_layer")
	add_child(projectiles)
	var controller := preload("res://scenes/ability/axe_ability_controller/axe_ability_controller.tscn").instantiate()
	add_child(controller)
	controller.get_node("Timer").stop()
	controller.attack_count = 2
	controller.additional_axe_count = 2
	controller.return_to_player = true
	controller.reflect_projectiles = true
	controller.knockback_enabled = true
	controller.distance_scaling_enabled = true
	controller.size_multiplier = 1.25
	controller.on_timer_timeout()
	assert(projectiles.get_child_count() == 4)
	var first := projectiles.get_child(0) as AxeAbility
	for index in 4:
		var axe := projectiles.get_child(index) as AxeAbility
		assert(axe.base_rotation.is_equal_approx(first.base_rotation.rotated(TAU * index / 4.0)))
		assert(axe.return_to_player and axe.reflect_projectiles and axe.knockback_enabled and axe.distance_scaling_enabled)
		assert(is_equal_approx(axe.base_scale.x, 1.25))
		axe.move_outward(0.25)
		assert(is_equal_approx(axe.global_position.distance_to(player.global_position), 25.0))
	controller.on_timer_timeout()
	assert(projectiles.get_child_count() == 4)
	for axe in projectiles.get_children():
		axe.queue_free()
	await get_tree().process_frame
	controller.attack_count = 1
	controller.additional_axe_count = 0
	controller.on_timer_timeout()
	assert(projectiles.get_child_count() == 1)
	assert(is_equal_approx((projectiles.get_child(0) as AxeAbility).base_rotation.length(), 1.0))
	print("AXE_FORMATION_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
