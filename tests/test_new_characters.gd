extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.reset_run_stats()
	GameEvents.game_mode = "endless"
	GameEvents.critical_disabled = true
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	add_child(foreground)
	var player := load("res://scenes/game_object/player/player.tscn").instantiate() as CharacterBody2D
	add_child(player)
	player.set_process(false)
	var passives := player.get_node("CharacterPassives") as CharacterPassives
	passives.set_process(false)
	var health := player.get_node("HealthComponent") as HealthComponent
	var gunner := load("res://resources/characters/lone_gunner.tres") as CharacterData
	player.call("set_character", gunner)
	GameEvents.weapon_types["sniper_rifle"] = Ability.WeaponType.RANGED
	GameEvents.weapon_types["sword"] = Ability.WeaponType.MELEE
	passives.scan_enemies()
	assert(is_equal_approx(float(GameEvents.get_critical_damage(10.0, "sniper_rifle")["damage"]), 14.0))
	assert(is_equal_approx(float(GameEvents.get_critical_damage(10.0, "sword")["damage"]), 10.0))
	var elite := make_enemy(Vector2(40, 0), true)
	passives.scan_enemies()
	assert(is_equal_approx(passives.solitude_multiplier, 1.32))
	passives.call("_process", 0.0)
	assert(passives.speed_multiplier == 1.5)
	passives.set_process(true)
	get_tree().paused = true
	var cooldown := passives.danger_cooldown_left
	await get_tree().process_frame
	assert(passives.danger_cooldown_left == cooldown)
	passives.set_process(false)
	get_tree().paused = false
	passives.call("_process", 2.0)
	assert(passives.speed_multiplier == 1.0)
	elite.position.x = 300.0
	passives.scan_enemies()
	elite.position.x = 40.0
	passives.scan_enemies()
	assert(passives.danger_boost_left == 0.0) # Re-entry during cooldown cannot trigger.
	elite.position.x = 300.0
	passives.scan_enemies()
	passives.call("_process", 11.0)
	elite.position.x = 40.0
	passives.scan_enemies()
	assert(passives.danger_boost_left > 0.0)

	var scholar := load("res://resources/characters/gambling_scholar.tres") as CharacterData
	player.call("set_character", scholar)
	health.current_health = 80.0
	health.set_shield(5.0)
	var experience := ExperienceManager.new()
	add_child(experience)
	var upgrades := load("res://scenes/manager/upgrade_manager.gd").new() as Node
	upgrades.experience_manager = experience
	upgrades.upgrade_screen_scene = load("res://scenes/ui/upgrade_screen.tscn")
	add_child(upgrades)
	upgrades.show_upgrade_choices(3)
	var screen := upgrades.get_child(0)
	assert(screen.health_reroll_button != null)
	screen.on_health_reroll_pressed()
	assert(is_equal_approx(health.current_health, 68.0))
	assert(health.shield == 5.0)
	assert(screen.card_container.get_child_count() == 3)
	screen.on_health_reroll_pressed()
	assert(is_equal_approx(health.current_health, 68.0))
	screen.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	upgrades.choice_screen_open = false
	upgrades.show_choices(upgrades.pick_upgrades(3))
	screen = upgrades.get_child(0)
	assert(screen.health_reroll_button == null) # Initial/challenge choices have no paid reroll.
	screen.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	health.current_health = 40.0
	var expected_health := minf(40.0 + health.max_health * scholar.elite_heal_fraction, health.max_health)
	var elite_health := elite.get_node("HealthComponent") as HealthComponent
	elite_health.damage(elite_health.max_health * 2.0)
	await get_tree().process_frame
	assert(is_equal_approx(health.current_health, expected_health))
	assert(not health.spend_health(health.current_health))
	assert(not health.spend_health(NAN))
	upgrades.queue_free()
	experience.queue_free()

	var ronin := load("res://resources/characters/ronin.tres") as CharacterData
	player.call("set_character", ronin)
	assert(passives.try_dash())
	assert(passives.dash_cooldown_left == 3.5)
	assert(passives.attack_bonus_left == 1.0)
	assert(not passives.try_dash())
	passives.move_dash(ronin.dash_duration)
	assert(passives.attack_bonus_left == ronin.dash_attack_window)
	var sword := load("res://resources/upgrades/sword.tres") as Ability
	player.call("on_ability_upgrade_added", sword, {})
	var sword_controller := player.get_node("Abilities").get_child(0)
	sword_controller.get_node("Timer").stop()
	sword_controller.set_process(false)
	sword_controller.on_timer_timeout()
	assert(passives.attack_bonus_left > 0.0) # No enemies: do not consume the next round.
	var enemy := make_enemy(player.position + Vector2(80, 0))
	sword_controller.attack_count = 3
	sword_controller.on_timer_timeout()
	assert(passives.attack_bonus_left > 0.0)
	var attacks := foreground.get_children()
	assert(attacks.size() == 3)
	for attack: Node in attacks:
		assert(is_equal_approx(attack.damage, sword_controller.base_damage * sword_controller.additional_damage_percent))
	GameEvents.critical_disabled = true
	for weapon_id: String in ["sword", "sniper_rifle", "bomb"]:
		assert(is_equal_approx(float(GameEvents.get_critical_damage(10.0, weapon_id)["damage"]), 20.0))
		assert(is_equal_approx(float(GameEvents.get_critical_damage(30.0, weapon_id)["damage"]), 40.0))
	GameEvents.critical_disabled = false
	GameEvents.critical_chance = 1.0
	assert(is_equal_approx(float(GameEvents.get_critical_damage(10.0)["damage"]), 30.0)) # Flat +10 after critical scaling.
	GameEvents.critical_disabled = true
	passives.attack_bonus_left = 0.1
	passives.call("_process", 0.2)
	assert(GameEvents.get_character_damage_bonus() == 0.0)
	assert(is_equal_approx(float(GameEvents.get_critical_damage(10.0)["damage"]), 10.0))
	passives.call("_process", 3.5)
	assert(passives.try_dash())
	enemy.queue_free()
	var blooddrinker := load("res://resources/characters/blooddrinker.tres") as CharacterData
	player.call("set_character", blooddrinker)
	health.current_health = health.max_health - 10.0
	player.call("refresh_missing_health_passive")
	assert(is_equal_approx(GameEvents.player_damage_multiplier, 1.015))
	assert(is_equal_approx(player.get_node("VelocityComponent").max_speed, player.base_speed + 1.5))

	var avenger := load("res://resources/characters/avenger.tres") as CharacterData
	player.call("set_character", avenger)
	health.set_shield(0.0)
	health.damage(40.0)
	assert(passives.frenzy_left == avenger.rage_duration)
	assert(passives.rage == 0.0)
	assert(is_equal_approx(health.temporary_shield, health.max_health * avenger.rage_shield_fraction))
	assert(passives.get_damage_multiplier("sword") == avenger.rage_damage_multiplier)
	health.damage(health.temporary_shield + 1.0)
	assert(passives.rage == 0.0)
	health.set_shield(12.0)
	health.call("_process", avenger.rage_duration)
	passives.call("_process", avenger.rage_duration)
	assert(health.temporary_shield == 0.0)
	assert(health.shield == 12.0)
	assert(passives.get_damage_multiplier("sword") == 1.0)
	health.damage(17.0)
	assert(passives.rage == 5.0)
	for data: CharacterData in [gunner, scholar, ronin, avenger]:
		assert(data.sprite.get_size() == Vector2(16, 16))
		assert(not data.custom_walk_animation)
	assert(InputMap.has_action("character_dash"))
	for character_id: String in ["warrior", "elf_ranger", "blooddrinker", "lone_gunner", "gambling_scholar", "ronin", "avenger"]:
		var data := load("res://resources/characters/%s.tres" % character_id) as CharacterData
		player.call("set_character", data)
		assert(player.get_node("Visuals").scale == Vector2(1.25, 1.25))
		assert(player.scale == Vector2.ONE) # Only artwork grows, not the physics body.
	var selection := (load("res://scenes/ui/character_select.tscn") as PackedScene).instantiate()
	add_child(selection)
	await get_tree().process_frame
	await get_tree().process_frame
	var panel := selection.get_child(0) as PanelContainer
	var scroll := panel.get_child(0) as ScrollContainer
	var list := scroll.get_child(0) as VBoxContainer
	assert(list.get_child_count() == 8) # Title and seven selectable characters.
	assert(list.get_combined_minimum_size().x <= panel.size.x)
	assert(scroll.get_v_scroll_bar().max_value > scroll.size.y)
	get_tree().paused = false
	selection.queue_free()
	await get_tree().process_frame
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	var cheat_ui := main.get_node("CheatUI")
	main.remove_child(cheat_ui)
	main.free()
	add_child(cheat_ui)
	await get_tree().process_frame
	for button: Button in cheat_ui.get_children():
		assert(button.focus_mode == Control.FOCUS_NONE)
		if button is OptionButton:
			continue
		player.call("set_character", ronin)
		var clicks := {"count": 0}
		button.pressed.connect(func(): clicks.count += 1)
		var point := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		get_viewport().push_input(motion, true)
		var mouse := InputEventMouseButton.new()
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		get_viewport().push_input(mouse, true)
		mouse = mouse.duplicate()
		mouse.pressed = false
		get_viewport().push_input(mouse, true)
		assert(clicks.count == 1)
		assert(not button.has_focus())
		var space := InputEventKey.new()
		space.keycode = KEY_SPACE
		space.physical_keycode = KEY_SPACE
		space.pressed = true
		get_viewport().push_input(space, true)
		space = space.duplicate()
		space.pressed = false
		get_viewport().push_input(space, true)
		assert(clicks.count == 1) # Space must not activate the last clicked test button.
		assert(passives.dash_left > 0.0)
	print("New character mechanics: PASS")
	for child: Node in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func make_enemy(position: Vector2, is_elite: bool = false) -> Node2D:
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	if is_elite:
		enemy.add_to_group("elite")
	add_child(enemy)
	enemy.position = position
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	enemy.add_child(health)
	health.owner = enemy
	return enemy
