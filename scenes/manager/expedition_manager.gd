extends Node

const WAVE_DURATION := 35.0
const INITIAL_CHOICES := 3
const BOSS_BASE_HEALTH := 750.0
const BOSS_HEALTH_GROWTH := 0.55
const CONTRACTS := [
	{"id": "fury", "text": "[1] 狂战契约：伤害 ×1.25，受到伤害 ×1.20"},
	{"id": "bulwark", "text": "[2] 血肉堡垒：最大生命 ×1.30，伤害 ×0.85"},
	{"id": "hunter", "text": "[3] 猎手之约：移速 ×1.20，最大生命 ×0.88"},
	{"id": "supply", "text": "[4] 补给整备：恢复35%最大生命，并多选一次升级"},
	{"id": "blood", "text": "[5] 饮血契约：吸血 +5%，最大生命 ×0.80"},
	{"id": "sacrifice", "text": "[6] 绝境献祭：消耗40%当前生命，伤害 ×1.40"},
]
enum Stage { CHARACTER, INITIAL, WAVE, BOSS, CLEARING, CONTRACT, REWARD, FINISHED }

var main: Node
var stage := Stage.CHARACTER
var maps: Array[int] = [1, 2, 3, 4, 5]
var patterns: Array[String] = ["rush", "ranged", "swift", "rush", "ranged"]
var wave_pattern := ""
var room_index := 0
var defeated_bosses := 0
var selected_contracts: Array[String] = []
var active_boss: Node2D
var contract_screen: CanvasLayer
var status: Label
var extra_upgrade_pending := false


func _ready() -> void:
	main = get_parent()
	maps.shuffle()
	patterns.shuffle()
	main.get_node("EnemyManager").stop_spawning()
	main.get_node("ArenaTimeManager").set_process(false)
	main.challenges.stop_challenges()
	main.get_node("CheatUI").hide()
	main.get_node("UpgradeManager").choices_finished.connect(on_choices_finished)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	status = Label.new()
	hud.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -175.0
	status.offset_right = -12.0
	status.offset_top = 10.0
	status.offset_bottom = 32.0
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_constant_override("outline_size", 3)
	status.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.1))
	status.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	status.text = "深渊远征：选择角色"


func start() -> void:
	if stage != Stage.CHARACTER:
		return
	stage = Stage.INITIAL
	main.get_node("UpgradeManager").start_initial_choices(INITIAL_CHOICES)


func on_choices_finished() -> void:
	if stage == Stage.INITIAL:
		start_room()
	elif stage == Stage.REWARD:
		if extra_upgrade_pending:
			extra_upgrade_pending = false
			show_upgrade_or_continue()
		else:
			start_room()


func start_room() -> void:
	if stage not in [Stage.INITIAL, Stage.REWARD]:
		return
	if not player_alive():
		return
	get_tree().paused = false
	stage = Stage.WAVE
	var map_id := maps[room_index]
	main.completed_maps = room_index
	GameEvents.campaign_completed_maps = room_index
	main.current_level = room_index + 1
	main.previous_map_id = main.current_map_id
	main.current_map_id = map_id
	main.show_map(map_id)
	MusicPlayer.play_level(map_id)
	var clock := main.get_node("ArenaTimeManager") as ArenaTimeManager
	clock.time_elapsed = 0.0
	clock.arena_difficulty = 0
	GameEvents.arena_difficulty = 0
	clock.set_process(true)
	wave_pattern = patterns[room_index]
	GameEvents.expedition_enemy_speed_multiplier = 1.35 if wave_pattern == "swift" else 1.0
	main.start_enemy_wave_for_map(map_id)
	var spawner: Node = main.get_node("EnemyManager")
	if wave_pattern == "rush":
		spawner.base_spawn_time *= 0.65
		spawner.timer.start(spawner.base_spawn_time)
	elif wave_pattern == "ranged":
		spawner.enemy_table.add_item(spawner.ranged_enemy_scene, 30)
	main.get_node("ArenaTimeUI").map_name = "远征 %d/5 · %s" % [room_index + 1, main.get_node("ArenaTimeUI").MAP_NAMES[map_id - 1]]
	update_status()


func _process(_delta: float) -> void:
	if stage == Stage.WAVE:
		if not player_alive():
			return
		if main.get_node("ArenaTimeManager").get_time_elapsed() >= WAVE_DURATION:
			start_boss()
		update_status()


func update_status() -> void:
	if stage == Stage.WAVE:
		var remaining := maxf(WAVE_DURATION - main.get_node("ArenaTimeManager").get_time_elapsed(), 0.0)
		var pattern_name: String = {"rush": "狂潮", "ranged": "弹雨", "swift": "迅捷"}.get(wave_pattern, "怪潮")
		status.text = "%s · 首领 %d 秒" % [pattern_name, ceili(remaining)]
	elif stage == Stage.BOSS:
		status.text = "击败守关首领"
	elif stage == Stage.CONTRACT:
		status.text = "选择远征契约"
	elif stage == Stage.FINISHED:
		status.text = ""


