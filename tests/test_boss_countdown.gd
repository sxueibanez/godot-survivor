extends Node


class MockGameState extends Node:
	var current_map_id := 1
	var current_level_boss_started := false
	var current_boss_spawn_time := 180.0
	var next_endless_boss_time := 60.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var state := MockGameState.new()
	add_child(state)
	var clock := ArenaTimeManager.new()
	clock.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(clock)
	clock.set_process(false)
	var hud := preload("res://scenes/ui/arena_time_ui.tscn").instantiate()
	hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	hud.game_state = state
	hud.arena_time_manager = clock
	add_child(hud)
	GameEvents.game_mode = "campaign"
	clock.time_elapsed = 20.2
	hud._process(0.0)
	assert(hud.boss_countdown.visible and hud.boss_countdown.text == "Boss 来袭 2:40")
	clock.set_process(true)
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	assert(is_equal_approx(clock.time_elapsed, 20.2) and hud.boss_countdown.text == "Boss 来袭 2:40")
	get_tree().paused = false
	clock.set_process(false)
	hud.show_notification("测试提示")
	state.current_boss_spawn_time = 60.0
	hud._process(0.0)
	assert(hud.label.text == "测试提示" and hud.boss_countdown.text == "Boss 来袭 0:40")
	state.current_level_boss_started = true
	hud._process(0.0)
	assert(not hud.boss_countdown.visible)
	GameEvents.game_mode = "endless"
	clock.time_elapsed = 90.0
	state.next_endless_boss_time = 120.0
	hud._process(0.0)
	assert(hud.boss_countdown.visible and hud.boss_countdown.text == "Boss 来袭 0:30")
	clock.time_elapsed = 111.0
	hud._process(0.0)
	assert(hud.boss_countdown.get_theme_color("font_color") == Color(1.0, 0.38, 0.28))
	clock.time_elapsed = 90.0
	hud._process(0.0)
	assert(hud.boss_countdown.get_theme_color("font_color") == Color.WHITE)
	var boss := Node2D.new()
	boss.add_to_group("boss")
	add_child(boss)
	hud._process(0.0)
	assert(not hud.boss_countdown.visible)
	boss.free()
	GameEvents.game_mode = "boss_rush"
	hud._process(0.0)
	assert(not hud.boss_countdown.visible)
	print("BOSS_COUNTDOWN_OK")
	get_tree().quit()
