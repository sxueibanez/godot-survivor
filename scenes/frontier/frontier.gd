extends Node

const INITIAL_RADIUS := 3000.0
const FINAL_RADIUS := 260.0
const SHRINK_INTERVAL := 60.0
const SHRINK_DURATION := 20.0
const SHRINK_STEP := 450.0
const MAX_CHESTS := 120
const MAX_ENEMIES := 120
const EXPLORATION_ENEMY_HEALTH := 60.0
const TOWER_TOUCH_RANGE := 40.0
const MAX_POTIONS := 8
const RESPAWN_TIME := 5.0
const ENEMY_SCENES: Array[PackedScene] = [
	preload("res://scenes/game_object/basic_enemy/basic_enemy.tscn"),
	preload("res://scenes/game_object/wizard_enemy/wizard_enemy.tscn"),
	preload("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn"),
	preload("res://scenes/game_object/ranged_enemy/ranged_enemy.tscn"),
	preload("res://scenes/game_object/cyclops_bat/cyclops_bat.tscn"),
	preload("res://scenes/game_object/iron_golem/iron_golem.tscn"),
	preload("res://scenes/game_object/stone_slime/stone_slime.tscn"),
	preload("res://scenes/game_object/frost_wisp/frost_wisp.tscn"),
	preload("res://scenes/game_object/frost_boar/frost_boar.tscn"),
	preload("res://scenes/game_object/snowball_monster/snowball_monster.tscn"),
	preload("res://scenes/game_object/forge_enemy/cinder.tscn"),
	preload("res://scenes/game_object/forge_enemy/guard.tscn"),
	preload("res://scenes/game_object/forge_enemy/worker.tscn"),
]
const BOSS_SCENES: Array[PackedScene] = [
	preload("res://scenes/game_object/slime_king/slime_king.tscn"),
	preload("res://scenes/game_object/frost_queen/frost_queen.tscn"),
	preload("res://scenes/game_object/lightning_knight/lightning_knight.tscn"),
	preload("res://scenes/game_object/iron_arm_miner/iron_arm_miner.tscn"),
	preload("res://scenes/game_object/furnace_tyrant/furnace_tyrant.tscn"),
]
const ENEMY_AI := preload("res://scenes/frontier/frontier_enemy_ai.gd")
const SIEGE_RANGES := {
	"ranged_enemy.tscn": 185.0, "cyclops_bat.tscn": 185.0, "frost_wisp.tscn": 185.0,
	"worker.tscn": 225.0, "guard.tscn": 85.0, "iron_golem.tscn": 72.0,
	"exploder_enemy.tscn": 70.0,
}
const MARKER := preload("res://scenes/frontier/map_marker.gd")
const INVENTORY := preload("res://scenes/frontier/weapon_inventory.gd")
const MAP := preload("res://scenes/frontier/minimap.gd")
const CARD := preload("res://scenes/ui/ability_upgrade_card.gd")

var rng := RandomNumberGenerator.new()
var world: Node2D
var player: CharacterBody2D
var tower: Node2D
var inventory: Node
var safe_radius := INITIAL_RADIUS
var target_radius := INITIAL_RADIUS
var previous_radius := INITIAL_RADIUS
var shrink_elapsed := 0.0
var cycle_elapsed := 0.0
var shrinking := false
var defense_active := false
var finished := false
var started := false
var respawning := false
var respawn_left := 0.0
var outside_tick := 0.0
var chest_timer := 0.0
var shop_timer := 0.0
var wave_timer := 0.0
var elite_timer := 0.0
var boss_timer := 0.0
var boss_count := 0
var exploration_spawn_timer := 0.0
var defense_time := 0.0
var supply_time := 30.0
var supply_count := 0
var boss_warned := false
var tower_warned := false
var chests_opened := 0
var bosses_defeated := 0
var total_time := 0.0
var kills := 0
var gold := 0
var potions := 0
var tower_health := 1500.0
var tower_max_health := 1500.0
var screen: CanvasLayer
var status: Label
var instructions: Label
var tower_status: Label
var danger_overlay: ColorRect
var zone_visual: Node2D
var notice := ""
var notice_left := 0.0


