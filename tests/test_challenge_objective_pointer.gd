extends Node2D


func _ready() -> void:
	var entities := Node2D.new()
	entities.name = "Entities"
	add_child(entities)
	var player := Node2D.new()
	player.name = "Player"
	player.position = Vector2(320, 180)
	entities.add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	player.add_child(health)
	var challenges := preload("res://scenes/manager/challenge_manager.gd").new()
	add_child(challenges)
	challenges.set_process(false)
	var overload := Node2D.new()
	overload.position = Vector2(950, 180)
	add_child(overload)
	var bounty := Node2D.new()
	bounty.position = Vector2(320, -220)
	add_child(bounty)
	challenges.overload_point = overload
	challenges.bounty_point = bounty
	challenges.overload_charge = 2.0
	challenges.bounty_offer_left = 12.4
	challenges.update_objective_pointer()
	assert(challenges.objective_pointer.visible)
	assert(challenges.objective_pointer.text == "超载 40%：右 · 630\n悬赏 13秒：上 · 400")
	overload.position = player.position + Vector2(10, 0)
	challenges.update_objective_pointer()
	assert(challenges.objective_pointer.text == "悬赏 13秒：上 · 400")
	bounty.queue_free()
	challenges.update_objective_pointer()
	assert(not challenges.objective_pointer.visible)
	var camera := Camera2D.new()
	camera.position = player.position
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	camera.make_current()
	overload.position = player.position + Vector2(200, 0)
	camera.force_update_scroll()
	await get_tree().process_frame
	challenges.update_objective_pointer()
	assert(challenges.objective_pointer.visible)
	camera.zoom = Vector2.ONE
	camera.force_update_scroll()
	await get_tree().process_frame
	challenges.update_objective_pointer()
	assert(not challenges.objective_pointer.visible)
	overload.position = Vector2(950, 180)
	challenges.update_objective_pointer()
	assert(challenges.objective_pointer.visible)
	health.current_health = 0.0
	challenges.update_objective_pointer()
	assert(not challenges.objective_pointer.visible)
	health.current_health = health.max_health
	challenges.reset_challenges()
	assert(not challenges.objective_pointer.visible)
	print("CHALLENGE_OBJECTIVE_POINTER_OK")
	get_tree().quit()
