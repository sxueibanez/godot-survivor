extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(60, 0)
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 200.0
	player.add_child(health)
	health.owner = player
	var velocity := VelocityComponent.new()
	velocity.name = "VelocityComponent"
	player.add_child(velocity)
	var projectiles := Node2D.new()
	projectiles.add_to_group("enemy_projectiles_layer")
	add_child(projectiles)
	var entities := Node2D.new()
	entities.add_to_group("entities_layer")
	add_child(entities)
	var slime := preload("res://scenes/game_object/stone_slime/stone_slime.tscn").instantiate()
	entities.add_child(slime)
	slime.set_process(false)
	slime.get_node("VialDropComponent").disabled = true
	slime.start_aim(player)
	assert(slime.aiming and is_instance_valid(slime.warning))
	slime.warning.set_process(false)
	slime.warning._process(0.25)
	assert(is_equal_approx(slime.warning.elapsed, 0.25))
	slime._process(slime.WARNING_DURATION)
	assert(slime.charging and health.current_health == 200.0)
	slime.global_position = Vector2(120, 0)
	assert(slime.hit_player(Vector2.ZERO))
	assert(health.current_health == 168.0)
	assert(velocity.knockback_time_left > 0.0)
	assert(GameEvents.last_damage_source == "石史莱姆冲锋")
	player.position = Vector2(60, 31)
	assert(not slime.hit_player(Vector2.ZERO))
	assert(health.current_health == 168.0)
	slime.finish_charge()
	player.position = Vector2(60, 0)
	slime.start_aim(player)
	var warning: Node = slime.warning
	slime.health_component.damage(slime.health_component.max_health + 1.0)
	assert(not slime.aiming and not slime.charging and warning.is_queued_for_deletion())
	slime._process(2.0)
	assert(not slime.charging and health.current_health == 168.0)
	var despawned := preload("res://scenes/game_object/stone_slime/stone_slime.tscn").instantiate()
	entities.add_child(despawned)
	despawned.set_process(false)
	despawned.start_aim(player)
	var despawn_warning: Node = despawned.warning
	despawned.queue_free()
	await get_tree().process_frame
	assert(not is_instance_valid(despawn_warning) or despawn_warning.is_queued_for_deletion())
	print("STONE_SLIME_CHARGE_FEEDBACK_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