class Tower extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 27.0, Color(0.21, 0.21, 0.18))
		draw_rect(Rect2(-17, -28, 34, 45), Color(0.57, 0.55, 0.42))
		draw_colored_polygon(PackedVector2Array([Vector2(-23, -27), Vector2(0, -47), Vector2(23, -27)]), Color(0.32, 0.48, 0.58))
		draw_rect(Rect2(-5, -19, 10, 14), Color(1.0, 0.8, 0.3))
		draw_arc(Vector2.ZERO, 30.0, 0, TAU, 40, Color(0.9, 0.75, 0.3, 0.75), 2.0)


class Zone extends Node2D:
	var mode: Node

	func _draw() -> void:
		if is_instance_valid(mode):
			draw_arc(Vector2.ZERO, mode.safe_radius, 0, TAU, 160, Color(0.35, 0.9, 1.0, 0.9), 4.0, true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("frontier_mode")
	for name: String in ["World", "GroundEffects", "EnemyProjectiles", "Entities", "PlayerProjectiles", "CombatEffects", "FloatingText", "GameCamera"]:
		get_node(name).process_mode = Node.PROCESS_MODE_PAUSABLE
	GameEvents.reset_run_stats()
	GameEvents.game_mode = "frontier"
	GameEvents.ability_critical_chance = 0.0
	GameEvents.meta_critical_chance = MetaProgression.get_upgrade_count("meta_critical_chance") * 0.01
	GameEvents.critical_damage_multiplier = 2.0
	GameEvents.critical_disabled = false
	GameEvents.speed_damage_no_crit = false
	GameEvents.life_steal_percent = MetaProgression.get_upgrade_count("meta_life_steal") * 0.01
	GameEvents.refresh_critical_chance()
	world = $World
	player = $Entities/Player
	$BossHealthBar/MarginContainer.add_theme_constant_override("margin_right", 150)
	var spawn := Vector2.RIGHT.rotated(rng.randf_range(0, TAU)) * (INITIAL_RADIUS - 160.0)
	player.global_position = spawn
	world.rng.seed = rng.randi()
	world.generate(spawn)
	tower = Tower.new()
	$Entities.add_child(tower)
	zone_visual = Zone.new()
	zone_visual.mode = self
	$GroundEffects.add_child(zone_visual)
	inventory = INVENTORY.new()
	inventory.player = player
	add_child(inventory)
	player.health_component.died.connect(on_player_died)
	make_hud()
	for index in 100:
		spawn_chest()
	for index in 10:
		spawn_shop()
	for index in 100:
		spawn_enemy(random_free_point(INITIAL_RADIUS - 50.0, 220.0), "normal", false)
	MusicPlayer.play_level(1)
	var selection := preload("res://scenes/ui/character_select.tscn").instantiate()
	selection.character_selected.connect(on_character_selected)
	add_child(selection)


func on_character_selected(character: Resource) -> void:
	player.set_character(character)
	var starter := {"id": "axe", "rarity": 1, "skills": inventory.roll_skills("axe", 1)}
	inventory.equip(starter, 0)
	started = true
	show_notice("向中心前进：E 开宝箱 / 使用铁匠铺，Q 喝药")


func make_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	status = Label.new()
	status.position = Vector2(12, 52)
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_constant_override("outline_size", 3)
	status.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(status)
	instructions = Label.new()
	instructions.position = Vector2(12, 112)
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_constant_override("outline_size", 3)
	instructions.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(instructions)
	tower_status = Label.new()
	tower_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tower_status.offset_top = 8.0
	tower_status.offset_bottom = 28.0
	tower_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_status.add_theme_font_size_override("font_size", 12)
	tower_status.add_theme_constant_override("outline_size", 3)
	tower_status.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	tower_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tower_status)
	var map := MAP.new()
	map.mode = self
	hud.add_child(map)
	var legend := Label.new()
	hud.add_child(legend)
	legend.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	legend.offset_left = -145.0
	legend.offset_right = -8.0
	legend.offset_top = 98.0
	legend.offset_bottom = 143.0
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.add_theme_font_size_override("font_size", 9)
	legend.add_theme_constant_override("outline_size", 2)
	legend.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	legend.text = "白点：玩家  黄点：建筑\n棕/蓝/金方：宝箱\n红方：铁匠  红点：首领"
	var overlay := CanvasLayer.new()
	overlay.layer = 5
	add_child(overlay)
	danger_overlay = ColorRect.new()
	danger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_overlay.color = Color(0.65, 0.05, 0.05, 0.18)
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_overlay.hide()
	overlay.add_child(danger_overlay)


