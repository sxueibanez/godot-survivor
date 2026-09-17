extends Node


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var root = self
	var events = get_node("/root/GameEvents")
	events.player_damage_multiplier = 1.0
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	root.add_child(foreground)
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)
	var enemy := Node2D.new()
	enemy.position = Vector2(40, 0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	var health := HealthComponent.new()
	health.max_health = 10000.0
	enemy.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.health_component = health
	enemy.add_child(hurtbox)
	var velocity := VelocityComponent.new()
	velocity.name = "VelocityComponent"
	enemy.add_child(velocity)
	var burn = load("res://scenes/ability/bomb_burn/bomb_burn.tscn").instantiate()
	# Use the bird's burn name: heat reaction must recognize all burning sources.
	burn.name = "AzureDragonBurn"
	burn.damage = 6.0
	enemy.add_child(burn)
	burn.ticks_left = 3
	var bomb = load("res://scenes/ability/bomb_ability/bomb_ability.tscn").instantiate()
	bomb.configure(Vector2.ZERO, Vector2.ZERO, 0.0, 30.0, 0, false, false)
	bomb.heat_reaction_enabled = true
	bomb.is_giant = true
	foreground.add_child(bomb)
	assert(is_equal_approx(bomb.get_explosion_radius(), 45.0))
	var before := health.current_health
	bomb.damage_enemies()
	assert(is_equal_approx(before - health.current_health, 9.0))
	assert(burn.ticks_left == 5 and burn.get_node("Timer").time_left > 0.9)
	assert(velocity.knockback_time_left > 0.0 and velocity.knockback_velocity.x > 0.0)
	enemy.add_to_group("boss")
	velocity.knockback_time_left = 0.0
	bomb.damage_enemies()
	assert(is_zero_approx(velocity.knockback_time_left))
	enemy.remove_from_group("boss")
	bomb.cluster_enabled = true
	bomb.bounce_remaining = 1
	bomb.explode()
	for child in foreground.get_children():
		if child is BombAbility and child != bomb:
			assert(not child.is_giant and child.heat_reaction_enabled)
	for child in foreground.get_children():
		child.free()
	var controller = load("res://scenes/ability/bomb_ability_controller/bomb_ability_controller.tscn").instantiate()
	root.add_child(controller)
	controller.giant_charge_enabled = true
	controller.attack_count = 2
	for round_index in 8:
		controller.on_timer_timeout()
		assert(foreground.get_child_count() == 2)
		for main_bomb in foreground.get_children():
			assert(main_bomb.is_giant == (round_index % 4 == 3))
		for main_bomb in foreground.get_children():
			main_bomb.free()
	enemy.remove_from_group("enemy")
	controller.on_timer_timeout()
	assert(controller.throw_rounds == 0) # Empty attempts do not charge a round.
	for skill in ["heat_reaction", "giant_charge"]:
		var upgrade = load("res://resources/upgrades/bomb_%s.tres" % skill)
		assert(upgrade.max_quantity == 1 and upgrade.description.length() < 40)
		assert(AbilityUpgradeCard.get_upgrade_icon(upgrade) != null)
	var manager_script = load("res://scenes/manager/upgrade_manager.gd")
	assert(manager_script.can_instantiate())
	var tree_script = load("res://scenes/ui/weapon_skill_tree.gd")
	assert(tree_script.WEAPON_SKILLS.bomb.any(func(skill): return skill.id == "tree_bomb_heat_reaction"))
	assert(tree_script.WEAPON_SKILLS.bomb.any(func(skill): return skill.id == "tree_bomb_giant_charge"))
	controller.free()
	enemy.free()
	player.free()
	foreground.free()
	print("Bomb specials passed: remaining burn damage + refresh, giant rounds, first-blast radius, boss immunity, ordinary descendants, icons and tree.")
	get_tree().quit()
