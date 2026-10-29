extends Node


func _ready() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(160, 0)
	add_child(player)
	var projectiles := Node2D.new()
	projectiles.add_to_group("enemy_projectiles_layer")
	add_child(projectiles)
	var enemy := preload("res://scenes/game_object/ranged_enemy/ranged_enemy.tscn").instantiate()
	add_child(enemy)
	enemy.set_process(false)

	enemy._process(1.0)
	assert(enemy.aim_time > 0.0)
	assert(projectiles.get_child_count() == 0)
	var locked_direction: Vector2 = enemy.aim_direction
	player.position = Vector2(0, 160)
	enemy._process(0.3)
	assert(projectiles.get_child_count() == 0)
	enemy._process(0.31)
	assert(projectiles.get_child_count() == 3)
	assert(projectiles.get_child(1).direction.is_equal_approx(locked_direction))
	assert(enemy.aim_time == 0.0)
	assert(enemy.cooldown > 0.0)
	print("RANGED_AIM_OK")
	get_tree().quit()
