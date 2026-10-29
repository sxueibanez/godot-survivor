extends Node2D


func make_enemy(point: Vector2) -> Node2D:
	var enemy := Node2D.new()
	enemy.position = point
	enemy.add_to_group("enemy")
	add_child(enemy)
	return enemy


func _ready() -> void:
	GameEvents.reset_run_stats()
	var layer := Node2D.new()
	layer.add_to_group("player_projectiles_layer")
	add_child(layer)
	var bomb := preload("res://scenes/ability/bomb_ability/bomb_ability.tscn").instantiate() as BombAbility
	bomb.configure(Vector2.ZERO, Vector2.ZERO, 15.0, 30.0, 1, false, false)
	layer.add_child(bomb)
	bomb.set_process(false)
	var lone := make_enemy(Vector2(45, 0))
	var clustered := make_enemy(Vector2(100, 0))
	var neighbor := make_enemy(Vector2(100, 18))
	var neighbor_two := make_enemy(Vector2(110, 0))
	var dead := make_enemy(Vector2(100, 12))
	var dead_health := HealthComponent.new()
	dead_health.name = "HealthComponent"
	dead.add_child(dead_health)
	dead_health.current_health = 0.0
	assert(bomb.find_bounce_target().is_equal_approx(clustered.global_position))
	neighbor.queue_free()
	neighbor_two.queue_free()
	assert(bomb.find_bounce_target().is_equal_approx(lone.global_position))
	bomb.queue_free()
	lone.remove_from_group("enemy")
	clustered.remove_from_group("enemy")

	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var right := make_enemy(Vector2(80, 0))
	var down := make_enemy(Vector2(0, 100))
	var outside := make_enemy(Vector2(400, 0))
	var controller := preload("res://scenes/ability/thunder_orb_book_controller/thunder_orb_book_controller.tscn").instantiate() as ThunderOrbBookController
	add_child(controller)
	controller.get_node("Timer").stop()
	controller.attack_count = 3
	controller.on_timer_timeout()
	assert(layer.get_child_count() == 4) # Bomb is queued for deletion; three new orbs are alive.
	var first := layer.get_child(1) as ThunderOrbBookAbility
	var second := layer.get_child(2) as ThunderOrbBookAbility
	var third := layer.get_child(3) as ThunderOrbBookAbility
	assert(first.normal_direction.is_equal_approx(Vector2.RIGHT))
	assert(second.normal_direction.is_equal_approx(Vector2.DOWN))
	assert(third.normal_direction.is_equal_approx(Vector2.RIGHT.rotated(deg_to_rad(12.0))))
	controller.on_timer_timeout()
	assert(layer.get_child_count() == 4)
	first.queue_free()
	second.queue_free()
	third.queue_free()
	await get_tree().process_frame
	down.remove_from_group("enemy")
	controller.on_timer_timeout()
	assert(layer.get_child_count() == 3)
	assert((layer.get_child(0) as ThunderOrbBookAbility).normal_direction.is_equal_approx(Vector2.RIGHT.rotated(deg_to_rad(-12.0))))
	assert((layer.get_child(1) as ThunderOrbBookAbility).normal_direction.is_equal_approx(Vector2.RIGHT))
	assert((layer.get_child(2) as ThunderOrbBookAbility).normal_direction.is_equal_approx(Vector2.RIGHT.rotated(deg_to_rad(12.0))))
	assert(is_instance_valid(right) and is_instance_valid(outside))
	print("WEAPON_TARGETING_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
