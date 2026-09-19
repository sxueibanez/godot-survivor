extends Node

const HUNT_TIME := 60.0
const OVERLOAD_TIME := 110.0
const BOUNTY_TIME := 150.0
const OFFER_END := 180.0

var main: Node
var status: Label
var status_left := 0.0
var stopped := false
var hunt_offered := false
var overload_offered := false
var bounty_offered := false
var hunt: Node2D
var elite_timers: Array[Dictionary] = []
var overload_point: Node2D
var bounty_point: Node2D
var bounty_offer_left := 0.0
var overload_left := 0.0
var overload_tick := 0.0
var overload_charge := 0.0
var pending_overload_elite := false
var bounty_selected := false
var boss_wave_started := false
var wave: Array[Node2D] = []
var challenge_enemies: Array[Node2D] = []
var bounty_remaining := 0
var generation := 0


class ChallengeRing extends Node2D:
	var tint := Color(1.0, 0.65, 0.15)
	var pulse := 0.0

	func _process(delta: float) -> void:
		pulse += delta * 3.0
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 26.0, Color(tint, 0.15))
		draw_arc(Vector2.ZERO, 24.0 + sin(pulse) * 2.0, 0, TAU, 32, tint, 2.0)
		for index in 4:
			var direction := Vector2.RIGHT.rotated(pulse * 0.4 + index * TAU / 4.0)
			draw_line(direction * 18.0, direction * 31.0, tint, 3.0)


func _ready() -> void:
	main = get_parent()
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	status = Label.new()
	status.position = Vector2(12, 82)
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_shadow_color", Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x", 1)
	status.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(status)


func _process(delta: float) -> void:
	if stopped:
		return
	if not has_living_player():
		stop_challenges()
		return
	if GameEvents.is_endless_mode() or main.get("current_map_id") == 0:
		return
	if status_left > 0:
		status_left = maxf(0.0, status_left - delta)
		if status_left <= 0:
			status.text = ""
	var time: float = main.get_node("ArenaTimeManager").get_time_elapsed()
	if time < OFFER_END:
		if time >= HUNT_TIME and not hunt_offered:
			start_hunt()
		if time >= OVERLOAD_TIME and not overload_offered:
			overload_offered = true
			overload_point = make_point("超载点\n累计停留5秒激活：20秒狂潮 / 经验x2", Color(0.2, 0.9, 1.0))
		if time >= BOUNTY_TIME and not bounty_offered:
			bounty_offered = true
			bounty_offer_left = 30.0
			bounty_point = make_point("双Boss悬赏\n入圈选择：3:00出现两只Boss", Color(1.0, 0.3, 0.45))
		if is_instance_valid(bounty_point):
			bounty_offer_left = maxf(0.0, OFFER_END - time)
			if bounty_offer_left <= 0:
				clear_point(bounty_point)
				bounty_point = null
			else:
				(bounty_point.get_child(0) as Label).text = "双Boss悬赏（%ds后消失）\n入圈选择：3:00刷两只Boss / 两轮升级" % ceili(bounty_offer_left)
		if is_instance_valid(overload_point):
			if player_position().distance_to(overload_point.global_position) < 24.0:
				overload_charge = minf(5.0, overload_charge + delta)
			(overload_point.get_child(0) as Label).text = "超载点：蓄力 %.1f / 5秒\n离圈保留进度 / 激活20秒狂潮 / 经验x2" % overload_charge
			if overload_charge >= 5.0:
				start_overload()
		if is_instance_valid(bounty_point) and player_position().distance_to(bounty_point.global_position) < 24.0:
			start_bounty()
	else:
		clear_point(overload_point)
		clear_point(bounty_point)
		overload_point = null
		bounty_point = null
		overload_charge = 0.0
	update_elite_countdowns(delta)
	if overload_left > 0:
		overload_left = maxf(0.0, overload_left - delta)
		overload_tick -= delta
		show_status("超载狂潮：%ds  攻速+54%% / 经验x2" % ceili(overload_left), 0.0)
		if overload_tick <= 0:
			overload_tick = 0.35
			spawn_wave()
		if overload_left <= 0:
			finish_overload()
	apply_attack_rate()
	if pending_overload_elite:
		spawn_overload_elite()


func player_position() -> Vector2:
	var player := main.get_node_or_null("Entities/Player") as Node2D
	return player.global_position if is_instance_valid(player) else Vector2.ZERO


func has_living_player() -> bool:
	var player := main.get_node_or_null("Entities/Player") as Node2D
	if player == null or player.is_queued_for_deletion():
		return false
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	return health != null and health.current_health > 0


func show_status(message: String, duration: float = 5.0) -> void:
	status.text = message
	status_left = duration


func nearby_position(distance: float) -> Vector2:
	# Reuse the spawner's wall-tested direction, keeping objectives within sight.
	var spawn: Vector2 = main.get_node("EnemyManager").get_spawn_position()
	return player_position().move_toward(spawn, distance)


