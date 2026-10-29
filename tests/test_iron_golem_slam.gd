extends Node2D

const GOLEM = preload("res://scenes/game_object/iron_golem/iron_golem.gd")

func _ready() -> void:
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 200.0
	player.add_child(health)
	var layer := Node2D.new()
	layer.add_to_group("enemy_projectiles_layer")
	add_child(layer)
	var entities := Node2D.new()
	entities.add_to_group("entities_layer")
	add_child(entities)
	var golem := preload("res://scenes/game_object/iron_golem/iron_golem.tscn").instantiate()
	entities.add_child(golem)
	golem.set_process(false)
	golem.get_node("VialDropComponent").disabled = true
	golem.start_attack()
	assert(golem.attacking and is_instance_valid(golem.ground_warning))
	golem._process(golem.WINDUP_DURATION * 0.5)
	assert(health.current_health == 200.0)
	golem._process(golem.WINDUP_DURATION * 0.5)
	assert(not golem.attacking and health.current_health == 162.0)
	assert(golem.ground_warning.is_queued_for_deletion())
	var impact := layer.get_child(layer.get_child_count() - 1)
	assert(impact is GOLEM.GroundImpact and impact.global_position == golem.attack_center)
	golem.slam()
	assert(health.current_health == 162.0)
	player.position = Vector2(100, 0)
	golem.start_attack()
	golem._process(golem.WINDUP_DURATION)
	assert(health.current_health == 162.0)
	player.position = Vector2.ZERO
	golem.start_attack()
	var warning: Node = golem.ground_warning
	golem.health_component.damage(golem.health_component.max_health + 1.0)
	assert(not golem.attacking and warning.is_queued_for_deletion())
	golem._process(golem.WINDUP_DURATION)
	assert(health.current_health == 162.0)
	impact._process(0.3)
	assert(impact.is_queued_for_deletion())
	await get_tree().process_frame
	print("IRON_GOLEM_SLAM_OK")
	get_tree().quit()
