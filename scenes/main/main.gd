extends Node


const PREVIOUS_BOSS_RESPAWN_TIME := 3.0 * 60.0
const CURRENT_BOSS_SPAWN_TIME := 6.0 * 60.0
const ENDLESS_BOSS_INTERVAL := 60.0
const ENDLESS_INITIAL_SKILL_CHOICES := 10

@export var end_screen_scene: PackedScene

var paused_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var character_select_scene = preload("res://scenes/ui/character_select.tscn")
var slime_king_scene = preload("res://scenes/game_object/slime_king/slime_king.tscn")
var lightning_knight_scene = preload("res://scenes/game_object/lightning_knight/lightning_knight.tscn")
var iron_arm_miner_scene = preload("res://scenes/game_object/iron_arm_miner/iron_arm_miner.tscn")
var waiting_for_entrance := false
var level_2_started := false
var entrance_spawned := false
var current_level := 1
var previous_boss_respawned := false
var current_level_boss_started := false
var next_endless_boss_time := ENDLESS_BOSS_INTERVAL


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
	%Player.health_component.died.connect(on_player_died)
	$UpgradeManager.initial_choices_completed.connect(on_initial_choices_completed)
	$CheatUI/LearnSkillButton.pressed.connect(on_learn_skill_button_pressed)
	$CheatUI/SpawnBossButton.pressed.connect(on_spawn_boss_button_pressed)
	$CheatUI/SpawnLightningKnightButton.pressed.connect(spawn_lightning_knight)
	$CheatUI/SpawnIronArmMinerButton.pressed.connect(spawn_iron_arm_miner)
	$CheatUI/SpawnRandomEnemiesButton.pressed.connect($EnemyManager.spawn_test_enemies.bind(20))
	$CheatUI/LevelSelect.item_selected.connect(on_test_level_selected)
	if GameEvents.is_endless_mode():
		$EnemyManager.stop_spawning()
	show_character_select()


func show_character_select() -> void:
	var character_select: Node = character_select_scene.instantiate()
	character_select.connect("character_selected", on_character_selected)
	add_child(character_select)


func on_character_selected(character: Resource) -> void:
	%Player.set_character(character)
	if GameEvents.is_endless_mode():
		begin_endless_mode()
		$UpgradeManager.start_initial_choices(ENDLESS_INITIAL_SKILL_CHOICES)
	else:
		$UpgradeManager.start_initial_choices()


func begin_endless_mode() -> void:
	match randi_range(1, 3):
		1:
			begin_level_1()
		2:
			begin_level_2()
		3:
			begin_level_3()
	$EnemyManager.start_endless()
	$EnemyManager.stop_spawning()
	next_endless_boss_time = ENDLESS_BOSS_INTERVAL


func on_initial_choices_completed() -> void:
	if GameEvents.is_endless_mode():
		$EnemyManager.resume_spawning()



func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		add_child(paused_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()


func on_player_died():
	var end_screen_instance = end_screen_scene.instantiate() as EndScreen
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()


func on_learn_skill_button_pressed() -> void:
	$UpgradeManager.show_upgrade_choices(3)


func on_spawn_boss_button_pressed() -> void:
	spawn_boss_for_level(current_level)


func on_test_level_selected(index: int) -> void:
	match index:
		0:
			begin_level_1()
		1:
			begin_level_2()
		2:
			begin_level_3()


func _process(_delta: float) -> void:
	var time_elapsed: float = $ArenaTimeManager.get_time_elapsed()
	if GameEvents.is_endless_mode():
		while time_elapsed >= next_endless_boss_time:
			spawn_boss_for_level(randi_range(1, 3))
			next_endless_boss_time += ENDLESS_BOSS_INTERVAL
		return
	if current_level >= 2 and not previous_boss_respawned and time_elapsed >= PREVIOUS_BOSS_RESPAWN_TIME:
		previous_boss_respawned = true
		spawn_boss_for_level(current_level - 1)
	if not current_level_boss_started and time_elapsed >= CURRENT_BOSS_SPAWN_TIME:
		current_level_boss_started = true
		waiting_for_entrance = current_level < 3
		$EnemyManager.stop_spawning()
		spawn_boss_for_level(current_level)

	if waiting_for_entrance and not entrance_spawned and get_tree().get_nodes_in_group("enemy").is_empty():
		spawn_level_entrance()


func spawn_slime_king() -> Node2D:
	return spawn_boss(slime_king_scene)


func spawn_lightning_knight() -> Node2D:
	return spawn_boss(lightning_knight_scene)


func spawn_iron_arm_miner() -> Node2D:
	return spawn_boss(iron_arm_miner_scene)


func spawn_boss(boss_scene: PackedScene) -> Node2D:
	var boss := boss_scene.instantiate() as Node2D
	if GameEvents.is_endless_mode():
		$EnemyManager.apply_endless_boss_difficulty(boss)
		var health := boss.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.died.connect(on_endless_boss_died)
	$Entities.add_child(boss)
	boss.global_position = $EnemyManager.get_spawn_position()
	return boss


func spawn_boss_for_level(level: int) -> Node2D:
	match level:
		1:
			return spawn_slime_king()
		2:
			return spawn_lightning_knight()
		3:
			return spawn_iron_arm_miner()
	return null


func on_endless_boss_died() -> void:
	$UpgradeManager.show_upgrade_choices(3)


func spawn_level_entrance() -> void:
	waiting_for_entrance = false
	entrance_spawned = true
	var entrance := LevelEntrance.new()
	$Entities.add_child(entrance)
	entrance.global_position = %Player.global_position + Vector2(72, 0)
	var label := Label.new()
	label.text = "第%d关入口" % (current_level + 1)
	label.position = Vector2(-32, -36)
	entrance.add_child(label)
	while is_instance_valid(entrance) and %Player.global_position.distance_to(entrance.global_position) > 24.0:
		await get_tree().process_frame
	if current_level == 1:
		begin_level_2()
	else:
		begin_level_3()
	entrance.queue_free()


func begin_level_2() -> void:
	level_2_started = true
	begin_level(2)
	$MineMap.hide()
	$TileMap.show()
	$TileMap.modulate = Color(0.82, 0.72, 0.96)
	$EnemyManager.start_level_2()


func begin_level_1() -> void:
	level_2_started = false
	begin_level(1)
	$MineMap.hide()
	$TileMap.show()
	$TileMap.modulate = Color.WHITE
	$EnemyManager.start_level_1()


func begin_level_3() -> void:
	begin_level(3)
	$TileMap.show()
	$TileMap.modulate = Color("c69048")
	$MineMap.show()
	$EnemyManager.start_level_3()


func begin_level(level: int) -> void:
	current_level = level
	previous_boss_respawned = false
	current_level_boss_started = false
	$ArenaTimeManager.time_elapsed = 0.0
	$ArenaTimeManager.arena_difficulty = 0
	GameEvents.arena_difficulty = 0
	if current_level >= 2 and not GameEvents.is_endless_mode():
		spawn_boss_for_level(current_level - 1)
