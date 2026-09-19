extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	assert(main.get_node("TileMap").z_index == -100)
	assert(main.get_node("GroundDecor").z_index == -20)
	assert(main.get_node("GroundEffects").z_index == -10)
	assert(main.get_node("EnemyProjectiles").z_index == 0)
	assert(main.get_node("Entities").z_index == 10 and main.get_node("Entities").y_sort_enabled)
	assert(main.get_node("PlayerProjectiles").z_index == 20)
	assert(main.get_node("CombatEffects").z_index == 30)
	assert(main.get_node("FloatingText").z_index == 40)
	assert(main.get_node("ArenaTimeUI").layer == 10)
	assert(main.get_node("BossHealthBar").layer == 20)
	for script_path in [
		"res://scenes/ability/azure_dragon_controller/azure_dragon_controller.gd",
		"res://scenes/ability/sword_ability_controller/sword_ability_controller.gd",
		"res://scenes/game_object/frost_queen/frost_queen.gd",
		"res://scenes/game_object/slime_king/slime_king.gd",
	]:
		assert(load(script_path) != null)
	var player: Node = main.get_node("Entities/Player")
	assert(player.get_node("HealthBar").z_index == 50 and not player.get_node("HealthBar").z_as_relative)
	main.queue_free()
	paused = false
	await process_frame
	quit()