func _process(delta: float) -> void:
	if get_tree().paused or not started or finished:
		return
	total_time += delta
	if respawning:
		respawn_left = maxf(respawn_left - delta, 0.0)
		if respawn_left <= 0.0:
			revive_player()
	if notice_left > 0.0:
		notice_left = maxf(notice_left - delta, 0.0)
	advance_zone(delta)
	if not defense_active and not respawning and player.global_position.distance_to(tower.global_position) <= TOWER_TOUCH_RANGE:
		start_defense()
	if not respawning and player.global_position.length() > safe_radius:
		outside_tick -= delta
		if outside_tick <= 0.0:
			outside_tick = 1.0
			player.health_component.damage(player.health_component.max_health * 0.05, "安全区外")
		danger_overlay.show()
	else:
		outside_tick = 0.0
		danger_overlay.hide()
	chest_timer += delta
	if chest_timer >= 30.0:
		chest_timer = 0.0
		spawn_chest()
	shop_timer += delta
	if shop_timer >= 60.0:
		shop_timer = 0.0
		spawn_shop()
	if defense_active:
		process_defense(delta)
	else:
		process_exploration(delta)
	update_hud()


func advance_zone(delta: float) -> void:
	if defense_active:
		return
	if not shrinking:
		cycle_elapsed += delta
		if cycle_elapsed < SHRINK_INTERVAL:
			return
		shrinking = true
		shrink_elapsed = 0.0
		previous_radius = safe_radius
		target_radius = maxf(FINAL_RADIUS, safe_radius - SHRINK_STEP)
		show_notice("安全区开始收缩，向中心移动！")
	else:
		shrink_elapsed += delta
		safe_radius = lerpf(previous_radius, target_radius, minf(shrink_elapsed / SHRINK_DURATION, 1.0))
		zone_visual.queue_redraw()
		if shrink_elapsed >= SHRINK_DURATION:
			shrinking = false
			cycle_elapsed = 0.0
			refresh_safe_zone_loot()
			if safe_radius <= FINAL_RADIUS:
				start_defense()


func start_defense() -> void:
	if defense_active or finished:
		return
	defense_active = true
	tower.add_to_group("frontier_defense_target")
	safe_radius = FINAL_RADIUS
	target_radius = FINAL_RADIUS
	previous_radius = FINAL_RADIUS
	shrinking = false
	zone_visual.queue_redraw()
	refresh_safe_zone_loot()
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	wave_timer = 0.0
	elite_timer = 15.0
	boss_timer = 35.0
	spawn_shop(true)
	var starting_potion := potions < MAX_POTIONS
	potions = mini(MAX_POTIONS, potions + 1)
	show_notice("守塔开始！%s每 30 秒获得守塔补给" % ("获得 1 瓶药水，" if starting_potion else ""))


func process_exploration(delta: float) -> void:
	exploration_spawn_timer -= delta
	if exploration_spawn_timer > 0.0 or respawning:
		return
	exploration_spawn_timer = 4.0
	var nearby := 0
	var distant: Array[Node2D] = []
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_queued_for_deletion():
			continue
		var distance := enemy.global_position.distance_to(player.global_position)
		if distance < 650.0:
			nearby += 1
		elif distance > 1200.0:
			distant.append(enemy)
	for index in mini(5, maxi(18 - nearby, 0)):
		if active_enemy_count() >= MAX_ENEMIES - 2 and not distant.is_empty():
			distant.pop_back().queue_free()
		for attempt in 20:
			var point := player.global_position + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(250.0, 550.0)
			if point.length() < safe_radius - 25.0 and world.is_clear(point, 35.0):
				spawn_enemy(point, "normal", false)
				break


func active_enemy_count() -> int:
	var count := 0
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_queued_for_deletion():
			count += 1
	return count


