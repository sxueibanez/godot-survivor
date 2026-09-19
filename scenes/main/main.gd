extends Node


const CURRENT_BOSS_SPAWN_TIME := 3.0 * 60.0
const ENDLESS_BOSS_INTERVAL := 60.0
const ENDLESS_INITIAL_SKILL_CHOICES := 5
const MAP_COUNT := 5

@export var end_screen_scene: PackedScene

var paused_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var character_select_scene = preload("res://scenes/ui/character_select.tscn")
var slime_king_scene = preload("res://scenes/game_object/slime_king/slime_king.tscn")
var lightning_knight_scene = preload("res://scenes/game_object/lightning_knight/lightning_knight.tscn")
var iron_arm_miner_scene = preload("res://scenes/game_object/iron_arm_miner/iron_arm_miner.tscn")
var frost_queen_scene = preload("res://scenes/game_object/frost_queen/frost_queen.tscn")
var furnace_tyrant_scene = preload("res://scenes/game_object/furnace_tyrant/furnace_tyrant.tscn")
var waiting_for_entrance := false
var level_2_started := false
var entrance_spawned := false
var current_level := 1
var completed_maps := 0
var current_map_id := 0
var previous_map_id := 0
var challenges: Node
var boss_rush: Node
var current_level_boss_started := false
var next_endless_boss_time := ENDLESS_BOSS_INTERVAL
var map_order := [1, 2, 3, 4, 5]
var forge_map: Node2D
var death_sequence_running := false
var curse_manager: CurseManager
var current_boss_spawn_time := CURRENT_BOSS_SPAWN_TIME


class LevelEntrance extends Node2D:
	var pulse := 0.0

	func _process(delta: float) -> void:
		pulse += delta * 4.0
		queue_redraw()

	func _draw() -> void:
		var radius := 17.0 + sin(pulse) * 2.0
		draw_circle(Vector2.ZERO, radius + 5.0, Color(0.82, 0.55, 1.0, 0.22))
		draw_circle(Vector2.ZERO, radius, Color(0.26, 0.08, 0.42, 0.95))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.94, 0.76, 1.0), 2.0)


func _ready():
	forge_map = preload("res://scenes/environment/level_5_forge.gd").new()
	forge_map.name = "ForgeMap"
	forge_map.z_index = -100
	add_child(forge_map)
	move_child(forge_map, $Entities.get_index())
	$CheatUI/LevelSelect.add_item("熔火铸炉", 5)
	var forge_button := preload("res://scenes/ui/sound_button.tscn").instantiate() as Button
	forge_button.text = "熔炉暴君"
	forge_button.focus_mode = Control.FOCUS_NONE
	forge_button.position = Vector2(494, 306)
	forge_button.size = Vector2(68, 18)
	forge_button.add_theme_font_size_override("font_size", 8)
	forge_button.pressed.connect(spawn_furnace_tyrant)
	$CheatUI.add_child(forge_button)
	GameEvents.campaign_completed_maps = 0
	%Player.health_component.died.connect(on_player_died)
	$UpgradeManager.initial_choices_completed.connect(on_initial_choices_completed)
	$CheatUI/LearnSkillButton.pressed.connect(on_learn_skill_button_pressed)
	$CheatUI/SpawnBossButton.pressed.connect(spawn_slime_king)
	$CheatUI/SpawnLightningKnightButton.pressed.connect(spawn_lightning_knight)
	$CheatUI/SpawnIronArmMinerButton.pressed.connect(spawn_iron_arm_miner)
	$CheatUI/SpawnFrostQueenButton.pressed.connect(spawn_frost_queen)
	$CheatUI/SpawnRandomEnemiesButton.pressed.connect($EnemyManager.spawn_test_enemies.bind(20))
	$CheatUI/LevelSelect.item_selected.connect(on_test_level_selected)
	challenges = preload("res://scenes/manager/challenge_manager.gd").new()
	add_child(challenges)
	if GameEvents.game_mode == "boss_rush":
		boss_rush = preload("res://scenes/manager/boss_rush_manager.gd").new()
		add_child(boss_rush)
	elif GameEvents.is_endless_mode():
		$EnemyManager.stop_spawning()
	else:
		map_order.shuffle()
	if GameEvents.game_mode in ["campaign", "endless"]:
		curse_manager = preload("res://scenes/manager/curse_manager.gd").new()
		add_child(curse_manager)
		curse_manager.setup(self)
	show_character_select()


func show_character_select() -> void:
	var character_select: Node = character_select_scene.instantiate()
	character_select.connect("character_selected", on_character_selected)
	add_child(character_select)


func on_character_selected(character: Resource) -> void:
	%Player.set_character(character)
	if boss_rush != null:
		boss_rush.start()
	elif GameEvents.is_endless_mode():
		begin_endless_mode()
		$UpgradeManager.start_initial_choices(ENDLESS_INITIAL_SKILL_CHOICES)
	else:
		completed_maps = 0
		begin_level_1()
		$UpgradeManager.start_initial_choices()


