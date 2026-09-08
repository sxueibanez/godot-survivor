extends Node


func _ready() -> void:
	var enemy := preload("res://scenes/game_object/basic_enemy/basic_enemy.tscn").instantiate()
	add_child(enemy)
	await get_tree().process_frame
	var health := enemy.get_node("HealthComponent") as HealthComponent
	var health_bar := enemy.get_node("HealthBar") as ProgressBar
	assert(health_bar.value == 1.0)
	assert((health_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == Color(0.95, 0.2, 0.25, 1))
	get_tree().quit()
