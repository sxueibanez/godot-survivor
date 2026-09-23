extends SceneTree

func _initialize() -> void:
	call_deferred("run_check")

func run_check() -> void:
	var screen = load("res://scenes/ui/upgrade_screen.tscn").instantiate()
	root.add_child(screen)
	var upgrades: Array[AbilityUpgrade] = []
	for id in ["sword_greatsword_sweep", "critical_hit", "sword_rate"]:
		upgrades.append(load("res://resources/upgrades/%s.tres" % id))
	screen.set_ability_upgrades(upgrades)
	screen.enable_health_reroll(0.15)
	await process_frame
	await process_frame
	for index in 3:
		var card = screen.card_container.get_child(index)
		assert(card.get_node("%KeyHint").text == str(index + 1))
		assert(root.get_visible_rect().encloses(card.get_global_rect()))
	assert(screen.health_reroll_button.size.x <= 72.0)
	assert(not screen.health_reroll_button.get_global_rect().intersects(screen.card_container.get_global_rect()))
	screen.on_upgrade_disabled(upgrades[0], screen.card_container.get_child(0))
	assert(screen.card_container.get_child(0).get_node("%KeyHint").text == "1")
	assert(screen.card_container.get_child(1).get_node("%KeyHint").text == "2")
	paused = false
	screen.queue_free()
	await process_frame
	quit()
