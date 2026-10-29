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
	var foreground := Node2D.new()
	foreground.add_to_group("player_projectiles_layer")
	add_child(foreground)
	var first := make_enemy(Vector2.ZERO)
	var near := make_enemy(Vector2(50, 0))
	var far := make_enemy(Vector2(80, 0))
	var outside := make_enemy(Vector2(110, 0))
	var sword := preload("res://scenes/ability/sword_ability/sword_ability.tscn").instantiate() as SwordAbility
	sword.damage = 40.0
	sword.chain_enabled = true
	foreground.add_child(sword)
	assert(sword.find_chain_target(first) == near)
	near.get_node("HealthComponent").current_health = 0.0
	assert(sword.find_chain_target(first) == far)
	far.queue_free()
	assert(sword.find_chain_target(first) == first)
	first.get_node("HealthComponent").current_health = 0.0
	assert(sword.find_chain_target(first) == null)
	near.get_node("HealthComponent").current_health = 10.0
	var timer := Timer.new()
	add_child(timer)
	var cooldown := preload("res://scenes/ability/attack_cooldown.gd").new(timer)
	cooldown.track(sword)
	var random_seed := 1
	seed(random_seed)
	while randf() > SwordAbility.CHAIN_CHANCE:
		random_seed += 1
		seed(random_seed)
	seed(random_seed)
	sword.on_hitbox_area_entered(first.get_node("HurtboxComponent"))
	await get_tree().process_frame
	assert(foreground.get_child_count() == 2)
	var followup := foreground.get_child(1) as SwordAbility
	assert(followup.global_position.distance_to(near.global_position) <= 4.01)
	assert(followup.chain_depth == 1 and followup.chain_enabled)
	assert(is_equal_approx(followup.damage, 10.0) and cooldown.active_count == 2)
	followup.chain_depth = SwordAbility.MAX_CHAIN_DEPTH
	followup.on_hitbox_area_entered(near.get_node("HurtboxComponent"))
	await get_tree().process_frame
	assert(foreground.get_child_count() == 2)
	assert(is_instance_valid(outside))
	print("SWORD_CHAIN_RETARGET_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