func make_point(text: String, tint: Color) -> Node2D:
	var point := ChallengeRing.new()
	point.tint = tint
	main.get_node("Entities").add_child(point)
	point.global_position = nearby_position(140.0)
	var label := Label.new()
	label.text = text
	label.position = Vector2(-120, -66)
	label.size.x = 240
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	point.add_child(label)
	return point


func spawn_enemy(position: Vector2) -> Node2D:
	if not GameEvents.can_spawn_enemy():
		return null
	var spawner: Node = main.get_node("EnemyManager")
	var scene: PackedScene = spawner.pick_enemy_scene()
	var forge: Node = get_tree().get_first_node_in_group("forge_map")
	if forge != null and forge.active:
		position = forge.safe_position(position)
	var enemy := scene.instantiate() as Node2D
	spawner.apply_difficulty(enemy)
	main.get_node("Entities").add_child(enemy)
	enemy.global_position = position
	if enemy.has_method("configure_small"):
		enemy.set("can_split", false)
	challenge_enemies.append(enemy)
	return enemy


func make_elite(position: Vector2) -> Node2D:
	var elite := spawn_enemy(position)
	if elite == null:
		return null
	elite.add_to_group("elite")
	var health := elite.get_node("HealthComponent") as HealthComponent
	health.max_health *= 4.0
	health.current_health = health.max_health
	elite.modulate = Color(1.0, 0.65, 0.3)
	var visuals := elite.get_node_or_null("Visuals") as Node2D
	if visuals != null:
		visuals.scale *= 1.35
	var marker := ChallengeRing.new()
	marker.position.y = -12
	elite.add_child(marker)
	var label := Label.new()
	label.position = Vector2(-100, -76)
	label.size.x = 200
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.text = "★ 精英 30s\n击杀：武器升级"
	elite.add_child(label)
	elite_timers.append({"enemy": elite, "label": label, "left": 30.0})
	return elite


func update_elite_countdowns(delta: float) -> void:
	for index in range(elite_timers.size() - 1, -1, -1):
		var entry: Dictionary = elite_timers[index]
		if not is_instance_valid(entry["enemy"]) or entry["enemy"].is_queued_for_deletion():
			elite_timers.remove_at(index)
			continue
		entry["left"] = maxf(0.0, float(entry["left"]) - delta)
		(entry["label"] as Label).text = "★ 精英 %ds\n击杀：武器升级" % ceili(entry["left"])
		var health := entry["enemy"].get_node("HealthComponent") as HealthComponent
		if entry["left"] <= 0 and health.current_health > 0:
			if entry["enemy"] == hunt:
				hunt = null
			entry["enemy"].queue_free()
			elite_timers.remove_at(index)
			show_status("精英已撤退，本次无奖励")


func start_hunt() -> void:
	if stopped or not has_living_player():
		return
	hunt = make_elite(nearby_position(280.0))
	if hunt == null:
		return
	hunt_offered = true
	(hunt.get_node("HealthComponent") as HealthComponent).died.connect(on_hunt_died.bind(generation))
	for index in 3:
		spawn_enemy(hunt.global_position + Vector2.RIGHT.rotated(index * TAU / 3) * 32.0)
	show_status("限时猎杀出现！金色★精英30秒后撤退，击杀获武器升级")


func on_hunt_died(token: int) -> void:
	if token != generation or not is_instance_valid(hunt):
		return
	hunt = null
	grant_reward(3, "猎杀成功：领取当前武器升级")


func start_overload() -> void:
	if stopped or not has_living_player() or overload_left > 0 or main.get("current_level_boss_started"):
		return
	clear_point(overload_point)
	overload_point = null
	overload_charge = 0.0
	overload_left = 20.0
	overload_tick = 0.0
	GameEvents.challenge_attack_interval_multiplier = 0.65
	GameEvents.challenge_experience_multiplier = 2.0
	apply_attack_rate()


func spawn_wave() -> void:
	if stopped or not has_living_player():
		return
	wave = wave.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_queued_for_deletion())
	for index in 3:
		var enemy := spawn_enemy(nearby_position(230.0))
		if enemy == null:
			break
		var health := enemy.get_node("HealthComponent") as HealthComponent
		health.max_health *= 0.3
		health.current_health = health.max_health
		var drop := enemy.get_node_or_null("VialDropComponent")
		if drop != null:
			drop.set("drop_rate", 1.0)
		wave.append(enemy)


func finish_overload() -> void:
	GameEvents.challenge_attack_interval_multiplier = 1.0
	GameEvents.challenge_experience_multiplier = 1.0
	apply_attack_rate()
	if stopped or not has_living_player():
		return
	pending_overload_elite = true
	show_status("狂潮结束：精英将在腾出位置后出现")
	spawn_overload_elite()


func spawn_overload_elite() -> void:
	var elite := make_elite(nearby_position(220.0))
	if elite == null:
		return
	pending_overload_elite = false
	(elite.get_node("HealthComponent") as HealthComponent).died.connect(on_overload_elite_died.bind(generation), CONNECT_ONE_SHOT)
	show_status("狂潮结束：击杀金色精英领取武器升级")


