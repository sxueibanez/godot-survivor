extends Node


func _ready() -> void:
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var player := main.get_node("Entities/Player") as CharacterBody2D
	var boss := CharacterBody2D.new()
	boss.add_to_group("boss")
	main.get_node("Entities").add_child(boss)
	boss.global_position = player.global_position + Vector2.LEFT
	player.call("on_body_entered", boss)
	var velocity := player.get_node("VelocityComponent") as VelocityComponent
	assert(velocity.knockback_velocity.x > 0.0)
	assert(velocity.knockback_time_left > 0.0)
	get_tree().quit()
