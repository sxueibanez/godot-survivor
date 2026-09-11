extends Node


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	health.owner = player
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	add_child(foreground)

	var controller := load("res://scenes/ability/azure_dragon_controller/azure_dragon_controller.tscn").instantiate() as AzureDragonController
	add_child(controller)
	await get_tree().process_frame
	assert(is_instance_valid(controller.dragon))
	for upgrade_id: String in ["azure_dragon_vermilion_bird", "azure_dragon_xuanwu", "azure_dragon_white_tiger"]:
		var upgrade := load("res://resources/upgrades/%s.tres" % upgrade_id) as AbilityUpgrade
		assert(upgrade.max_quantity == 1)
		controller.on_ability_upgrade_added(upgrade, {upgrade_id: {"quantity": 1}})
	assert(is_instance_valid(controller.vermilion_bird))
	assert(is_instance_valid(controller.xuanwu))
	assert(is_instance_valid(controller.white_tiger))
	assert(is_equal_approx(controller.vermilion_bird.get_node("AttackTimer").wait_time, controller.get_attack_interval_multiplier()))
	assert(is_equal_approx(controller.white_tiger.get_node("AttackTimer").wait_time, 5.0 * controller.get_attack_interval_multiplier()))
	assert(is_equal_approx(controller.xuanwu.get_node("ShieldTimer").wait_time, 30.0))
	for upgrade_id: String in ["azure_dragon_damage", "azure_dragon_size", "azure_dragon_rate"]:
		var upgrade := load("res://resources/upgrades/%s.tres" % upgrade_id) as AbilityUpgrade
		controller.on_ability_upgrade_added(upgrade, {upgrade_id: {"quantity": 1}})
	assert(is_equal_approx(controller.vermilion_bird.damage, controller.base_damage * controller.damage_multiplier))
	assert(is_equal_approx(controller.white_tiger.size_multiplier, controller.size_multiplier))
	assert(is_equal_approx(controller.vermilion_bird.get_node("AttackTimer").wait_time, controller.get_attack_interval_multiplier()))
	assert(is_equal_approx(controller.white_tiger.get_node("AttackTimer").wait_time, 5.0 * controller.get_attack_interval_multiplier()))
	assert(is_equal_approx(SacredTornado.PULL_RADIUS, 140.0))

	controller.xuanwu.generate_shield()
	assert(is_equal_approx(health.shield, 20.0))
	health.damage(30.0)
	assert(is_equal_approx(health.shield, 0.0) and is_equal_approx(health.current_health, 90.0))
	health.current_health = 100.0
	health.damage(100.0)
	assert(is_equal_approx(health.current_health, 30.0))
	assert(is_equal_approx(health.invulnerable_time_left, 3.0) and controller.xuanwu.death_save_used)
	health.damage(100.0)
	assert(is_equal_approx(health.current_health, 30.0))

	controller.begin_four_beasts_rush()
	assert(controller.four_beasts_active and controller.get_node("Timer").paused)
	assert(controller.four_beasts_trails.size() == 4 and controller.four_beasts_rings.size() == 2)
	controller._process(5.0)
	assert(not controller.four_beasts_active and not controller.get_node("Timer").paused)
	assert((load("res://resources/upgrades/azure_dragon_four_beasts.tres") as AbilityUpgrade).max_quantity == 1)
	var player_scene: Node = load("res://scenes/game_object/player/player.tscn").instantiate()
	assert(player_scene.has_node("ShieldBar"))
	player_scene.free()
	print("SACRED_BEASTS_TEST_PASSED")
	get_tree().quit()
