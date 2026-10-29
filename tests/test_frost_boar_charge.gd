extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(60, 0)
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	var projectiles := Node2D.new()
	projectiles.add_to_group("enemy_projectiles_layer")
	add_child(projectiles)

	var boar := preload("res://scenes/game_object/frost_boar/frost_boar.tscn").instantiate()
	add_child(boar)
	boar.get_node("VialDropComponent").disabled = true
	boar.set_process(false)
	boar.start_charge(player)
	assert(boar.warning_time == boar.WARNING_DURATION)
	assert(projectiles.get_child_count() == 1)
	boar._process(0.2)
	assert(not boar.charging and boar.warning_time > 0.0)
	boar.health_component.damage(boar.health_component.max_health + 1.0)
	boar._process(1.0)
	assert(not boar.charging)
	await get_tree().process_frame
	assert(projectiles.get_child_count() == 0)

	var second := preload("res://scenes/game_object/frost_boar/frost_boar.tscn").instantiate()
	add_child(second)
	second.set_process(false)
	second.start_charge(player)
	second.hit_player_along_path(Vector2.ZERO, Vector2(120, 0))
	assert(is_equal_approx(health.current_health, 58.0))
	second.hit_player_along_path(Vector2.ZERO, Vector2(120, 0))
	assert(is_equal_approx(health.current_health, 58.0))
	second.hit_player = false
	player.position = Vector2(60, 31)
	second.hit_player_along_path(Vector2.ZERO, Vector2(120, 0))
	assert(is_equal_approx(health.current_health, 58.0) and not second.hit_player)
	print("FROST_BOAR_CHARGE_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
