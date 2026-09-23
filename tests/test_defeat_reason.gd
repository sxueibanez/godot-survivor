extends Node


func _ready() -> void:
	var game_events := preload("res://scenes/autoload/game_events.tscn").instantiate()
	game_events.name = "GameEvents"
	get_tree().root.add_child(game_events)
	game_events.call("reset_run_stats")
	var player := Node.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.max_health = 10.0
	player.add_child(health)
	await get_tree().process_frame
	health.damage(10.0, "独眼蝙蝠")
	assert(game_events.get("last_damage_source") == "独眼蝙蝠")
	get_tree().quit()