func begin_endless_mode() -> void:
	begin_level(1, randi_range(1, MAP_COUNT))
	$EnemyManager.level = current_map_id
	$EnemyManager.start_endless()
	$EnemyManager.stop_spawning()
	next_endless_boss_time = ENDLESS_BOSS_INTERVAL


func on_initial_choices_completed() -> void:
	if GameEvents.is_endless_mode():
		$EnemyManager.resume_spawning()
	if curse_manager != null:
		curse_manager.start()



func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		add_child(paused_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()


func on_player_died() -> void:
	if death_sequence_running:
		return
	death_sequence_running = true
	set_process(false)
	if curse_manager != null:
		curse_manager.set_process(false)
	$EnemyManager.stop_spawning()
	$ArenaTimeManager.set_process(false)
	if challenges != null:
		challenges.stop_challenges()
	var player := %Player as CharacterBody2D
	player.set_process(false)
	player.set_physics_process(false)
	player.collision_layer = 0
	player.collision_mask = 0
	var death_overlay := create_death_overlay()
	var reason := death_overlay.get_node("DefeatReason") as Label
	var original_time_scale := Engine.time_scale
	Engine.time_scale = 0.03
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 0.3
	play_player_dissolve(player)
	await get_tree().create_timer(0.85, true, false, true).timeout
	reason.text = "被%s击败" % GameEvents.last_damage_source
	reason.show()
	await get_tree().create_timer(0.5, true, false, true).timeout
	Engine.time_scale = original_time_scale
	death_overlay.queue_free()
	if boss_rush != null:
		boss_rush.finish(false)
		return
	var end_screen_instance = end_screen_scene.instantiate() as EndScreen
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()


func create_death_overlay() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 60
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.75, 0.03, 0.04, 0.32)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	var flash_tween := flash.create_tween().set_ignore_time_scale(true)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3)
	var reason := Label.new()
	reason.name = "DefeatReason"
	reason.hide()
	reason.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reason.offset_left = -220.0
	reason.offset_top = -24.0
	reason.offset_right = 220.0
	reason.offset_bottom = 24.0
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reason.add_theme_font_size_override("font_size", 22)
	reason.add_theme_constant_override("outline_size", 5)
	reason.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.07))
	layer.add_child(reason)
	return layer


