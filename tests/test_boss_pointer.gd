extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.position = Vector2(320, 180)
	player.add_to_group("player")
	add_child(player)
	var boss := Node2D.new()
	boss.position = Vector2(800, 180)
	boss.add_to_group("boss")
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	boss.add_child(health)
	add_child(boss)
	var hud := preload("res://scenes/ui/boss_health_bar.tscn").instantiate()
	add_child(hud)
	hud.set_process(false)
	hud._process(0.0)
	assert(hud.boss_pointer.visible and hud.boss_pointer.text == "首领：右 · 480")
	boss.position = Vector2(400, 180)
	hud._process(0.0)
	assert(not hud.boss_pointer.visible)
	var camera := Camera2D.new()
	camera.position = player.position
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	camera.make_current()
	boss.position = player.position + Vector2(200, 0)
	camera.force_update_scroll()
	await get_tree().process_frame
	hud._process(0.0)
	assert(hud.boss_pointer.visible)
	camera.zoom = Vector2.ONE
	camera.force_update_scroll()
	await get_tree().process_frame
	hud._process(0.0)
	assert(not hud.boss_pointer.visible)
	health.current_health = 0.0
	boss.position = Vector2(800, 180)
	hud._process(0.0)
	assert(not hud.boss_pointer.visible)
	boss.queue_free()
	await get_tree().process_frame
	hud._process(0.0)
	assert(not hud.boss_pointer.visible and not hud.content.visible)
	print("BOSS_POINTER_OK")
	get_tree().quit()
