extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var player = load("res://scenes/game_object/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_character(load("res://resources/characters/ronin.tres"))
	var passive = player.character_passives
	assert(passive.skill_icon.visible)
	assert(passive.skill_icon.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(passive.skill_icon.tooltip_text == "%s\n%s" % [player.character.display_name, player.character.passive_description])
	assert(passive.status.text.is_empty())
	assert(passive.cooldown_label.text == "就绪")
	passive.dash_cooldown_left = 2.5
	passive.update_status()
	assert(passive.cooldown_label.text == "2.5")
	await process_frame
	var viewport_rect := root.get_visible_rect()
	assert(viewport_rect.encloses(passive.skill_icon.get_global_rect()))
	assert(viewport_rect.encloses(passive.cooldown_label.get_global_rect()))
	assert(viewport_rect.encloses(passive.status.get_global_rect()))
	player.set_character(load("res://resources/characters/lone_gunner.tres"))
	passive.solitude_multiplier = 1.32
	passive.danger_cooldown_left = 1.0
	passive.update_status()
	assert(passive.status.text == "远程 +32%")
	assert(passive.cooldown_label.text == "1.0")
	player.set_character(load("res://resources/characters/avenger.tres"))
	assert(passive.cooldown_label.text == "被动")
	for character_id in ["warrior", "elf_ranger", "blooddrinker"]:
		player.set_character(load("res://resources/characters/%s.tres" % character_id))
		assert(passive.skill_icon.visible)
		assert(passive.skill_icon.texture != null)
		assert(passive.cooldown_label.text == "被动")
		assert(not player.character.passive_description.is_empty())
		assert(passive.skill_icon.tooltip_text == "%s\n%s" % [player.character.display_name, player.character.passive_description])
	var bomber = load("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn").instantiate()
	root.add_child(bomber)
	bomber._process(0.0)
	assert(bomber.charging)
	bomber._process(0.5)
	assert(is_equal_approx(bomber.charge_time, 0.5))
	player.queue_free()
	bomber.queue_free()
	await process_frame
	quit()
