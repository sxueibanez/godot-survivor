extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "campaign"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
	main.call("begin_level_1")
	main.set_process(false)
	main.get_node("ArenaTimeManager").set_process(false)
	main.get_node("EnemyManager").stop_spawning()
	var events: Node = main.get("challenges")
	events.set_process(false)
	var upgrades: Node = main.get_node("UpgradeManager")
	upgrades.choice_screen_open = true # Exercise reward queuing without opening modal screens.
	get_tree().paused = false
	events.start_hunt()
	assert(events.challenge_enemies.size() == 4)
	var health := events.hunt.get_node("HealthComponent") as HealthComponent
	health.damage(health.max_health * 2)
	await get_tree().process_frame
	assert(events.hunt == null)
	assert(upgrades.pending_challenge_rewards.size() == 1)
	events.call("_process", 4.9)
	assert(not events.status.text.is_empty())
	events.call("_process", 0.11)
	assert(events.status.text.is_empty())
	events.start_hunt()
	events.hunt_left = 0.01
	events.call("_process", 0.02)
	assert(events.hunt == null)
	assert(upgrades.pending_challenge_rewards.size() == 1)
	var controller := Node.new()
	main.get_node("Entities/Player/Abilities").add_child(controller)
	var timer := Timer.new()
	timer.name = "Timer"
	timer.wait_time = 2.0
	controller.add_child(timer)
	events.start_overload()
	assert(is_equal_approx(timer.wait_time, 1.3))
	assert(GameEvents.challenge_experience_multiplier == 2.0)
	events.set_process(true)
	get_tree().paused = true
	var remaining: float = events.overload_left
	await get_tree().process_frame
	await get_tree().process_frame
	assert(events.overload_left == remaining)
	events.set_process(false)
	get_tree().paused = false
	events.spawn_wave()
	assert(events.wave.size() == 3)
	events.call("_process", 20.0)
	assert(GameEvents.challenge_experience_multiplier == 1.0)
	assert(is_equal_approx(timer.wait_time, 2.0))
	var elite: Node2D = events.challenge_enemies.back()
	health = elite.get_node("HealthComponent") as HealthComponent
	health.damage(health.max_health * 2)
	await get_tree().process_frame
	assert(upgrades.pending_challenge_rewards.size() == 2)
	events.start_bounty()
	assert(events.bounty_remaining == 2)
	assert(get_tree().get_nodes_in_group("boss").size() == 2)
	var bosses := get_tree().get_nodes_in_group("boss")
	health = bosses[0].get_node("HealthComponent") as HealthComponent
	health.damage(health.max_health * 2)
	await get_tree().process_frame
	assert(events.bounty_remaining == 1)
	assert(upgrades.pending_challenge_rewards.size() == 2)
	health = bosses[1].get_node("HealthComponent") as HealthComponent
	health.damage(health.max_health * 2)
	await get_tree().process_frame
	assert(events.bounty_remaining == 0)
	assert(upgrades.pending_challenge_rewards.size() == 4)
	upgrades.current_upgrades["sword"] = {"resource": upgrades.upgrade_sword, "quantity": 1}
	upgrades.upgrade_pool.add_item(upgrades.upgrade_sword_damage, 5)
	upgrades.upgrade_pool.add_item(upgrades.upgrade_sword_rain, 5)
	upgrades.upgrade_pool.add_item(upgrades.upgrade_sword_rain, 5)
	var choices: Array = upgrades.pick_challenge_upgrades(4)
	assert(choices.size() == 2)
	assert(choices[0].id == "sword_rain")
	upgrades.disable_upgrade_for_run(upgrades.upgrade_sword_rain)
	assert(upgrades.pick_challenge_upgrades(4).size() == 1)
	var old_token: int = events.generation
	events.reset_challenges()
	events.on_bounty_boss_died(old_token)
	assert(upgrades.pending_challenge_rewards.size() == 4)
	main.get_node("ArenaTimeManager").time_elapsed = 180.0
	events.call("_process", 0.01)
	assert(is_instance_valid(events.overload_point))
	assert(is_instance_valid(events.bounty_point))
	events.call("_process", 29.98)
	assert(is_instance_valid(events.bounty_point))
	events.call("_process", 0.02)
	assert(events.bounty_point == null)
	main.get_node("ArenaTimeManager").time_elapsed = 280.0
	events.call("_process", 0.01)
	assert(events.overload_point.is_queued_for_deletion())
	assert(events.bounty_point == null)
	events.reset_challenges()
	assert(GameEvents.challenge_attack_interval_multiplier == 1.0)
	assert(GameEvents.challenge_experience_multiplier == 1.0)
	main.get_node("Entities/Player").queue_free()
	await get_tree().process_frame
	events.apply_attack_rate()
	events.call("_process", 0.01)
	assert(events.stopped)
	assert(not events.is_processing())
	assert(events.player_position() == Vector2.ZERO)
	events.call("_process", 30.0)
	assert(events.challenge_enemies.is_empty())
	assert(upgrades.pending_challenge_rewards.size() == 4)
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("CHALLENGE_TEST_PASSED")
	get_tree().quit()
