extends Node


func _ready() -> void:
	GameEvents.critical_disabled = true
	GameEvents.game_mode = "normal"
	var texts := Node2D.new()
	texts.add_to_group("floating_text_layer")
	add_child(texts)
	var health_by_position: Dictionary = {}
	# Add the furthest enemy first to ensure scene order differs from bullet order.
	for x in [80, 60, 40, 20]:
		var enemy := Node2D.new()
		enemy.position = Vector2(x, 0)
		enemy.add_to_group("enemy")
		add_child(enemy)
		var health := HealthComponent.new()
		health.max_health = 1000.0
		enemy.add_child(health)
		var hurtbox := HurtboxComponent.new()
		hurtbox.name = "HurtboxComponent"
		hurtbox.health_component = health
		enemy.add_child(hurtbox)
		health_by_position[x] = health

	var bullet := load("res://scenes/ability/sniper_rifle_bullet/sniper_rifle_bullet.tscn").instantiate() as SniperRifleBullet
	bullet.configure(Vector2.ZERO, Vector2.RIGHT, 80.0, 1.0, false)
	add_child(bullet)
	bullet.set_process(false)
	var initial_health: float = health_by_position[20].current_health
	bullet.damage_crossed_enemies(Vector2.ZERO, Vector2(100, 0))
	assert(is_equal_approx(health_by_position[20].current_health, initial_health - 80.0))
	assert(is_equal_approx(health_by_position[40].current_health, initial_health - 40.0))
	assert(is_equal_approx(health_by_position[60].current_health, initial_health - 20.0))
	assert(is_equal_approx(health_by_position[80].current_health, initial_health))
	assert(bullet.global_position.is_equal_approx(Vector2(60, 0)))

	var wall := StaticBody2D.new()
	wall.position = Vector2(100, 0)
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2, 40)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	add_child(wall)
	var ricochet_bullet := load("res://scenes/ability/sniper_rifle_bullet/sniper_rifle_bullet.tscn").instantiate() as SniperRifleBullet
	ricochet_bullet.configure(Vector2.ZERO, Vector2.RIGHT, 10.0, 1.0, false, false, true)
	ricochet_bullet.max_hits = 1
	add_child(ricochet_bullet)
	ricochet_bullet.set_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ray := PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2(130, 0), 1)
	assert(not get_viewport().world_2d.direct_space_state.intersect_ray(ray).is_empty())
	ricochet_bullet._process(0.2)
	assert(ricochet_bullet.finished)
	assert(ricochet_bullet.global_position.is_equal_approx(Vector2(20, 0)))
	assert(ricochet_bullet.direction == Vector2.RIGHT)
	print("Sniper penetration order, falloff, and stopping before wall passed.")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
