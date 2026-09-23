extends Node

const INITIAL_UPGRADES := 5
const NEXT_ROUND_UPGRADES := 3
const BOSS_HEALTH := [800.0, 1000.0, 1200.0, 1400.0, 1600.0]
const BOSS_NAMES := ["史莱姆王", "雷电骑士", "铁臂矿工", "冰霜女王", "熔炉暴君"]
const WEAPON_UNLOCK_RULES := [
	{"weapon_id": "sword", "boss_map_id": 1, "unlocks": "axe"},
	{"weapon_id": "axe", "boss_map_id": 2, "unlocks": "laser_gun"},
	{"weapon_id": "laser_gun", "boss_map_id": 3, "unlocks": "lightning_whip"},
	{"weapon_id": "lightning_whip", "boss_map_id": 4, "unlocks": "bomb"},
	{"weapon_id": "bomb", "boss_map_id": 5, "unlocks": "thunder_orb_book"},
	{"weapon_id": "thunder_orb_book", "boss_map_id": 1, "unlocks": "azure_dragon"},
	{"weapon_id": "azure_dragon", "boss_map_id": 2, "unlocks": "nine_treasure_pagoda"},
	{"weapon_id": "nine_treasure_pagoda", "boss_map_id": 3, "unlocks": "heaven_shaking_hammer", "requires_equipped": true},
	{"weapon_id": "heaven_shaking_hammer", "boss_map_id": 4, "unlocks": "sniper_rifle"},
]
enum Stage { CHARACTER, INITIAL, FIGHT, CLEANUP, REWARD, REST, EXTRA, ROUND_COMPLETE, FINISHED }

var stage := Stage.CHARACTER
var round_index := 0
var round_number := 1
var remaining_bosses := 0
var pending_boss_maps: Array[int] = []
var dead_boss_ids: Dictionary = {}
var result_screen: EndScreen
var defeated_bosses := 0
var combat_time := 0.0
var spawning_boss := false
var active_boss: Node2D
var rest_screen: CanvasLayer
var main: Node


func _ready() -> void:
	main = get_parent()
	main.get_node("EnemyManager").stop_spawning()
	main.get_node("ArenaTimeManager").set_process(false)
	main.challenges.stop_challenges()
	main.get_node("CheatUI").hide()
	main.get_node("UpgradeManager").choices_finished.connect(on_choices_finished)


func start() -> void:
	if stage != Stage.CHARACTER:
		return
	stage = Stage.INITIAL
	GameEvents.arena_difficulty = 0
	main.current_map_id = 1
	main.show_map(1)
	main.get_node("UpgradeManager").start_initial_choices(INITIAL_UPGRADES)


func _process(delta: float) -> void:
	if stage == Stage.FIGHT:
		spawn_pending_bosses()
		combat_time += delta
		main.get_node("ArenaTimeManager").time_elapsed = combat_time


func on_choices_finished() -> void:
	match stage:
		Stage.INITIAL, Stage.EXTRA:
			start_fight()
		Stage.REWARD:
			show_rest()


func start_fight() -> void:
	if stage not in [Stage.INITIAL, Stage.EXTRA, Stage.REST]:
		return
	stage = Stage.FIGHT
	get_tree().paused = false
	main.current_map_id = round_index + 1
	main.show_map(round_index + 1)
	MusicPlayer.play_level(round_index + 1)
	var hud: Node = main.get_node("ArenaTimeUI")
	hud.map_name = "第%d轮 · 第 %d / %d 场 · %s" % [round_number, round_index + 1, BOSS_NAMES.size(), BOSS_NAMES[round_index]]
	remaining_bosses = round_number
	pending_boss_maps.clear()
	dead_boss_ids.clear()
	spawning_boss = true
	active_boss = main.spawn_boss_for_map(round_index + 1)
	assert(active_boss != null, "Boss rush failed to spawn boss")
	active_boss.get_node("HealthComponent").died.connect(on_boss_died.bind(active_boss, round_index + 1), CONNECT_ONE_SHOT)
	var other_maps: Array[int] = []
	for extra in round_number - 1:
		if other_maps.is_empty():
			other_maps.assign(range(1, BOSS_NAMES.size() + 1))
			other_maps.erase(round_index + 1)
			other_maps.shuffle()
		pending_boss_maps.append(other_maps.pop_back())
	hud.map_name += "（%d只Boss）" % round_number
	spawning_boss = false
	spawn_pending_bosses()


