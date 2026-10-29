extends Node2D


class DoubleExperienceZone extends Node:
	func experience_multiplier_at(_point: Vector2) -> float:
		return 2.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.reset_run_stats()
	GameEvents.auto_collect_experience = true
	var zone := DoubleExperienceZone.new()
	zone.add_to_group("curse_manager")
	add_child(zone)
	var values: Array[float] = []
	var on_collected := func(value: float): values.append(value)
	GameEvents.experience_vial_collected.connect(on_collected)
	var vial := preload("res://scenes/game_object/experience_vial/experience_vial.tscn").instantiate()
	vial.process_mode = Node.PROCESS_MODE_PAUSABLE
	vial.experience_value = 2.0
	add_child(vial)
	await get_tree().create_timer(0.1).timeout
	assert(is_instance_valid(vial) and not vial.collecting and values.is_empty())
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(80, 0)
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	await get_tree().create_timer(0.3).timeout
	assert(vial.collecting)
	player.remove_from_group("player")
	await get_tree().create_timer(0.65).timeout
	assert(is_instance_valid(vial) and not vial.collecting and values.is_empty())
	assert(vial.experience_value == 2.0 and vial.get_node("Sprite2D").scale == Vector2.ONE)
	player.add_to_group("player")
	await get_tree().create_timer(0.9).timeout
	assert(not is_instance_valid(vial) and values == [4.0])
	health.current_health = 0.0
	var next_vial := preload("res://scenes/game_object/experience_vial/experience_vial.tscn").instantiate()
	next_vial.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(next_vial)
	await get_tree().create_timer(0.3).timeout
	assert(is_instance_valid(next_vial) and not next_vial.collecting and values.size() == 1)
	health.current_health = 100.0
	await get_tree().create_timer(0.9).timeout
	assert(not is_instance_valid(next_vial) and values == [4.0, 2.0])
	GameEvents.auto_collect_experience = false
	var manual_vial := preload("res://scenes/game_object/experience_vial/experience_vial.tscn").instantiate()
	manual_vial.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(manual_vial)
	manual_vial.collect_to_player()
	get_tree().paused = true
	await get_tree().create_timer(0.7, true).timeout
	assert(manual_vial.collecting and values == [4.0, 2.0])
	get_tree().paused = false
	await get_tree().create_timer(0.7).timeout
	assert(not is_instance_valid(manual_vial) and values == [4.0, 2.0, 2.0])
	GameEvents.experience_vial_collected.disconnect(on_collected)
	GameEvents.reset_run_stats()
	print("EXPERIENCE_COLLECT_RECOVERY_OK")
	get_tree().quit()
