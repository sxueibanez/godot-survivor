extends Node

class FakeUpgradeManager extends Node:
	var choice_screen_open := false
	var shown := 0
	var last_choices: Array[AbilityUpgrade] = []

	func show_external_choices(choices: Array[AbilityUpgrade], _callback: Callable) -> bool:
		shown += 1
		last_choices = choices
		return true


func _ready() -> void:
	GameEvents.reset_run_stats()
	var manager := CurseManager.new()
	add_child(manager)
	manager.build_definitions()
	assert(manager.definitions.size() == 12)
	assert(manager.CURSE_INTERVAL == 90.0 and manager.MAX_CURSES == 6)
	var ids: Array = manager.definitions.keys()
	assert(ids.size() == ids.duplicate().size())
	manager.apply_curse(manager.definitions["stampede"])
	assert(is_equal_approx(GameEvents.curse_enemy_health_multiplier, 0.8))
	assert(is_equal_approx(GameEvents.curse_enemy_speed_multiplier, 1.35))
	assert(is_equal_approx(GameEvents.curse_experience_multiplier, 1.5))
	manager.apply_curse(manager.definitions["cooldown_freeze"])
	assert(is_equal_approx(GameEvents.curse_weapon_damage_multiplier, 1.35))
	assert(is_equal_approx(GameEvents.curse_attack_interval_multiplier, 1.25))
	assert(is_equal_approx(GameEvents.curse_experience_multiplier, 1.875))
	manager.apply_curse(manager.definitions["stampede"])
	assert(manager.selected.size() == 2)
	var offers := manager.get_offer_choices()
	assert(offers.size() == 3 and offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2])
	for offer: AbilityUpgrade in offers:
		assert(not manager.selected.has(offer.id.trim_prefix("curse_")))
	manager.apply_curse(manager.definitions["glass_cannon"])
	manager.apply_curse(manager.definitions["glass_cannon"])
	assert(is_equal_approx(GameEvents.curse_weapon_damage_multiplier, 1.35 * 1.4))
	var zone := CurseManager.DangerZone.new()
	add_child(zone)
	zone.warning = 1.0
	zone.active_duration = 1.5
	zone._process(0.9)
	assert(zone.tick_left <= 0.0)
	zone._process(0.1)
	assert(is_equal_approx(zone.tick_left, manager.DAMAGE_TICK))
	var fake_upgrades := FakeUpgradeManager.new()
	add_child(fake_upgrades)
	manager.upgrade_manager = fake_upgrades
	manager.started = true
	manager._process(89.9)
	assert(fake_upgrades.shown == 0)
	manager._process(0.1)
	assert(fake_upgrades.shown == 1 and fake_upgrades.last_choices.size() == 3)
	manager._process(1.0)
	assert(fake_upgrades.shown == 1)
	GameEvents.reset_run_stats()
	assert(GameEvents.active_curses.is_empty())
	assert(GameEvents.curse_weapon_damage_multiplier == 1.0)
	var screen := preload("res://scenes/ui/upgrade_screen.tscn").instantiate()
	add_child(screen)
	assert(get_tree().paused)
	screen.queue_free()
	get_tree().paused = false
	zone.queue_free()
	fake_upgrades.queue_free()
	manager.queue_free()
	await get_tree().process_frame
	print("CURSE_MANAGER_TEST_PASSED")
	get_tree().call_deferred("quit")
