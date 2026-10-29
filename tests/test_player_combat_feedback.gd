extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var layer := Node2D.new()
	layer.add_to_group("floating_text_layer")
	add_child(layer)
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	var health := player.get_node("HealthComponent") as HealthComponent
	var velocity := player.get_node("VelocityComponent") as VelocityComponent
	health.set_shield(20.0)
	health.damage(10.0)
	assert(layer.get_child_count() == 0)
	health.damage(20.5)
	assert(layer.get_child_count() == 1)
	var damage_label := layer.get_child(0).get_node("Label") as Label
	assert(damage_label.text == "-10.5")
	assert(damage_label.get_theme_color("font_color") == Color(1.0, 0.35, 0.3))
	health.heal(5.0)
	assert(layer.get_child_count() == 2)
	var heal_label := layer.get_child(1).get_node("Label") as Label
	assert(heal_label.text == "+5")
	assert(heal_label.get_theme_color("font_color") == Color(0.4, 1.0, 0.55))
	velocity.apply_slow(0.35, 1.2)
	velocity.apply_slippery(0.2)
	player.update_movement_status()
	assert(player.movement_status.text == "减速 1.2s · 打滑")
	velocity.stun_time_left = 0.6
	player.update_movement_status()
	assert(player.movement_status.text.begins_with("眩晕 0.6s"))
	velocity.slow_time_left = 0.0
	velocity.slippery_time_left = 0.0
	velocity.stun_time_left = 0.0
	player.update_movement_status()
	assert(player.movement_status.text.is_empty())
	print("PLAYER_COMBAT_FEEDBACK_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
