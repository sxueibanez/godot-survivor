extends Node2D


func _ready() -> void:
	GameEvents.reset_run_stats()
	GameEvents.game_mode = "endless"
	GameEvents.critical_disabled = true
	GameEvents.life_steal_percent = 0.01
	var floating := Node2D.new()
	floating.add_to_group("floating_text_layer")
	add_child(floating)
	var effects := Node2D.new()
	effects.add_to_group("combat_effects_layer")
	add_child(effects)
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	var player_health: HealthComponent = player.health_component
	player_health.current_health = player_health.max_health - 30.0
	player_health.health_changed.emit()
	var target := Node2D.new()
	target.add_to_group("enemy")
	target.position = Vector2(120.0, 0.0)
	add_child(target)
	var target_health := HealthComponent.new()
	target_health.max_health = 1000.0
	target.add_child(target_health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.health_component = target_health
	hurtbox.collision_layer = 32
	hurtbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	hurtbox.add_child(shape)
	target.add_child(hurtbox)
	var laser := preload("res://scenes/ability/laser_gun_ability/laser_gun_ability.tscn").instantiate() as LaserGunAbility
	laser.source = player
	laser.damage_per_second = 8.0
	effects.add_child(laser)
	var player_initial := player_health.current_health
	var target_initial := target_health.current_health
	var healing_frames := 0
	var previous := player_initial
	for frame in 45:
		await get_tree().physics_frame
		player.update_heal_text(1.0 / 60.0)
		if player_health.current_health > previous:
			healing_frames += 1
		previous = player_health.current_health
	var damage_done := target_initial - target_health.current_health
	var healing_done := player_health.current_health - player_initial
	assert(healing_frames > 5 and damage_done > 0.0)
	assert(is_equal_approx(healing_done, damage_done * 0.01))
	assert(is_equal_approx(player.health_bar.value, player_health.get_health_percent()), "health bar did not preserve fractional healing")
	var healing_labels: Array[String] = []
	for text: Node in floating.get_children():
		var label := text.get_node("Label") as Label
		if label.get_theme_color("font_color") == Color(0.4, 1.0, 0.55):
			healing_labels.append(label.text)
	assert(healing_labels.size() >= 2 and healing_labels.size() <= 4, "heal labels: %s" % [healing_labels])
	for text: String in healing_labels:
		assert(text not in ["+0", "+0.0", "+0.00", "+0.000"])
	var before_reflection := player_health.current_health
	var target_before_reflection := target_health.current_health
	laser.apply_damage(hurtbox, 0.1, LaserGunAbility.REFLECTION_DAMAGE_MULTIPLIER)
	assert(is_equal_approx(player_health.current_health - before_reflection, (target_before_reflection - target_health.current_health) * 0.01))
	assert(player.pending_heal_text > 0.0)
	player_health.damage(1.0)
	assert(player.pending_heal_text == 0.0 and player.heal_text_time_left == 0.0)
	var before_no_lifesteal := player_health.current_health
	GameEvents.life_steal_percent = 0.0
	laser.apply_damage(hurtbox, 0.1)
	assert(player_health.current_health == before_no_lifesteal)
	player_health.heal(player_health.max_health)
	GameEvents.life_steal_percent = 0.5
	laser.apply_damage(hurtbox, 0.1)
	assert(player_health.current_health == player_health.max_health)
	print("LASER_LIFESTEAL_OK frames=%d damage=%.4f heal=%.4f" % [healing_frames, damage_done, healing_done])
	get_tree().quit()