func on_overload_elite_died(token: int) -> void:
	if token == generation:
		grant_reward(3, "狂潮精英已击杀：领取武器升级")


func start_bounty() -> void:
	if stopped or not has_living_player() or bounty_selected or main.get("current_level_boss_started"):
		return
	if main.get_node("ArenaTimeManager").get_time_elapsed() >= OFFER_END:
		return
	clear_point(bounty_point)
	bounty_point = null
	bounty_selected = true
	show_status("已选择双Boss悬赏：3:00出现两只Boss")


func spawn_scheduled_bosses() -> void:
	if stopped or not has_living_player() or boss_wave_started:
		return
	boss_wave_started = true
	clear_point(bounty_point)
	bounty_point = null
	bounty_remaining = 0
	var first: int = main.get("previous_map_id")
	var second: int = main.get("current_map_id")
	if first == 0 or first == second:
		first = second % main.MAP_COUNT + 1
	var boss_maps: Array[int] = [second]
	if bounty_selected:
		boss_maps.push_front(first)
	for map_id in boss_maps:
		var boss: Node2D = main.spawn_boss_for_map(map_id)
		if boss == null:
			continue
		challenge_enemies.append(boss)
		var health := boss.get_node("HealthComponent") as HealthComponent
		if bounty_selected:
			bounty_remaining += 1
			health.max_health *= 0.75
			health.current_health = health.max_health
			health.died.connect(on_bounty_boss_died.bind(generation), CONNECT_ONE_SHOT)
	if bounty_selected:
		show_status("双Boss悬赏：剩余2只 / 胜利奖励两轮武器升级", 0.0)


func on_bounty_boss_died(token: int) -> void:
	if token != generation or bounty_remaining <= 0:
		return
	bounty_remaining -= 1
	if bounty_remaining == 0:
		grant_reward(4, "双Boss悬赏完成：领取两轮武器升级")
		main.get_node("UpgradeManager").show_challenge_reward(4)
	else:
		show_status("双Boss悬赏：剩余1只", 0.0)


func grant_reward(choices: int, message: String) -> void:
	if stopped or not has_living_player():
		return
	show_status(message)
	main.get_node("UpgradeManager").show_challenge_reward(choices)


func apply_attack_rate() -> void:
	var abilities := main.get_node_or_null("Entities/Player/Abilities")
	if abilities == null:
		return
	for controller: Node in abilities.get_children():
		if controller is NineTreasurePagodaController:
			# The pagoda owns these timers and composes both multipliers itself.
			return
	var timers: Array[Timer] = []
	for controller: Node in abilities.get_children():
		var timer := controller.get_node_or_null("Timer") as Timer
		if timer != null:
			timers.append(timer)
	for layer_name in ["player_projectiles_layer", "combat_effects_layer"]:
		var foreground := get_tree().get_first_node_in_group(layer_name)
		if foreground == null:
			continue
		for companion: Node in foreground.get_children():
			var timer := companion.get_node_or_null("AttackTimer") as Timer
			if timer != null:
				timers.append(timer)
	for timer: Timer in timers:
		var factor := GameEvents.challenge_attack_interval_multiplier
		if factor == 1.0 and not timer.has_meta("challenge_base_wait"):
			continue
		var last := float(timer.get_meta("challenge_applied_wait", -1.0))
		var base := float(timer.get_meta("challenge_base_wait", timer.wait_time))
		if last >= 0 and not is_equal_approx(last, timer.wait_time):
			base = timer.wait_time
		timer.wait_time = maxf(0.05, base * factor)
		if factor == 1.0:
			timer.remove_meta("challenge_base_wait")
			timer.remove_meta("challenge_applied_wait")
		else:
			timer.set_meta("challenge_base_wait", base)
			timer.set_meta("challenge_applied_wait", timer.wait_time)


func clear_point(point) -> void:
	if is_instance_valid(point) and not point.is_queued_for_deletion():
		point.queue_free()


func reset_challenges() -> void:
	generation += 1
	GameEvents.challenge_attack_interval_multiplier = 1.0
	GameEvents.challenge_experience_multiplier = 1.0
	apply_attack_rate()
	for enemy: Node2D in challenge_enemies:
		clear_point(enemy)
	challenge_enemies.clear()
	wave.clear()
	clear_point(overload_point)
	clear_point(bounty_point)
	overload_point = null
	bounty_point = null
	hunt = null
	elite_timers.clear()
	overload_left = 0.0
	bounty_remaining = 0
	bounty_selected = false
	boss_wave_started = false
	overload_charge = 0.0
	pending_overload_elite = false
	bounty_offer_left = 0.0
	status_left = 0.0
	hunt_offered = false
	overload_offered = false
	bounty_offered = false
	status.text = ""


func stop_challenges() -> void:
	reset_challenges()
	stopped = true
	set_process(false)