func process_defense(delta: float) -> void:
	defense_time += delta
	while defense_time >= supply_time:
		supply_time += 30.0
		grant_defense_supply()
	wave_timer -= delta
	elite_timer -= delta
	boss_timer -= delta
	if boss_timer <= 10.0 and boss_timer > 0.0 and not boss_warned and get_tree().get_nodes_in_group("boss").is_empty():
		boss_warned = true
		show_notice("首领即将来袭，准备防守！")
	if wave_timer <= 0.0:
		wave_timer = maxf(0.55, 1.6 - defense_time / 180.0)
		var count := mini(3 + floori(defense_time / 60.0), 7)
		for index in count:
			spawn_enemy(defense_spawn_point(), "normal", true)
	if elite_timer <= 0.0:
		elite_timer = 18.0
		spawn_enemy(defense_spawn_point(), "elite", true)
	if boss_timer <= 0.0:
		boss_timer = 55.0
		boss_warned = false
		if get_tree().get_nodes_in_group("boss").is_empty():
			spawn_enemy(defense_spawn_point(), "boss", true)


func grant_defense_supply() -> void:
	supply_count += 1
	var reward := 20 + mini(supply_count * 5, 50)
	gold += reward
	var restored := minf(tower_max_health - tower_health, 50.0)
	tower_health += restored
	var potion_gained := supply_count % 2 == 0 and potions < MAX_POTIONS
	if potion_gained:
		potions += 1
	if tower_health > tower_max_health * 0.25:
		tower_warned = false
	show_notice("守塔补给：%d 金币，建筑恢复 %.0f%s" % [reward, restored, "，药水 +1" if potion_gained else ""])


func defense_spawn_point() -> Vector2:
	return Vector2.RIGHT.rotated(rng.randf_range(0, TAU)) * (FINAL_RADIUS + 22.0)


func spawn_enemy(point: Vector2, kind: String, defending: bool) -> Node2D:
	if active_enemy_count() >= MAX_ENEMIES - (0 if kind == "boss" else 2):
		return null
	var scene: PackedScene
	if kind == "boss":
		scene = BOSS_SCENES[boss_count % BOSS_SCENES.size()]
		boss_count += 1
	else:
		scene = ENEMY_SCENES[rng.randi_range(0, ENEMY_SCENES.size() - 1)]
	var enemy := scene.instantiate() as CharacterBody2D
	if kind == "elite":
		enemy.add_to_group("elite")
		enemy.scale *= 1.4
		enemy.modulate = Color(1.0, 0.78, 0.3)
	$Entities.add_child(enemy)
	enemy.global_position = point
	var health := enemy.get_node("HealthComponent") as HealthComponent
	var base_health := 20.0 + defense_time / 60.0 * 5.0 if defending else EXPLORATION_ENEMY_HEALTH
	health.max_health = (900.0 + defense_time * 2.5) if kind == "boss" else base_health * (3.0 if kind == "elite" else 1.0)
	health.current_health = health.max_health
	health.health_changed.emit()
	register_enemy(enemy, defending)
	if kind == "boss":
		show_notice("首领来袭：%s" % enemy.get_meta("display_name", enemy.name))
	return enemy


func register_enemy(enemy: CharacterBody2D, defending: bool) -> void:
	var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return
	var drop := enemy.get_node_or_null("VialDropComponent") as VialDropComponent
	if drop != null:
		drop.disabled = true
	var potion_drop := enemy.get_node_or_null("HealthVialDropComponent")
	if potion_drop != null:
		potion_drop.queue_free()
	var on_death := on_enemy_died.bind(enemy)
	if not health.died.is_connected(on_death):
		health.died.connect(on_death, CONNECT_ONE_SHOT)
	var ai := enemy.get_node_or_null("FrontierEnemyAI")
	if ai == null:
		ai = ENEMY_AI.new()
		ai.name = "FrontierEnemyAI"
		enemy.add_child(ai)
	ai.enemy = enemy
	ai.mode = self
	ai.defending = defending
	if defending:
		enemy.add_to_group("frontier_siege")
		ai.tower_damage = 28.0 if enemy.is_in_group("boss") else (22.0 if enemy.is_in_group("elite") else 7.0)
		var path := enemy.scene_file_path
		ai.attack_range = float(SIEGE_RANGES.get(path.get_file(), 80.0 if enemy.is_in_group("boss") else 38.0))
	else:
		enemy.set_process(false)


