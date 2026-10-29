extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "normal"
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var player_health := HealthComponent.new()
	player_health.name = "HealthComponent"
	player_health.max_health = 500.0
	player.add_child(player_health)
	player_health.owner = player

	var bomber := preload("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn").instantiate()
	add_child(bomber)
	bomber.set_process(false)
	bomber._process(0.0)
	assert(bomber.charging)
	bomber._process(0.75)
	assert(is_equal_approx(bomber.charge_time, 0.75))
	assert(not bomber.detonated)
	bomber.health_component.damage(1000.0)
	bomber._process(1.0)
	assert(not bomber.detonated)
	assert(is_equal_approx(player_health.current_health, 500.0))
	await get_tree().process_frame

	var second := preload("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn").instantiate()
	add_child(second)
	second.set_process(false)
	second._process(0.0)
	player.position = Vector2(100, 0)
	second._process(1.5)
	assert(second.detonated)
	assert(is_equal_approx(player_health.current_health, 500.0))
	await get_tree().process_frame

	player.position = Vector2.ZERO
	var third := preload("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn").instantiate()
	add_child(third)
	third.set_process(false)
	third._process(0.0)
	third._process(1.5)
	assert(third.detonated)
	assert(is_equal_approx(player_health.current_health, 350.0))
	third.detonate()
	assert(is_equal_approx(player_health.current_health, 350.0))
	print("EXPLODER_COUNTERPLAY_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
