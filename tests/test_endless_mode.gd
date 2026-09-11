extends SceneTree


func _init() -> void:
	var manager := preload("res://scenes/manager/enemy_manager.tscn").instantiate()
	assert(manager.get_endless_spawn_count(0) == 1)
	assert(manager.get_endless_spawn_count(12) == 2)
	assert(manager.get_endless_spawn_count(120) == 11)
	assert(is_equal_approx(manager.get_endless_boss_health_multiplier(0), 0.25))
	assert(is_equal_approx(manager.get_endless_boss_health_multiplier(12), 0.43))
	GameEvents.game_mode = "endless"
	assert(GameEvents.is_endless_mode())
	GameEvents.game_mode = "campaign"
	quit()
