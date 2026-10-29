extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(100, 0)
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	var movement := VelocityComponent.new()
	movement.name = "VelocityComponent"
	player.add_child(movement)
	movement.set_process(false)
	var projectiles := Node2D.new()
	projectiles.add_to_group("enemy_projectiles_layer")
	add_child(projectiles)
	var wisp := preload("res://scenes/game_object/frost_wisp/frost_wisp.tscn").instantiate()
	add_child(wisp)
	wisp.set_process(false)
	wisp.cooldown = 0.0
	wisp._process(0.01)
	assert(wisp.aim_time > 0.0 and projectiles.get_child_count() == 0)
	var locked_direction: Vector2 = wisp.aim_direction
	player.position = Vector2(0, 100)
	wisp._process(0.49)
	assert(projectiles.get_child_count() == 0 and wisp.aim_direction == locked_direction)
	wisp._process(0.02)
	assert(projectiles.get_child_count() == 1 and wisp.cooldown == 2.1)
	var bolt := projectiles.get_child(0) as Node2D
	assert(bolt.direction == locked_direction)
	bolt.set_process(false)
	player.position = Vector2(100, 0)
	bolt._process(0.6)
	assert(is_equal_approx(health.current_health, 70.0))
	assert(is_equal_approx(movement.slow_multiplier, 0.65))
	await get_tree().process_frame
	assert(not is_instance_valid(bolt))
	wisp.cooldown = 0.0
	wisp._process(0.01)
	assert(wisp.aim_time > 0.0)
	player.remove_from_group("player")
	wisp._process(1.0)
	assert(wisp.aim_time == 0.0 and projectiles.get_child_count() == 0)
	player.add_to_group("player")
	wisp._process(0.01)
	wisp.health_component.current_health = 0.0
	wisp._process(1.0)
	assert(wisp.aim_time == 0.0 and projectiles.get_child_count() == 0)
	print("FROST_WISP_AIM_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
