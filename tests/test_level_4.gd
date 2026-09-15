extends SceneTree


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var scenes := [
		preload("res://scenes/game_object/frost_wisp/frost_wisp.tscn"),
		preload("res://scenes/game_object/frost_boar/frost_boar.tscn"),
		preload("res://scenes/game_object/snowball_monster/snowball_monster.tscn"),
		preload("res://scenes/game_object/frost_queen/frost_queen.tscn"),
	]
	for enemy_scene in scenes:
		var enemy := enemy_scene.instantiate()
		root.add_child(enemy)
		assert(enemy.is_in_group("enemy"))
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	root.add_child(foreground)
	var wisp := scenes[0].instantiate()
	root.add_child(wisp)
	wisp.call("fire", Vector2.DOWN)
	assert(is_equal_approx(foreground.get_child(0).rotation, PI * 0.5))

	var queen := scenes[-1].instantiate()
	root.add_child(queen)
	assert(queen.is_in_group("boss"))
	assert(queen.call("get_phase") == 1)
	var health := queen.get_node("HealthComponent") as HealthComponent
	health.current_health = health.max_health * 0.5
	assert(queen.call("get_phase") == 2)
	health.current_health = health.max_health * 0.2
	assert(queen.call("get_phase") == 3)

	var movement := VelocityComponent.new()
	movement.apply_slippery(1.0)
	assert(movement.slippery_time_left == 1.0)
	movement.free()
	quit()
