extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	assert(load("res://scenes/main/main.gd") != null)
	var player := Node.new()
	player.add_to_group("player")
	root.add_child(player)
	var health = load("res://scenes/component/health_component.gd").new()
	player.add_child(health)
	health.owner = player
	health.current_health = 0.0
	health.check_death()
	assert(not player.is_queued_for_deletion(), "Player must remain for the death dissolve")
	player.queue_free()
	await process_frame
	quit()