func register_summon(enemy: Node2D) -> void:
	if not enemy is CharacterBody2D:
		return
	if not defense_active:
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.max_health = EXPLORATION_ENEMY_HEALTH
			health.current_health = health.max_health
			health.health_changed.emit()
	register_enemy(enemy, defense_active)


func on_enemy_died(enemy: Node2D) -> void:
	if finished or not is_instance_valid(enemy):
		return
	kills += 1
	gold += 60 if enemy.is_in_group("boss") else (15 if enemy.is_in_group("elite") else 2)
	if enemy.is_in_group("boss"):
		bosses_defeated += 1
		var restored := minf(120.0, tower_max_health - tower_health)
		tower_health += restored
		if tower_health > tower_max_health * 0.25:
			tower_warned = false
		var potion_gained := potions < MAX_POTIONS
		potions = mini(MAX_POTIONS, potions + 1)
		show_notice("击败首领：60 金币，建筑恢复 %.0f%s" % [restored, "，药水 +1" if potion_gained else ""])
	elif enemy.is_in_group("elite") and rng.randf() < 0.35:
		if potions < MAX_POTIONS:
			potions += 1
			show_notice("精英掉落 1 瓶药水")


func damage_tower(amount: float) -> void:
	if not defense_active or finished:
		return
	tower_health = maxf(tower_health - maxf(amount, 0.0), 0.0)
	if tower_health > 0.0 and tower_health <= tower_max_health * 0.25 and not tower_warned:
		tower_warned = true
		show_notice("建筑生命不足 25%！前往铁匠铺修复")
	if tower_health <= 0.0:
		end_game("守护建筑被摧毁")


func on_player_died() -> void:
	if not defense_active:
		end_game("角色被击败")
	elif not finished and not respawning:
		respawning = true
		respawn_left = RESPAWN_TIME
		player.set_process(false)
		player.set_physics_process(false)
		player.abilities.process_mode = Node.PROCESS_MODE_DISABLED
		player.get_node("CollisionArea2D").set_deferred("monitoring", false)
		player.hide()
		show_notice("角色倒地，5 秒后在建筑旁复活")


func revive_player() -> void:
	if not respawning or finished:
		return
	respawning = false
	player.global_position = Vector2(80, 0)
	player.velocity = Vector2.ZERO
	player.velocity_component.velocity = Vector2.ZERO
	player.health_component.death_emitted = false
	player.health_component.current_health = player.health_component.max_health * 0.5
	player.health_component.set_invulnerable(2.0)
	player.health_component.health_changed.emit()
	player.get_node("CollisionArea2D").set_deferred("monitoring", true)
	player.abilities.process_mode = Node.PROCESS_MODE_INHERIT
	player.set_process(true)
	player.set_physics_process(true)
	player.show()
	show_notice("已复活，守护建筑！")


func end_game(reason: String) -> void:
	if finished:
		return
	finished = true
	var bottles := maxi(gold, 0) / 10
	if bottles > 0:
		MetaProgression.on_experience_collected(bottles)
		MetaProgression.save()
	get_tree().paused = true
	var box := open_panel("挑战结束 · %s" % reason)
	add_label(box, "守塔时间 %d:%02d · 击败 %d · 剩余金币 %d" % [floori(defense_time / 60), floori(defense_time) % 60, kills, gold])
	add_label(box, "兑换永久升级瓶子：%d 瓶（每 10 金币兑换 1 瓶）" % bottles)
	add_label(box, "开启宝箱 %d · 击败首领 %d · 获得守塔补给 %d 次" % [chests_opened, bosses_defeated, supply_count])
	add_button(box, "返回主菜单", return_to_menu)


