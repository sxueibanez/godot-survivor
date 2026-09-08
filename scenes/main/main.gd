extends Node


const LEVEL_1_DURATION := 6.0 * 60.0

@export var end_screen_scene: PackedScene

var paused_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var slime_king_scene = preload("res://scenes/game_object/slime_king/slime_king.tscn")
var waiting_for_entrance := false
var level_2_started := false
var entrance_spawned := false
var level_1_boss_started := false


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
	$CheatUI/LearnSkillButton.pressed.connect(on_learn_skill_button_pressed)
	$CheatUI/SpawnBossButton.pressed.connect(on_spawn_boss_button_pressed)



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
	spawn_slime_king()


func _process(_delta: float) -> void:
	if not level_1_boss_started and not level_2_started and $ArenaTimeManager.get_time_elapsed() >= LEVEL_1_DURATION:
		level_1_boss_started = true
		waiting_for_entrance = true
		$EnemyManager.stop_spawning()
		spawn_slime_king()

	if waiting_for_entrance and not entrance_spawned and get_tree().get_nodes_in_group("enemy").is_empty():
		spawn_level_entrance()


func spawn_slime_king() -> void:
	if !get_tree().get_nodes_in_group("boss").is_empty():
		return
	var slime_king: Node2D = slime_king_scene.instantiate() as Node2D
	$Entities.add_child(slime_king)
	slime_king.global_position = $EnemyManager.get_spawn_position()


func spawn_level_entrance() -> void:
	waiting_for_entrance = false
	entrance_spawned = true
	var entrance := LevelEntrance.new()
	$Entities.add_child(entrance)
	entrance.global_position = %Player.global_position + Vector2(72, 0)
	var label := Label.new()
	label.text = "第二关入口"
	label.position = Vector2(-32, -36)
	entrance.add_child(label)
	while is_instance_valid(entrance) and %Player.global_position.distance_to(entrance.global_position) > 24.0:
		await get_tree().process_frame
	begin_level_2()
	entrance.queue_free()


func begin_level_2() -> void:
	level_2_started = true
	$TileMap.modulate = Color(0.82, 0.72, 0.96)
	$ArenaTimeManager.time_elapsed = 0.0
	$ArenaTimeManager.arena_difficulty = 0
	GameEvents.arena_difficulty = 0
	$EnemyManager.start_level_2()