func spawn_pending_bosses() -> void:
	# Preserve the global 30-enemy cap; later bosses enter as slots become free.
	while not pending_boss_maps.is_empty() and GameEvents.can_spawn_enemy(true):
		spawning_boss = true
		var boss: Node2D = main.spawn_boss_for_map(pending_boss_maps[0])
		spawning_boss = false
		if boss == null:
			return
		var boss_map_id: int = pending_boss_maps.pop_front()
		boss.get_node("HealthComponent").died.connect(on_boss_died.bind(boss, boss_map_id), CONNECT_ONE_SHOT)


func on_boss_died(boss: Node2D, boss_map_id: int) -> void:
	if stage != Stage.FIGHT or not is_instance_valid(boss):
		return
	var boss_id := boss.get_instance_id()
	if dead_boss_ids.has(boss_id):
		return
	# If both die on the same frame, player defeat takes precedence.
	var player: Node = main.get_node_or_null("Entities/Player")
	if player == null or player.health_component.current_health <= 0:
		finish(false)
		return
	dead_boss_ids[boss_id] = true
	defeated_bosses += 1
	try_unlock_weapon(boss, boss_map_id)
	remaining_bosses -= 1
	if remaining_bosses > 0:
		return
	stage = Stage.CLEANUP
	cleanup_battle()
	get_tree().paused = true
	# Let safe deletions and the boss's remaining death callbacks finish first.
	await get_tree().process_frame
	await get_tree().process_frame
	if stage == Stage.FINISHED:
		return
	cleanup_battle()
	if round_index == BOSS_NAMES.size() - 1:
		finish(true)
		return
	round_index += 1
	stage = Stage.REWARD
	main.get_node("UpgradeManager").show_upgrade_choices(3)


func try_unlock_weapon(boss: Node2D, boss_map_id: int) -> void:
	var health := boss.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return
	var rule: Dictionary = {}
	for candidate: Dictionary in WEAPON_UNLOCK_RULES:
		if not MetaProgression.is_weapon_unlocked(str(candidate["unlocks"])):
			rule = candidate
			break
	if rule.is_empty() or int(rule["boss_map_id"]) != boss_map_id:
		return
	var required_weapon_id := str(rule["weapon_id"])
	if bool(rule.get("requires_equipped", false)):
		if not main.get_node("UpgradeManager").current_upgrades.has(required_weapon_id):
			return
	elif health.last_damage_weapon_id != required_weapon_id:
		return
	var unlocked_weapon_id := str(rule["unlocks"])
	if not MetaProgression.unlock_weapon(unlocked_weapon_id):
		return
	var upgrade_manager: Node = main.get_node("UpgradeManager")
	upgrade_manager.add_unlocked_weapon(unlocked_weapon_id)
	var weapon_name := unlocked_weapon_id
	for weapon: Ability in upgrade_manager.weapon_upgrades:
		if weapon.id == unlocked_weapon_id:
			weapon_name = weapon.name
			break
	main.get_node("ArenaTimeUI").show_notification("解锁新武器：%s" % weapon_name)