func start_boss() -> void:
	if stage != Stage.WAVE or not player_alive():
		return
	main.get_node("EnemyManager").stop_spawning()
	var boss: Node2D = main.spawn_boss_for_map(maps[room_index])
	if boss == null:
		return
	active_boss = boss
	var health := boss.get_node("HealthComponent") as HealthComponent
	health.max_health = BOSS_BASE_HEALTH * (1.0 + room_index * BOSS_HEALTH_GROWTH) * MetaProgression.get_enemy_health_multiplier()
	health.current_health = health.max_health
	health.health_changed.emit()
	health.died.connect(on_boss_died, CONNECT_ONE_SHOT)
	stage = Stage.BOSS
	update_status()


func on_boss_died() -> void:
	if stage != Stage.BOSS or not player_alive():
		return
	stage = Stage.CLEARING
	defeated_bosses += 1
	main.get_node("ArenaTimeManager").set_process(false)
	clear_enemies_and_projectiles()
	var upgrades: Node = main.get_node("UpgradeManager")
	while upgrades.choice_screen_open and player_alive() and stage == Stage.CLEARING:
		await get_tree().process_frame
	if stage != Stage.CLEARING or not player_alive():
		return
	get_tree().paused = true
	if room_index >= maps.size() - 1:
		finish_victory()
	else:
		show_contracts()


func clear_enemies_and_projectiles() -> void:
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_queued_for_deletion():
			enemy.queue_free()
	for projectile: Node in main.get_node("EnemyProjectiles").get_children():
		projectile.queue_free()


func show_contracts() -> void:
	stage = Stage.CONTRACT
	update_status()
	contract_screen = CanvasLayer.new()
	contract_screen.layer = 40
	contract_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(contract_screen)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contract_screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 520.0
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "第 %d 站完成 · 选择契约（效果持续本局）" % (room_index + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var hint := Label.new()
	hint.text = "每站追加升级；契约可重复选择，数值相乘"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	box.add_child(hint)
	for index in CONTRACTS.size():
		var button := preload("res://scenes/ui/sound_button.tscn").instantiate() as Button
		button.text = CONTRACTS[index]["text"]
		button.add_theme_font_size_override("font_size", 12)
		var shortcut := Shortcut.new()
		var key := InputEventKey.new()
		key.keycode = KEY_1 + index
		shortcut.events.append(key)
		button.shortcut = shortcut
		button.pressed.connect(choose_contract.bind(str(CONTRACTS[index]["id"])))
		box.add_child(button)
	(box.get_child(2) as Button).grab_focus.call_deferred()


func choose_contract(id: String) -> void:
	if stage != Stage.CONTRACT or not player_alive():
		return
	if id not in ["fury", "bulwark", "hunter", "supply", "blood", "sacrifice"]:
		return
	stage = Stage.REWARD
	selected_contracts.append(id)
	var player: Node = main.get_node("Entities/Player")
	match id:
		"fury":
			GameEvents.expedition_damage_multiplier *= 1.25
			GameEvents.expedition_incoming_multiplier *= 1.20
		"bulwark":
			GameEvents.expedition_health_multiplier *= 1.30
			GameEvents.expedition_damage_multiplier *= 0.85
		"hunter":
			GameEvents.expedition_speed_multiplier *= 1.20
			GameEvents.expedition_health_multiplier *= 0.88
		"supply":
			player.health_component.heal(player.health_component.max_health * 0.35, "boss_reward")
			extra_upgrade_pending = true
		"blood":
			GameEvents.life_steal_percent += 0.05
			GameEvents.expedition_health_multiplier *= 0.80
		"sacrifice":
			player.health_component.spend_health(player.health_component.current_health * 0.40)
			GameEvents.expedition_damage_multiplier *= 1.40
	player.refresh_support_stats()
	player.refresh_missing_health_passive()
	contract_screen.hide()
	contract_screen.queue_free()
	room_index += 1
	get_tree().paused = false
	show_upgrade_or_continue()


func show_upgrade_or_continue() -> void:
	var upgrades: Node = main.get_node("UpgradeManager")
	upgrades.show_upgrade_choices(3)
	if not upgrades.choice_screen_open:
		if extra_upgrade_pending:
			extra_upgrade_pending = false
		start_room()


func finish_victory() -> void:
	if stage != Stage.CLEARING:
		return
	stage = Stage.FINISHED
	update_status()
	var screen: EndScreen = main.end_screen_scene.instantiate()
	main.add_child(screen)
	describe_result(screen)
	screen.play_jingle()
	MetaProgression.save()


func describe_result(screen: EndScreen) -> void:
	screen.get_node("%DefeatReasonLabel").text += "\n深渊远征：击败 %d / %d 位守关首领 · 签订 %d 个契约" % [defeated_bosses, maps.size(), selected_contracts.size()]


func stop_for_defeat() -> void:
	stage = Stage.FINISHED
	extra_upgrade_pending = false
	if is_instance_valid(contract_screen):
		contract_screen.queue_free()
	update_status()


func player_alive() -> bool:
	var player := main.get_node_or_null("Entities/Player")
	return is_instance_valid(player) and not player.is_queued_for_deletion() and player.health_component.current_health > 0.0
