extends Node2D


func make_enemy(point: Vector2) -> Node2D:
	var enemy := Node2D.new()
	enemy.position = point
	enemy.add_to_group("enemy")
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	enemy.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.health_component = health
	enemy.add_child(hurtbox)
	add_child(enemy)
	return enemy


func _ready() -> void:
	GameEvents.game_mode = "endless"
	GameEvents.critical_disabled = true
	var texts := Node2D.new()
	texts.add_to_group("floating_text_layer")
	add_child(texts)
	var rain := preload("res://scenes/ability/sword_rain_ability/sword_rain_ability.tscn").instantiate() as SwordRainAbility
	rain.damage = 4.0
	add_child(rain)
	rain.set_process(false)
	var near := make_enemy(Vector2(45, 0))
	var far := make_enemy(Vector2(47, 0))
	var near_health := near.get_node("HealthComponent") as HealthComponent
	var far_health := far.get_node("HealthComponent") as HealthComponent
	assert(rain.range_ring.top_level and rain.range_ring.closed)
	assert(is_equal_approx(rain.range_ring.get_point_position(0).length(), 46.0))
	rain.deal_damage()
	assert(is_equal_approx(near_health.current_health, near_health.max_health - 4.0))
	assert(is_equal_approx(far_health.current_health, far_health.max_health))
	near.remove_from_group("enemy")
	far.remove_from_group("enemy")
	var giant := preload("res://scenes/ability/sword_rain_ability/sword_rain_ability.tscn").instantiate() as SwordRainAbility
	giant.radius_multiplier = 2.0
	giant.scale = Vector2.ONE * 2.0
	add_child(giant)
	giant.set_process(false)
	giant.global_position = Vector2(10, 0)
	giant._process(0.0)
	assert(giant.range_ring.global_position == giant.global_position)
	assert(is_equal_approx(giant.range_ring.global_scale.x, 1.0))
	assert(is_equal_approx(giant.range_ring.get_point_position(0).length(), 92.0))
	var giant_near := make_enemy(Vector2(101, 0))
	var giant_far := make_enemy(Vector2(103, 0))
	var giant_near_health := giant_near.get_node("HealthComponent") as HealthComponent
	var giant_far_health := giant_far.get_node("HealthComponent") as HealthComponent
	giant.deal_damage()
	assert(is_equal_approx(giant_near_health.current_health, giant_near_health.max_health - 4.0))
	assert(is_equal_approx(giant_far_health.current_health, giant_far_health.max_health))
	var ring := giant.range_ring
	giant.queue_free()
	await get_tree().process_frame
	assert(not is_instance_valid(ring))
	print("SWORD_RAIN_RANGE_OK")
	get_tree().quit()