func cleanup_battle() -> void:
	# Controllers live under Player. Only these foreground weapons are persistent.
	var player: Node = main.get_node_or_null("Entities/Player")
	if player != null:
		for controller: Node in player.abilities.get_children():
			if controller is AzureDragonController and controller.four_beasts_active:
				controller.end_four_beasts_rush()
	for layer_name: String in ["GroundEffects", "EnemyProjectiles", "PlayerProjectiles", "CombatEffects"]:
		for effect: Node in main.get_node(layer_name).get_children():
			if effect is AzureDragonAbility or effect is VermilionBirdAbility or effect is WhiteTigerAbility or effect is XuanwuAbility or effect is NineTreasurePagodaAbility:
				continue
			effect.queue_free()
	for entity: Node in main.get_node("Entities").get_children():
		if entity != player:
			entity.queue_free()
	for effect: Node in main.get_node("IceMap").get_children():
		effect.queue_free()
	if player != null:
		player.velocity = Vector2.ZERO
		var movement: VelocityComponent = player.velocity_component
		movement.velocity = Vector2.ZERO
		movement.knockback_time_left = 0.0
		movement.stun_time_left = 0.0
		movement.slow_time_left = 0.0
		movement.slippery_time_left = 0.0
		movement.slow_multiplier = 1.0
		movement.slow_changed.emit(false)
		if is_instance_valid(movement.stun_indicator):
			movement.stun_indicator.time_left = 0.0
			movement.stun_indicator.hide()


func show_rest() -> void:
	stage = Stage.REST
	get_tree().paused = true
	rest_screen = CanvasLayer.new()
	rest_screen.layer = 30
	rest_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(rest_screen)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rest_screen.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := Label.new()
	label.text = "第%d轮 · 第 %d 场胜利！选择下一场准备方式" % [round_number, round_index + 1]
	box.add_child(label)
	for heal: bool in [true, false]:
		var button: Button = preload("res://scenes/ui/sound_button.tscn").instantiate()
		button.text = "[1] 休整：恢复30%最大生命" if heal else "[2] 乘胜追击：额外升级一次（不治疗）"
		var shortcut := Shortcut.new()
		for key: int in ([KEY_1, KEY_KP_1] if heal else [KEY_2, KEY_KP_2]):
			var key_event := InputEventKey.new()
			key_event.keycode = key
			shortcut.events.append(key_event)
		button.shortcut = shortcut
		button.pressed.connect(choose_rest.bind(heal))
		box.add_child(button)


func choose_rest(heal: bool) -> void:
	if stage != Stage.REST:
		return
	stage = Stage.EXTRA
	if is_instance_valid(rest_screen):
		rest_screen.hide()
		rest_screen.queue_free()
	if heal:
		var player: Node = main.get_node_or_null("Entities/Player")
		if player == null:
			finish(false)
			return
		player.health_component.heal(player.health_component.max_health * 0.30, "boss_reward")
		start_fight()
	else:
		main.get_node("UpgradeManager").show_upgrade_choices(3)


func finish(victory: bool) -> void:
	if stage in [Stage.FINISHED, Stage.ROUND_COMPLETE]:
		return
	stage = Stage.ROUND_COMPLETE if victory else Stage.FINISHED
	main.get_node("EnemyManager").stop_spawning()
	cleanup_battle()
	main.set_process(false)
	if is_instance_valid(rest_screen):
		rest_screen.queue_free()
	var screen: EndScreen = main.end_screen_scene.instantiate()
	result_screen = screen
	main.add_child(screen)
	if victory:
		screen.get_node("%TitleLabel").text = "胜利"
		screen.get_node("%ContinueButton").text = "进入第%d轮（再选%d次技能）" % [round_number + 1, NEXT_ROUND_UPGRADES]
		screen.continue_requested.connect(continue_round, CONNECT_ONE_SHOT)
		screen.play_jingle()
	else:
		screen.set_defeat()
	screen.get_node("%DefeatReasonLabel").text += "\nBoss 车轮战：第%d轮 · 累计击败 %d\n战斗用时 %d:%02d" % [round_number, defeated_bosses, int(combat_time / 60.0), int(combat_time) % 60]


func continue_round() -> void:
	if stage != Stage.ROUND_COMPLETE:
		return
	stage = Stage.INITIAL
	round_number += 1
	round_index = 0
	result_screen.hide()
	result_screen.queue_free()
	main.set_process(true)
	var upgrades: Node = main.get_node("UpgradeManager")
	upgrades.initial_choices_remaining = NEXT_ROUND_UPGRADES
	upgrades.show_upgrade_choices(3)