func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func random_free_point(radius: float, minimum_radius: float = 0.0) -> Vector2:
	for attempt in 200:
		var distance := sqrt(rng.randf_range(minimum_radius * minimum_radius, radius * radius))
		var point := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * distance
		if not world.is_clear(point, 35.0) or point.distance_to(player.global_position) <= 65.0:
			continue
		var occupied := false
		for group: String in ["frontier_chest", "frontier_shop"]:
			for marker: Node2D in get_tree().get_nodes_in_group(group):
				if not marker.is_queued_for_deletion() and marker.global_position.distance_squared_to(point) < 50.0 * 50.0:
					occupied = true
					break
		if not occupied:
			return point
	return Vector2(80, 0)


func spawn_chest() -> void:
	if get_tree().get_nodes_in_group("frontier_chest").size() >= MAX_CHESTS:
		return
	var roll := rng.randi_range(1, 100)
	var level := 1 if roll <= 60 else (2 if roll <= 90 else 3)
	var marker := MARKER.new()
	marker.kind = "chest"
	marker.level = level
	marker.add_to_group("frontier_chest")
	$Entities.add_child(marker)
	marker.global_position = random_free_point(maxf(safe_radius - 50.0, 100.0), 45.0)


func spawn_shop(force: bool = false) -> void:
	if not force and get_tree().get_nodes_in_group("frontier_shop").size() >= 16:
		return
	var marker := MARKER.new()
	marker.kind = "shop"
	marker.add_to_group("frontier_shop")
	$Entities.add_child(marker)
	marker.global_position = random_free_point(maxf(safe_radius - 50.0, 100.0), 65.0)


func refresh_safe_zone_loot() -> void:
	for group: String in ["frontier_chest", "frontier_shop"]:
		for marker: Node2D in get_tree().get_nodes_in_group(group):
			if marker.global_position.length() > safe_radius:
				marker.queue_free()


func nearest_interactable() -> Node2D:
	var nearest: Node2D
	var best := 52.0 * 52.0
	for group: String in ["frontier_chest", "frontier_shop"]:
		for marker: Node2D in get_tree().get_nodes_in_group(group):
			if marker.is_queued_for_deletion():
				continue
			var distance := player.global_position.distance_squared_to(marker.global_position)
			if distance < best:
				best = distance
				nearest = marker
	return nearest


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not started:
		return
	if event.is_action_pressed("pause"):
		if finished:
			return
		if is_instance_valid(screen):
			close_panel()
		else:
			show_pause()
		get_viewport().set_input_as_handled()
		return
	if get_tree().paused or finished or respawning:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key == KEY_E:
		var marker := nearest_interactable()
		if marker != null:
			if marker.is_in_group("frontier_chest"):
				open_chest(marker)
			else:
				show_forge()
		get_viewport().set_input_as_handled()
	elif key == KEY_Q:
		use_potion()
		get_viewport().set_input_as_handled()
	elif key == KEY_I:
		show_inventory()
		get_viewport().set_input_as_handled()


func open_chest(chest: Node2D) -> void:
	if not is_instance_valid(chest) or chest.is_queued_for_deletion():
		return
	var level: int = chest.level
	chests_opened += 1
	chest.queue_free()
	var roll := rng.randi_range(1, 100)
	if roll <= 40:
		var minimum: int = [10, 25, 60][level - 1]
		var maximum: int = [20, 45, 110][level - 1]
		var amount := rng.randi_range(minimum, maximum)
		gold += amount
		show_notice("宝箱：获得 %d 金币" % amount)
	elif roll <= 65:
		var previous := potions
		potions = mini(MAX_POTIONS, potions + level)
		var excess := level - (potions - previous)
		gold += excess * 10
		show_notice("宝箱：获得 %d 瓶药水，溢出兑换 %d 金币" % [potions - previous, excess * 10])
	else:
		var item: Dictionary = inventory.make_weapon(level)
		item["salvage_value"] = level * 15
		for slot in get_weapon_limit():
			if inventory.items[slot] == null and inventory.can_equip(item, slot):
				inventory.equip(item, slot)
				show_notice("获得 %s" % inventory.item_name(item))
				return
		show_weapon_choice(item)


func use_potion() -> void:
	if potions <= 0:
		show_notice("没有药水")
		return
	if player.health_component.current_health >= player.health_component.max_health:
		show_notice("生命已满")
		return
	potions -= 1
	player.health_component.heal(player.health_component.max_health * 0.25)
	show_notice("使用药水：恢复 25% 最大生命")


