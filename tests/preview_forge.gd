extends Node

func _ready() -> void:
	GameEvents.game_mode = "campaign"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.queue_free()
	get_tree().paused = false
	main.begin_level_5()
	main.set_process(false)
	main.get_node("ArenaTimeManager").set_process(false)
	main.get_node("EnemyManager").stop_spawning()
	main.challenges.stop_challenges()
	var player: Node = main.get_node("Entities/Player")
	player.set_process(false)
	player.get_node("Abilities").process_mode = Node.PROCESS_MODE_DISABLED
	main.get_node("CheatUI").hide()
	var camera := get_tree().get_first_node_in_group("camera") as Camera2D
	if camera == null:
		camera = Camera2D.new()
		main.add_child(camera)
	camera.set_process(false)
	camera.position = main.forge_map.CENTER
	camera.zoom = Vector2.ONE * 0.28
	camera.make_current()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png("res://assets/forge/map-preview.png")
		print("FORGE_MAP_PREVIEW_SAVED")
	camera.zoom = Vector2.ONE
	camera.position = main.forge_map.CENTER + Vector2(-30, -30)
	var boss: Node2D = main.spawn_boss_for_map(5)
	boss.global_position = main.forge_map.CENTER + Vector2(-60, 20)
	boss.set_process(false)
	boss.begin_state("idle", "walk")
	player.global_position = main.forge_map.valves[0].position
	boss.start_skill("punch")
	for kind in 3:
		var scene: PackedScene = [main.get_node("EnemyManager").CINDER, main.get_node("EnemyManager").GUARD, main.get_node("EnemyManager").WORKER][kind]
		var enemy := scene.instantiate() as Node2D
		main.get_node("Entities").add_child(enemy)
		enemy.global_position = main.forge_map.CENTER + Vector2(70 + kind * 50, 90)
		enemy.set_process(false)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	image = get_viewport().get_texture().get_image()
	if image != null:
		image.save_png("res://assets/forge/combat-preview.png")
		print("FORGE_COMBAT_PREVIEW_SAVED")
	for index in 4:
		var effect := preload("res://scenes/environment/forge_effect.gd").new()
		effect.kind = ["fire", "flame", "eruption", "ember"][index]
		effect.warning_time = 0
		effect.active_time = 10
		effect.elapsed = 0.25
		effect.player_damage = 0
		effect.set_process(false)
		main.get_node("Foreground").add_child(effect)
		effect.global_position = main.forge_map.CENTER + Vector2(-150 + index * 90, -15)
		effect.radius = 45 if index == 1 else 22
		if index == 1:
			effect.shape = "cone"
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	image = get_viewport().get_texture().get_image()
	if image != null:
		image.save_png("res://assets/forge/fire-preview.png")
		print("FORGE_FIRE_PREVIEW_SAVED")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()
