extends Node


func _ready() -> void:
	var miner := preload("res://scenes/game_object/iron_arm_miner/iron_arm_miner.tscn").instantiate()
	add_child(miner)
	await get_tree().process_frame
	assert(miner.is_in_group("boss"))
	assert(miner.get_meta("display_name") == "铁臂矿工")
	assert((miner.get_node("HealthComponent") as HealthComponent).max_health == 5000.0)
	assert(miner.call("get_phase") == 1)
	(miner.get_node("HealthComponent") as HealthComponent).current_health = 2500.0
	assert(miner.call("get_phase") == 2)
	(miner.get_node("HealthComponent") as HealthComponent).current_health = 1000.0
	assert(miner.call("get_phase") == 3)
	miner.call("show_run_frame", 7)
	assert((miner.get_node("Visuals/Sprite2D") as Sprite2D).region_rect == Rect2(2220, 0, 323, 345))
	var entities := Node2D.new()
	entities.add_to_group("entities_layer")
	add_child(entities)
	miner.call("summon_golems")
	assert(entities.get_child_count() == 5)
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	add_child(foreground)
	miner.call("melee_attack")
	assert(foreground.get_child_count() == 1)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	miner.call("spawn_rock")
	var projectile := foreground.get_child(-1)
	assert((projectile.get_child(0) as Sprite2D).texture == load("res://assets/enemies/stone_slime_walk.png"))
	get_tree().quit()