func update_hud() -> void:
	var phase := "守塔 %d:%02d" % [floori(defense_time / 60.0), floori(defense_time) % 60] if defense_active else ("安全区收缩中" if shrinking else "下次缩圈 %d 秒" % ceili(maxf(SHRINK_INTERVAL - cycle_elapsed, 0.0)))
	status.text = "%s\n金币 %d · 药水 %d/%d\n武器：%s" % [phase, gold, potions, MAX_POTIONS, equipped_names()]
	if respawning:
		status.text += "\n复活倒计时：%d 秒" % ceili(respawn_left)
	if defense_active:
		var boss_status := "首领交战中" if not get_tree().get_nodes_in_group("boss").is_empty() else "首领 %d 秒" % ceili(maxf(boss_timer, 0.0))
		tower_status.text = "守护建筑 %.0f / %.0f · 下次补给 %d 秒 · %s" % [tower_health, tower_max_health, ceili(maxf(supply_time - defense_time, 0.0)), boss_status]
	else:
		var directions := ["东", "东南", "南", "西南", "西", "西北", "北", "东北"]
		var toward_center := tower.global_position - player.global_position
		var direction: String = directions[posmod(roundi(toward_center.angle() / (PI / 4.0)), 8)]
		tower_status.text = "中心建筑：%s · 距离 %d · 碰触开启守塔" % [direction, roundi(toward_center.length())]
	if notice_left > 0.0:
		instructions.text = notice
	else:
		var marker := nearest_interactable()
		if marker != null and marker.is_in_group("frontier_chest"):
			var weights: Array = inventory.CHEST_WEIGHTS[marker.level - 1]
			instructions.text = "E：%d级宝箱 · 武器白/绿/蓝/紫/橙 %d/%d/%d/%d/%d%%" % [marker.level, weights[0], weights[1], weights[2], weights[3], weights[4]]
		else:
			instructions.text = "E：使用铁匠铺" if marker != null else "E 互动 · Q 药水 · I 装备 · P 暂停"


func equipped_names() -> String:
	var names: Array[String] = []
	for item: Variant in inventory.items:
		if item != null:
			names.append(inventory.item_name(item))
	return " / ".join(names) if not names.is_empty() else "未装备"


func get_weapon_limit() -> int:
	return clampi(int(player.character.get("weapon_limit")), 1, 2)


func show_notice(text: String) -> void:
	notice = text
	notice_left = 3.0


func open_panel(title: String) -> VBoxContainer:
	if is_instance_valid(screen):
		screen.queue_free()
	screen = CanvasLayer.new()
	screen.layer = 40
	screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(screen)
	get_tree().paused = true
	var center := CenterContainer.new()
	screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	box.add_child(label)
	return box


func add_label(box: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)


