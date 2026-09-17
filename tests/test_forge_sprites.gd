extends Node

const ART = preload("res://scenes/environment/forge_art.gd")

func _ready() -> void:
	var frames := 0
	for sheet: String in ART.SPRITE_SHEETS:
		var image := Image.load_from_file(ART.SPRITE_ROOT + sheet + ".png")
		assert(image != null)
		assert(image.get_pixel(0, 0).a == 0, "Not transparent: " + sheet)
		assert(image.get_pixel(image.get_width() - 1, image.get_height() - 1).a == 0)
	for actor: String in ART.ACTORS:
		for action: String in ART.ACTORS[actor]:
			if action == "size":
				continue
			var count := ART.frame_count(actor, action)
			for frame in count:
				var texture: AtlasTexture = ART.frame_texture(actor, action, frame)
				assert(texture != null and texture.region.has_area())
				var bounds := Rect2(Vector2.ZERO, texture.atlas.get_size())
				assert(bounds.encloses(texture.region), "Frame cut outside source atlas")
				assert(texture.get_width() == texture.get_height())
				assert(texture.margin.position.x >= 0 and texture.margin.position.y >= 0)
				var feet := texture.margin.position.y + texture.region.size.y
				assert(absf(feet / texture.get_height() - 0.9) < 0.004)
				assert(ART.frame_texture(actor, action, frame) == texture)
				frames += 1
	print("FORGE_SPRITES_OK: seven real-alpha atlases, %d nonempty frames, source bounds, fixed feet, cache" % frames)
	GameEvents.game_mode = "boss_rush"
	var main := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	for scene: PackedScene in [main.get_node("EnemyManager").CINDER, main.get_node("EnemyManager").GUARD, main.get_node("EnemyManager").WORKER, main.furnace_tyrant_scene]:
		var enemy := scene.instantiate() as Node2D
		main.get_node("Entities").add_child(enemy)
		enemy.set_process(false)
		for action: String in ART.ACTORS[enemy.ACTOR_NAMES[enemy.kind]]:
			if action == "size":
				continue
			enemy.set_action(action, 1)
			enemy.update_animation(0.51)
			assert(enemy.sprite.texture is AtlasTexture)
			assert(not enemy.sprite.region_enabled)
			assert(enemy.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
		assert(enemy.sprite.material is ShaderMaterial)
		enemy.sprite.material.set_shader_parameter("lerp_percent", 1.0)
		enemy.queue_free()
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	print("FORGE_SPRITE_INTEGRATION_OK: all actor actions use generated frames, nearest filtering, hit flash retained")
	get_tree().quit()
