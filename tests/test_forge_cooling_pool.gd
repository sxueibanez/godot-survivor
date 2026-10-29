extends Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "campaign"
	GameEvents.curse_no_normal_healing = false
	var forge := preload("res://scenes/environment/level_5_forge.gd").new()
	add_child(forge)
	forge.set_process(false)
	forge.activate(true)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	health.current_health = 50.0
	player.global_position = forge.COOLING_POOL_POSITION + Vector2(60, 0)
	forge._process(0.6)
	assert(is_equal_approx(forge.cooling_pool_charge, 0.6) and health.current_health == 50.0)
	player.global_position += Vector2(100, 0)
	forge._process(0.2)
	assert(forge.cooling_pool_charge == 0.0 and health.current_health == 50.0)
	player.global_position = forge.COOLING_POOL_POSITION + Vector2(60, 0)
	forge._process(0.6)
	get_tree().paused = true
	forge.update_cooling_pool(2.0, player)
	assert(is_equal_approx(forge.cooling_pool_charge, 0.6) and health.current_health == 50.0)
	get_tree().paused = false
	forge._process(0.4)
	assert(health.current_health == 58.0 and forge.cooling_pool_cooldown == 25.0)
	forge._process(1.0)
	assert(health.current_health == 58.0 and is_equal_approx(forge.cooling_pool_cooldown, 24.0))
	forge.cooling_pool_cooldown = 0.0
	GameEvents.curse_no_normal_healing = true
	forge._process(1.0)
	assert(health.current_health == 58.0 and forge.cooling_pool_cooldown == 0.0)
	GameEvents.curse_no_normal_healing = false
	health.current_health = health.max_health
	forge._process(1.0)
	assert(forge.cooling_pool_cooldown == 0.0)
	health.current_health = 0.0
	forge._process(1.0)
	assert(health.current_health == 0.0 and forge.cooling_pool_cooldown == 0.0)
	health.current_health = 50.0
	forge._process(0.5)
	forge.activate(false)
	assert(forge.cooling_pool_charge == 0.0 and forge.cooling_pool_cooldown == 0.0)
	forge._process(2.0)
	assert(health.current_health == 50.0)
	print("FORGE_COOLING_POOL_OK")
	get_tree().quit()