func play_player_dissolve(player: Node2D) -> void:
	var particles := CPUParticles2D.new()
	particles.process_mode = Node.PROCESS_MODE_ALWAYS
	particles.amount = 42
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(10, 14)
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 16.0
	particles.initial_velocity_max = 35.0
	particles.gravity = Vector2(0, 18)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = Color(0.75, 0.45, 1.0)
	particles.position = Vector2(0, -7)
	player.add_child(particles)
	particles.emitting = true
	var visuals := player.get_node("Visuals") as Node2D
	var dissolve := visuals.create_tween().set_parallel(true).set_ignore_time_scale(true)
	dissolve.tween_property(visuals, "modulate", Color(1.0, 0.25, 0.3, 0.0), 0.85)
	dissolve.tween_property(visuals, "scale", visuals.scale * 0.35, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func on_learn_skill_button_pressed() -> void:
	$UpgradeManager.show_upgrade_choices(3)


func on_test_level_selected(index: int) -> void:
	begin_level(current_level, index + 1)
	if GameEvents.is_endless_mode():
		$EnemyManager.level = current_map_id
		$EnemyManager.start_endless()


func _process(_delta: float) -> void:
	if boss_rush != null:
		return
	var time_elapsed: float = $ArenaTimeManager.get_time_elapsed()
	if GameEvents.is_endless_mode():
		while time_elapsed >= next_endless_boss_time:
			spawn_boss_for_map(randi_range(1, MAP_COUNT))
			next_endless_boss_time += ENDLESS_BOSS_INTERVAL
		return
	if not current_level_boss_started and time_elapsed >= current_boss_spawn_time:
		current_level_boss_started = true
		waiting_for_entrance = true
		$EnemyManager.stop_spawning()
		challenges.spawn_scheduled_bosses()

	if waiting_for_entrance and not entrance_spawned and get_tree().get_nodes_in_group("enemy").is_empty():
		spawn_level_entrance()


func spawn_slime_king() -> Node2D:
	return spawn_boss(slime_king_scene)


func spawn_lightning_knight() -> Node2D:
	return spawn_boss(lightning_knight_scene)


func spawn_iron_arm_miner() -> Node2D:
	return spawn_boss(iron_arm_miner_scene)


func spawn_frost_queen() -> Node2D:
	return spawn_boss(frost_queen_scene)


func spawn_furnace_tyrant() -> Node2D:
	return spawn_boss(furnace_tyrant_scene)


func spawn_boss(boss_scene: PackedScene) -> Node2D:
	if boss_rush != null and not boss_rush.spawning_boss:
		return null
	if not GameEvents.can_spawn_enemy(true):
		return null
	var boss := boss_scene.instantiate() as Node2D
	if boss_rush != null:
		boss.get_node("HealthComponent").max_health = boss_rush.BOSS_HEALTH[boss_rush.round_index]
	if GameEvents.is_endless_mode():
		$EnemyManager.apply_endless_boss_difficulty(boss)
		var health := boss.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.died.connect(on_endless_boss_died)
	$Entities.add_child(boss)
	boss.global_position = $EnemyManager.get_boss_spawn_position()
	return boss


func spawn_boss_for_map(map_id: int) -> Node2D:
	match map_id:
		1:
			return spawn_slime_king()
		2:
			return spawn_lightning_knight()
		3:
			return spawn_iron_arm_miner()
		4:
			return spawn_frost_queen()
		5:
			return spawn_furnace_tyrant()
	return null


func on_endless_boss_died() -> void:
	$UpgradeManager.show_upgrade_choices(3)


func advance_current_boss(seconds: float) -> void:
	if GameEvents.is_endless_mode():
		next_endless_boss_time = maxf($ArenaTimeManager.get_time_elapsed(), next_endless_boss_time - seconds)
	elif not current_level_boss_started:
		current_boss_spawn_time = maxf(0.0, current_boss_spawn_time - seconds)


func spawn_level_entrance() -> void:
	var player := get_node_or_null("Entities/Player") as Node2D
	if entrance_spawned or player == null:
		return
	waiting_for_entrance = false
	entrance_spawned = true
	completed_maps += 1
	var entrance := LevelEntrance.new()
	$Entities.add_child(entrance)
	entrance.global_position = player.global_position + Vector2(72, 0)
	if forge_map.active:
		entrance.global_position = forge_map.safe_position(entrance.global_position)
	var label := Label.new()
	label.text = "第%d关入口" % (completed_maps + 1)
	label.position = Vector2(-32, -36)
	entrance.add_child(label)
	while is_instance_valid(entrance) and is_instance_valid(player) and player.global_position.distance_to(entrance.global_position) > 24.0:
		await get_tree().process_frame
	if not is_instance_valid(player) or not is_instance_valid(entrance):
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if player.is_queued_for_deletion() or health == null or health.current_health <= 0:
		entrance.queue_free()
		return
	begin_level(completed_maps + 1)
	entrance.queue_free()


func begin_level_2() -> void:
	level_2_started = true
	begin_level(2)


func begin_level_1() -> void:
	level_2_started = false
	begin_level(1)


func begin_level_3() -> void:
	begin_level(3)


func begin_level_4() -> void:
	begin_level(4)


func begin_level_5() -> void:
	begin_level(5, 5)


func begin_level(level: int, forced_map_id: int = 0) -> void:
	GameEvents.campaign_completed_maps = completed_maps
	previous_map_id = current_map_id
	current_level = level
	waiting_for_entrance = false
	entrance_spawned = false
	current_map_id = forced_map_id if forced_map_id > 0 else (map_order[level - 1] if level <= map_order.size() else randi_range(1, MAP_COUNT))
	show_map(current_map_id)
	MusicPlayer.play_level(current_map_id)
	current_level_boss_started = false
	current_boss_spawn_time = CURRENT_BOSS_SPAWN_TIME
	$ArenaTimeManager.time_elapsed = 0.0
	$ArenaTimeManager.arena_difficulty = 0
	GameEvents.arena_difficulty = 0
	if not GameEvents.is_endless_mode():
		start_enemy_wave_for_map(current_map_id)
	challenges.reset_challenges()
	if curse_manager != null:
		curse_manager.on_map_changed()


func start_enemy_wave_for_map(map_id: int) -> void:
	match map_id:
		1:
			$EnemyManager.start_level_1()
		2:
			$EnemyManager.start_level_2()
		3:
			$EnemyManager.start_level_3()
		4:
			$EnemyManager.start_level_4()
		5:
			$EnemyManager.start_level_5()


func show_map(map_id: int) -> void:
	var was_forge: bool = forge_map.active
	forge_map.activate(map_id == 5)
	for layer in $TileMap.get_layers_count():
		$TileMap.set_layer_enabled(layer, map_id != 5)
	if map_id == 5 and not was_forge:
		%Player.global_position = forge_map.CENTER
		%Player.velocity = Vector2.ZERO
	elif was_forge and map_id != 5:
		# The forge is larger than the shared arena; don't retain an outside position.
		%Player.global_position = Vector2(384, 384)
		%Player.velocity = Vector2.ZERO
	$ArenaTimeUI.set_map(map_id)
	$TileMap.show()
	$TileMap.visible = map_id != 5
	$MineMap.visible = map_id == 3
	$IceMap.visible = map_id == 4
	match map_id:
		1:
			$TileMap.modulate = Color.WHITE
		2:
			$TileMap.modulate = Color(0.82, 0.72, 0.96)
		3:
			$TileMap.modulate = Color("c69048")
		4:
			$TileMap.modulate = Color("a8dff2")
