extends Node

func _ready() -> void:
	GameEvents.game_mode = "boss_rush"
	var player := Node2D.new()
	player.add_to_group("player")
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 1000.0
	player.add_child(health)
	add_child(player)
	var storm := preload("res://scenes/game_object/frost_queen/frost_queen.gd").Blizzard.new()
	add_child(storm)
	storm.set_process(false)
	player.position = Vector2(200, 0)
	storm._process(0.79)
	assert(health.current_health == 1000.0 and storm.get_safe_radius() == 145.0)
	storm._process(0.02)
	assert(health.current_health == 982.0 and storm.hint.visible)
	player.position = Vector2.ZERO
	storm._process(0.5)
	assert(health.current_health == 982.0 and not storm.hint.visible)
	storm.elapsed = 1.8
	assert(is_equal_approx(storm.get_safe_radius(), 145.0))
	storm.elapsed = 3.3
	assert(is_equal_approx(storm.get_safe_radius(), 100.0))
	get_tree().paused = true
	storm._process(1.0)
	assert(storm.elapsed == 3.3)
	get_tree().paused = false
	# Give the renderer a frame to execute the outside-ring polygon drawing.
	await get_tree().process_frame
	storm.elapsed = 4.8
	assert(is_equal_approx(storm.get_safe_radius(), 55.0))
	storm._process(0.01)
	assert(storm.is_queued_for_deletion())
	print("BLIZZARD_CHECK_PASSED: warning, safe zone, hold/shrink, pause, expiry")
	get_tree().quit()
