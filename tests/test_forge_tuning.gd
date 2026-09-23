extends Node

const ART = preload("res://scenes/environment/forge_art.gd")
const EFFECT = preload("res://scenes/environment/forge_effect.gd")

func _ready() -> void:
	var image := Image.load_from_file(ART.SPRITE_ROOT + "fire-effects-v2.png")
	assert(image != null and image.get_pixel(0, 0).a == 0)
	for kind: String in ART.FIRE_ROWS:
		for frame in 6:
			var texture := ART.fire_frame_texture(kind, frame)
			assert(image.get_region(Rect2i(texture.region)).get_used_rect().has_area())
			assert(image.get_pixelv(Vector2i(texture.region.position)).a == 0)
			assert(ART.fire_frame_texture(kind, frame) == texture)
	GameEvents.game_mode = "boss_rush"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.set_process(false)
	main.boss_rush.set_process(false)
	main.challenges.stop_challenges()
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.queue_free()
	get_tree().paused = false
	var player: Node2D = main.get_node("Entities/Player")
	player.set_process(false)
	player.get_node("Abilities").process_mode = Node.PROCESS_MODE_DISABLED
	player.get_node("HealthComponent").max_health = 1000
	player.get_node("HealthComponent").current_health = 1000
	assert(player.get_contact_damage() == 10)
	main.show_map(5)
	main.forge_map.set_process(false)
	var guard: Node2D = main.get_node("EnemyManager").GUARD.instantiate()
	main.get_node("Entities").add_child(guard)
	guard.set_process(false)
	guard.global_position = player.global_position
	assert(guard.DISPLAY_HEIGHTS[1] == 70)
	assert(is_equal_approx(guard.get_node("CollisionShape2D").shape.radius, 8.4))
	assert(guard.get_meta("contact_damage") == 24)
	for tick in 4:
		await get_tree().physics_frame
		await get_tree().process_frame
	assert(player.get_contact_damage() == 24, "Forge contact damage must reach the player damage path")
	guard.drop_barrel(1.2)
	assert(guard.barrel.player_damage == 28)
	guard.queue_free()
	await get_tree().process_frame
	player.global_position = Vector2(910, 384)
	main.show_map(1)
	assert(player.global_position == Vector2(384, 384), "Leaving larger forge must keep player inside shared arena")
	for map_id in range(1, 6):
		main.show_map(map_id)
		await get_tree().physics_frame
		await get_tree().physics_frame
		for offset: Vector2 in [Vector2.ZERO, Vector2(-160, 0), Vector2(160, 0), Vector2(0, -160), Vector2(0, 160)]:
			player.global_position = Vector2(384, 384) + offset
			main.boss_rush.spawning_boss = true
			var boss: Node2D = main.spawn_furnace_tyrant()
			main.boss_rush.spawning_boss = false
			boss.set_process(false)
			assert(boss.global_position != Vector2.ZERO)
			if map_id == 5:
				assert(main.forge_map.is_walkable(boss.global_position, 72))
			else:
				assert(main.get_node("EnemyManager").boss_position_has_floor(boss.global_position), "Boss outside floor on map %d" % map_id)
			boss.begin_state("idle", "walk")
			boss.start_skill("flame")
			boss._process(0.91)
			var found := false
			for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
				if effect.owner_id == boss.get_instance_id() and effect.kind == "flame":
					assert(effect.player_damage == 14)
					found = true
			assert(found)
			boss.cancel_attacks()
			boss.begin_state("idle", "walk")
			boss.start_skill("punch")
			boss.land_punch()
			for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
				if effect.owner_id == boss.get_instance_id():
					if effect.kind == "fire":
						assert(effect.player_damage == 40)
					if effect.kind == "wave":
						assert(effect.player_damage == 14)
			boss.cancel_attacks()
			boss.queue_free()
			await get_tree().process_frame
	var slag := EFFECT.new()
	main.get_node("Foreground").add_child(slag)
	slag.spawn_fire()
	var fire_found := false
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect != slag and effect.kind == "fire" and not effect.is_queued_for_deletion():
			assert(effect.player_damage == 12)
			fire_found = true
	assert(fire_found)
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	print("FORGE_TUNING_OK: 24 transparent fire frames, enlarged guard/unchanged collision, stronger skills, 25 actual boss spawns inside all five maps")
	get_tree().quit()