func add_button(box: VBoxContainer, text: String, action: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(action)
	box.add_child(button)
	return button


func add_weapon_details(box: VBoxContainer, item: Dictionary) -> void:
	var tier: int = item.rarity
	var heading := Label.new()
	heading.text = "%s  ·  伤害 +%d%% / 范围 +%d%% / 冷却 -%d%%" % [inventory.item_name(item), (tier - 1) * 30, (tier - 1) * 8, (tier - 1) * 6]
	if item.id == "nine_treasure_pagoda":
		heading.text = "%s  ·  辅助强度随品质提升" % inventory.item_name(item)
	heading.add_theme_color_override("font_color", inventory.RARITY_COLORS[tier - 1])
	heading.add_theme_font_size_override("font_size", 12)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	for skill_id: String in item.skills:
		var skill: AbilityUpgrade = inventory.skill_resource(skill_id)
		var row := HBoxContainer.new()
		box.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = CARD.get_upgrade_icon(skill)
		row.add_child(icon)
		var text := Label.new()
		text.text = "%s：%s" % [skill.name, skill.description]
		text.add_theme_font_size_override("font_size", 10)
		row.add_child(text)


func show_weapon_choice(item: Dictionary) -> void:
	var box := open_panel("发现武器：选择替换的位置")
	add_weapon_details(box, item)
	for slot in get_weapon_limit():
		var current: String = "空" if inventory.items[slot] == null else inventory.item_name(inventory.items[slot])
		add_button(box, "装备至武器 %d：%s" % [slot + 1, current], equip_and_close.bind(item, slot), not inventory.can_equip(item, slot))
	add_button(box, "分解武器：获得 %d 金币" % int(item.get("salvage_value", 0)), salvage_weapon.bind(item))


func salvage_weapon(item: Dictionary) -> void:
	var amount := int(item.get("salvage_value", 0))
	gold += amount
	close_panel()
	show_notice("分解武器：获得 %d 金币" % amount)


func equip_and_close(item: Dictionary, slot: int) -> void:
	inventory.equip(item, slot)
	close_panel()
	show_notice("装备：%s" % inventory.item_name(item))


func show_inventory() -> void:
	var box := open_panel("当前装备")
	for slot in get_weapon_limit():
		if inventory.items[slot] != null:
			add_button(box, "武器 %d：%s" % [slot + 1, inventory.item_name(inventory.items[slot])], show_inventory_item.bind(slot))
	add_button(box, "关闭", close_panel)


func show_inventory_item(slot: int) -> void:
	var box := open_panel("武器 %d" % (slot + 1))
	add_weapon_details(box, inventory.items[slot])
	add_button(box, "返回", show_inventory)
	add_button(box, "关闭", close_panel)


func show_forge() -> void:
	var box := open_panel("铁匠铺 · 金币 %d" % gold)
	add_label(box, "选择武器进行升品质或洗练")
	add_button(box, "购买药水：30 金币", buy_potion, gold < 30 or potions >= MAX_POTIONS)
	if defense_active:
		add_button(box, "修复建筑 200 生命：50 金币", repair_tower, gold < 50 or tower_health >= tower_max_health)
	for slot in get_weapon_limit():
		if inventory.items[slot] != null:
			add_button(box, "武器 %d：%s" % [slot + 1, inventory.item_name(inventory.items[slot])], show_forge_item.bind(slot))
	add_button(box, "离开", close_panel)


func buy_potion() -> void:
	if gold >= 30 and potions < MAX_POTIONS:
		gold -= 30
		potions += 1
	show_forge()


func repair_tower() -> void:
	if defense_active and gold >= 50 and tower_health < tower_max_health:
		gold -= 50
		tower_health = minf(tower_max_health, tower_health + 200.0)
		if tower_health > tower_max_health * 0.25:
			tower_warned = false
	show_forge()


func show_forge_item(slot: int) -> void:
	var item: Dictionary = inventory.items[slot]
	var tier: int = item.rarity
	var upgrade_cost: int = [0, 60, 100, 160, 240, 0][tier]
	var reroll_cost := 20 + tier * 15
	var box := open_panel("铁匠铺 · 金币 %d" % gold)
	add_weapon_details(box, item)
	add_button(box, "品质升一级：%d 金币（保留技能并增加一条）" % upgrade_cost if tier < 5 else "已是橙色品质", buy_upgrade.bind(slot, upgrade_cost), tier >= 5 or gold < upgrade_cost)
	add_button(box, "洗练全部技能：%d 金币" % reroll_cost, buy_reroll.bind(slot, reroll_cost), gold < reroll_cost)
	add_button(box, "返回", show_forge)
	add_button(box, "离开", close_panel)


func buy_upgrade(slot: int, cost: int) -> void:
	var tier: int = inventory.items[slot].rarity
	var expected_cost: int = [0, 60, 100, 160, 240, 0][tier]
	if tier < 5 and cost == expected_cost and gold >= cost and inventory.upgrade(slot):
		gold -= cost
	show_forge_item(slot)


func buy_reroll(slot: int, cost: int) -> void:
	var expected_cost: int = 20 + int(inventory.items[slot].rarity) * 15
	if cost == expected_cost and gold >= cost and inventory.reroll(slot):
		gold -= cost
	show_forge_item(slot)


func close_panel() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
		screen = null
	get_tree().paused = false


func show_pause() -> void:
	var box := open_panel("暂停")
	add_button(box, "继续游戏", close_panel)
	add_button(box, "结束本局并结算", end_game.bind("主动结束"))
