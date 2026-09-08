extends SceneTree


func _init() -> void:
	var laser := load("res://scenes/ability/laser_gun_ability/laser_gun_ability.tscn").instantiate() as LaserGunAbility
	laser.beam_width = 16.0
	root.add_child(laser)
	assert(is_equal_approx(laser.beam.width, 16.0))
	assert(is_equal_approx((laser.collision_shape.shape as RectangleShape2D).size.y, 16.0))
	assert(laser.bounce_beams.size() == 3)
	for bounce_beam: Line2D in laser.bounce_beams:
		assert(is_equal_approx(bounce_beam.width, 4.0))
	assert(is_equal_approx(laser.get_primary_beam_length(), LaserGunAbility.BEAM_LENGTH))
	laser.reflection_enabled = true
	assert(is_equal_approx(laser.get_primary_beam_length(), LaserGunAbility.BEAM_LENGTH * 1.5))
	laser.reflection_enabled = false
	assert(is_equal_approx(laser.get_node("Sprite2D").scale.x, 0.75))
	var enemies: Array = []
	for position: Vector2 in [Vector2(100, 20), Vector2(110, 20), Vector2(250, 0)]:
		var enemy := Node2D.new()
		enemy.global_position = position
		root.add_child(enemy)
		enemy.add_to_group("enemy")
		enemies.append(enemy)
	assert(laser.find_densest_enemy(enemies).global_position == Vector2(100, 20))
	var source := Node2D.new()
	root.add_child(source)
	laser.source = source
	laser.auto_aim_enabled = true
	laser.update_auto_aim(0.1)
	assert(laser.direction.is_equal_approx(Vector2(100, 20).normalized()))
	var victim := Node2D.new()
	root.add_child(victim)
	var health := HealthComponent.new()
	health.max_health = 1.0
	victim.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.health_component = health
	victim.add_child(hurtbox)
	laser.kill_duration_extension_enabled = true
	laser.damage_per_second = 10.0
	laser.time_left = LaserGunAbility.DURATION
	laser.apply_damage(hurtbox, 1.0)
	assert(is_equal_approx(laser.time_left, LaserGunAbility.DURATION + LaserGunAbility.KILL_DURATION_EXTENSION))
	var boss := Node2D.new()
	boss.add_to_group("boss")
	root.add_child(boss)
	var boss_health := HealthComponent.new()
	boss_health.max_health = 1.0
	boss.add_child(boss_health)
	var boss_hurtbox := HurtboxComponent.new()
	boss_hurtbox.health_component = boss_health
	boss.add_child(boss_hurtbox)
	laser.time_left = LaserGunAbility.DURATION
	laser.apply_damage(boss_hurtbox, 1.0)
	assert(is_equal_approx(laser.time_left, LaserGunAbility.DURATION))
	quit()
