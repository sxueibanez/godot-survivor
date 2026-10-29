extends Node


func _ready() -> void:
	GameEvents.game_mode = "normal"
	var vignette := preload("res://scenes/ui/vignette.tscn").instantiate()
	add_child(vignette)
	var overlay := vignette.get_node("LowHealthOverlay") as ColorRect
	await get_tree().process_frame
	assert(not overlay.visible)
	var player := Node2D.new()
	player.add_to_group("player")
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	add_child(player)
	await get_tree().process_frame
	assert(not overlay.visible)
	health.damage(75.0)
	vignette._process(0.1)
	assert(overlay.visible)
	assert(overlay.modulate.a >= 0.16 and overlay.modulate.a <= 0.4)
	health.heal(1.0)
	vignette._process(0.1)
	assert(not overlay.visible)
	health.damage(26.0)
	vignette._process(0.1)
	assert(not overlay.visible)
	player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not overlay.visible)
	print("LOW_HEALTH_WARNING_OK")
	MusicPlayer.stop()
	get_tree().quit()
