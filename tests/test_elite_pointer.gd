extends Node2D


func make_enemy(point: Vector2) -> Node2D:
	var enemy := Node2D.new()
	enemy.position = point
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	enemy.add_child(health)
	add_child(enemy)
	return enemy


func _ready() -> void:
	var entities := Node2D.new()
	entities.name = "Entities"
	add_child(entities)
	var player := Node2D.new()
	player.name = "Player"
	player.position = Vector2(320, 180)
	entities.add_child(player)
	var events := preload("res://scenes/manager/challenge_manager.gd").new()
	add_child(events)
	events.set_process(false)
	var first := make_enemy(Vector2(850, 180))
	events.elite_timers.append({"enemy": first, "left": 20.0})
	events.update_elite_pointer()
	assert(events.elite_pointer.visible and events.elite_pointer.text == "精英：右 · 530 · 20秒")
	var second := make_enemy(Vector2(-200, 180))
	events.elite_timers.append({"enemy": second, "left": 10.0})
	events.update_elite_pointer()
	assert(events.elite_pointer.text == "精英：左 · 520 · 10秒")
	(second.get_node("HealthComponent") as HealthComponent).current_health = 0.0
	events.update_elite_pointer()
	assert(events.elite_pointer.text == "精英：右 · 530 · 20秒")
	first.position = player.position + Vector2(10, 0)
	events.update_elite_pointer()
	assert(not events.elite_pointer.visible)
	var camera := Camera2D.new()
	camera.position = player.position
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	camera.make_current()
	first.position = player.position + Vector2(200, 0)
	camera.force_update_scroll()
	await get_tree().process_frame
	events.update_elite_pointer()
	assert(events.elite_pointer.visible)
	camera.zoom = Vector2.ONE
	camera.force_update_scroll()
	await get_tree().process_frame
	events.update_elite_pointer()
	assert(not events.elite_pointer.visible)
	events.reset_challenges()
	assert(not events.elite_pointer.visible)
	print("ELITE_POINTER_OK")
	get_tree().quit()
