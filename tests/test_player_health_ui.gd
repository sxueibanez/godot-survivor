extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var ui := preload("res://scenes/ui/player_health_ui.tscn").instantiate()
	add_child(ui)
	ui.set_process(false)
	ui._process(0.0)
	assert(not ui.visible)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	ui._process(0.0)
	assert(ui.visible and ui.health_label.text == "生命 100 / 100")
	assert(not ui.shield_label.visible)
	health.damage(20.5)
	assert(ui.health_label.text == "生命 79.5 / 100")
	health.set_shield(15.0)
	health.set_temporary_shield(3.0, 1.0)
	assert(ui.shield_label.visible and ui.shield_label.text == "护盾 18")
	health.set_shield(0.0)
	health.set_temporary_shield(0.0, 0.0)
	assert(not ui.shield_label.visible)
	player.remove_from_group("player")
	ui._process(0.0)
	assert(not ui.visible)
	player.add_to_group("player")
	ui._process(0.0)
	player.queue_free()
	await get_tree().process_frame
	ui._process(0.0)
	assert(not ui.visible)
	var replacement := Node2D.new()
	replacement.add_to_group("player")
	add_child(replacement)
	var new_health := HealthComponent.new()
	new_health.name = "HealthComponent"
	new_health.max_health = 50.0
	replacement.add_child(new_health)
	ui._process(0.0)
	assert(ui.visible and ui.health_label.text == "生命 50 / 50")
	new_health.damage(5.0)
	assert(ui.health_label.text == "生命 45 / 50")
	var main := preload("res://scenes/main/main.tscn").instantiate()
	assert(main.get_node_or_null("PlayerHealthUI") != null)
	main.free()
	print("PLAYER_HEALTH_UI_OK")
	get_tree().quit()
