extends Node2D

const Mine = preload("res://scenes/environment/level_3_mine.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(30, 384)
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	var movement := VelocityComponent.new()
	movement.name = "VelocityComponent"
	player.add_child(movement)
	var mine := Mine.new()
	mine.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(mine)
	mine.set_process(false)
	var cart := Mine.Minecart.new(1.0)
	mine.add_child(cart)
	cart.set_process(false)
	cart.global_position = Vector2(-128, 384)
	cart._process(0.6)
	assert(cart.travelled == 0.0 and health.current_health == 100.0)
	cart._process(0.6)
	assert(cart.travelled == 0.0 and health.current_health == 100.0)
	cart._process(0.5)
	assert(cart.hit_player and is_equal_approx(health.current_health, 88.0))
	assert(movement.knockback_velocity == Vector2(240, 0))
	cart._process(0.3)
	assert(health.current_health == 88.0)

	player.position = Vector2(30, 407)
	var safe_cart := Mine.Minecart.new(1.0)
	mine.add_child(safe_cart)
	safe_cart.set_process(false)
	safe_cart.global_position = Vector2(-128, 384)
	safe_cart._process(2.2)
	assert(not safe_cart.hit_player and health.current_health == 88.0)

	player.position = Vector2(1000, 384)
	var reverse_cart := Mine.Minecart.new(-1.0)
	mine.add_child(reverse_cart)
	reverse_cart.set_process(false)
	reverse_cart.global_position = Vector2(1280, 384)
	reverse_cart._process(2.2)
	assert(reverse_cart.hit_player and health.current_health == 76.0)
	assert(movement.knockback_velocity == Vector2(-240, 0))

	mine.hide()
	assert(cart.is_queued_for_deletion() and safe_cart.is_queued_for_deletion() and reverse_cart.is_queued_for_deletion())
	assert(is_equal_approx(mine.cart_time, mine.CART_START_DELAY))
	await get_tree().process_frame
	mine.show()
	mine.cart_time = 0.01
	mine._process(0.01)
	assert(mine.get_child_count() == 1 and is_equal_approx(mine.cart_time, mine.CART_INTERVAL))
	var spawned := mine.get_child(0) as Node2D
	var start: Vector2 = spawned.global_position
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	assert(spawned.global_position == start and spawned.elapsed == 0.0)
	get_tree().paused = false
	print("MINECART_HAZARD_OK")
	get_tree().quit()
