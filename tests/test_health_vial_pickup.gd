extends Node


func _ready() -> void:
	GameEvents.curse_no_normal_healing = false
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	var pickup_area := Area2D.new()
	pickup_area.collision_layer = 16
	pickup_area.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	pickup_area.add_child(shape)
	player.add_child(pickup_area)
	var vial := preload("res://scenes/game_object/health_vial/health_vial.tscn").instantiate()
	add_child(vial)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(is_instance_valid(vial) and not vial.collecting)
	GameEvents.curse_no_normal_healing = true
	health.damage(20.0)
	await get_tree().process_frame
	assert(is_instance_valid(vial) and health.current_health == 80.0, "vial=%s health=%s" % [is_instance_valid(vial), health.current_health])
	GameEvents.curse_no_normal_healing = false
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not is_instance_valid(vial) and is_equal_approx(health.current_health, 92.0))
	var emergency_vial := preload("res://scenes/game_object/health_vial/health_vial.tscn").instantiate()
	add_child(emergency_vial)
	health.current_health = 10.0
	emergency_vial.nearby_area = pickup_area
	emergency_vial.try_collect()
	assert(is_equal_approx(health.current_health, 29.0))
	var deadly_vial := preload("res://scenes/game_object/health_vial/health_vial.tscn").instantiate()
	add_child(deadly_vial)
	health.current_health = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(is_instance_valid(deadly_vial) and health.current_health == 0.0)
	print("HEALTH_VIAL_PICKUP_OK")
	get_tree().quit()
