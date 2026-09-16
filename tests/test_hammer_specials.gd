extends Node

func _ready() -> void:
	for skill in ["pull", "heavy"]:
		var upgrade := load("res://resources/upgrades/heaven_shaking_hammer_%s.tres" % skill) as AbilityUpgrade
		assert(upgrade != null and upgrade.max_quantity == 1)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var enemy := CharacterBody2D.new()
	enemy.position = Vector2(70, 0)
	enemy.add_to_group("enemy")
	add_child(enemy)
	var hammer := load("res://scenes/ability/heaven_shaking_hammer/heaven_shaking_hammer.tscn").instantiate() as HeavenShakingHammerAbility
	hammer.configure(Vector2.ZERO, Vector2(42, 0), 12.0, 38.5, 0, false, true, true)
	add_child(hammer)
	assert(is_equal_approx(hammer.damage, 24.0) and is_equal_approx(hammer.radius, 77.0))
	var before := enemy.global_position.distance_to(hammer.global_position)
	hammer.pull_enemies(0.05)
	assert(enemy.global_position.distance_to(hammer.global_position) < before)
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	add_child(foreground)
	var controller = load("res://scenes/ability/heaven_shaking_hammer_controller/heaven_shaking_hammer_controller.tscn").instantiate()
	add_child(controller)
	controller.heavy_enabled = true
	controller._process(10.0)
	assert(is_equal_approx(controller.quake_charge, 10.0))
	controller.on_timer_timeout()
	assert(is_equal_approx(controller.quake_charge, 0.0))
	assert(foreground.get_child(0).is_heavy)
	controller._process(1.0)
	enemy.remove_from_group("enemy")
	controller._process(1.0)
	assert(is_zero_approx(controller.quake_charge))
	print("Hammer specials test passed: pull, heavy scaling, charge and consumption.")
	get_tree().quit()
