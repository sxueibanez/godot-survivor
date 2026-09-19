extends Node
class_name CurseManager

const CURSE_INTERVAL := 90.0
const MAX_CURSES := 6
const CHOICE_COUNT := 3
const EMBER_WARNING := 0.45
const EMBER_DURATION := 1.5
const EMBER_RADIUS := 44.0
const GROUND_FIRE_INTERVAL := 8.0
const GROUND_FIRE_WARNING := 1.0
const GROUND_FIRE_DURATION := 2.5
const GROUND_FIRE_RADIUS := 52.0
const MAX_GROUND_FIRES := 3
const DAMAGE_TICK := 0.5
const SAFE_START_RADIUS := 300.0
const SAFE_MIN_RADIUS := 135.0
const SAFE_SHRINK_INTERVAL := 25.0
const SAFE_SHRINK_AMOUNT := 25.0
const EXPERIENCE_VIAL := preload("res://scenes/game_object/experience_vial/experience_vial.tscn")

var main: Node
var upgrade_manager: Node
var started := false
var combat_time := 0.0
var next_trigger_time := CURSE_INTERVAL
var offer_pending := false
var selected: Array[String] = []
var definitions: Dictionary = {}
var ground_fire_time := 0.0
var cooldown_scan_time := 0.0
var safe_zone: SafeZone
var early_boss_reward_pending := false


class DangerZone extends Node2D:
	var radius := 48.0
	var warning := 1.0
	var active_duration := 1.5
	var damage := 8.0
	var age := 0.0
	var tick_left := 0.0
	var ember := false

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		age += delta
		tick_left -= delta
		if age >= warning and tick_left <= 0.0:
			tick_left = DAMAGE_TICK
			deal_tick()
		if age >= warning + active_duration:
			queue_free()
		queue_redraw()

	func deal_tick() -> void:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and player.global_position.distance_to(global_position) <= radius:
			var health := player.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(damage, "诅咒余烬" if ember else "诅咒地火")
		for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
			if enemy.global_position.distance_to(global_position) > radius:
				continue
			var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
			if health != null and health.current_health > 0.0:
				if ember:
					enemy.set_meta("curse_ember_touched", true)
				health.damage(damage, "诅咒环境")

	func _draw() -> void:
		var progress := clampf(age / warning, 0.0, 1.0)
		if age < warning:
			draw_circle(Vector2.ZERO, radius, Color(0.9, 0.08, 0.02, 0.08 + progress * 0.2))
			draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color(1.0, 0.16, 0.04, 0.95), 3.0)
		else:
			var pulse := 0.65 + sin(age * 18.0) * 0.12
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.12, 0.01, 0.28))
			draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 36, Color(1.0, 0.62, 0.08, 0.9), 4.0)
			for index in 8:
				var direction := Vector2.RIGHT.rotated(index * TAU / 8.0 + age)
				draw_line(direction * radius * 0.35, direction * radius * 0.8, Color(1.0, 0.34, 0.02, 0.75), 3.0)


class SafeZone extends Node2D:
	var radius := SAFE_START_RADIUS
	var shrink_left := SAFE_SHRINK_INTERVAL
	var tick_left := DAMAGE_TICK

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		shrink_left -= delta
		tick_left -= delta
		if shrink_left <= 0.0:
			shrink_left = SAFE_SHRINK_INTERVAL
			radius = maxf(radius - SAFE_SHRINK_AMOUNT, SAFE_MIN_RADIUS)
		if tick_left <= 0.0:
			tick_left = DAMAGE_TICK
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player != null and player.global_position.distance_to(global_position) > radius:
				var health := player.get_node_or_null("HealthComponent") as HealthComponent
				if health != null:
					health.damage(7.0, "诅咒安全区")
		queue_redraw()

	func _draw() -> void:
		var outer := 1200.0
		for index in 48:
			var a := index * TAU / 48.0
			var b := (index + 1) * TAU / 48.0
			var points := PackedVector2Array([
				Vector2.RIGHT.rotated(a) * radius, Vector2.RIGHT.rotated(b) * radius,
				Vector2.RIGHT.rotated(b) * outer, Vector2.RIGHT.rotated(a) * outer])
			draw_colored_polygon(points, Color(0.82, 0.02, 0.04, 0.17))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.2, 0.95, 0.75, 0.95), 3.0)


func setup(owner_main: Node) -> void:
	main = owner_main
	upgrade_manager = main.get_node("UpgradeManager")
	add_to_group("curse_manager")
	build_definitions()
	GameEvents.enemy_defeated.connect(on_enemy_defeated)


func start() -> void:
	started = true


func _process(delta: float) -> void:
	if not started or selected.size() >= MAX_CURSES:
		return
	combat_time += delta
	if combat_time >= next_trigger_time:
		offer_pending = true
	if offer_pending and can_offer():
		show_offer()
	if GameEvents.has_curse("ground_fire"):
		ground_fire_time += delta
		if ground_fire_time >= GROUND_FIRE_INTERVAL:
			ground_fire_time = 0.0
			spawn_ground_fire()
	if GameEvents.has_curse("cooldown_freeze"):
		cooldown_scan_time += delta
		if cooldown_scan_time >= 0.25:
			cooldown_scan_time = 0.0
			apply_weapon_cooldowns()


func can_offer() -> bool:
	return not upgrade_manager.choice_screen_open and get_tree().get_nodes_in_group("boss").is_empty()


func show_offer() -> void:
	var choices := get_offer_choices()
	if upgrade_manager.show_external_choices(choices, apply_curse):
		offer_pending = false
		next_trigger_time += CURSE_INTERVAL


func get_offer_choices() -> Array[AbilityUpgrade]:
	var remaining: Array[String] = []
	for curse_id: String in definitions:
		if not selected.has(curse_id):
			remaining.append(curse_id)
	remaining.shuffle()
	var choices: Array[AbilityUpgrade] = []
	for index in mini(CHOICE_COUNT, remaining.size()):
		choices.append(definitions[remaining[index]])
	return choices


func build_definitions() -> void:
	add_definition("stampede", "狂奔兽潮", "普通敌人移速 +35%，生命 -20%\n补偿：经验 +50%")
	add_definition("iron_shell", "铁壳时代", "普通敌人生命 +50%，移速 -25%\n补偿：击杀有概率额外掉落经验")
	add_definition("death_ember", "死亡余烬", "普通敌人死亡留下预警余烬\n补偿：被余烬灼伤的敌人额外掉落经验")
	add_definition("elite_migration", "精英迁徙", "精英出现频率提高\n补偿：击杀精英必定额外升级一次")
	add_definition("ground_fire", "地火苏醒", "地图周期生成预警地火\n补偿：地火也会伤害敌人")
	add_definition("shrinking_safe_zone", "安全区收缩", "安全圈外持续受伤，范围逐渐缩小\n补偿：圈内经验 +75%")
	add_definition("glass_cannon", "玻璃大炮", "最大生命 -35%，武器伤害 +40%\n补偿：移速 +10%")
	add_definition("unhealed_wound", "伤口未愈", "禁用普通回血和常规治疗\n补偿：击杀精英或 Boss 恢复 20% 最大生命")
	add_definition("cooldown_freeze", "冷却冻结", "武器冷却 +25%，武器伤害 +35%\n补偿：经验 +25%")
	add_definition("dangerous_investment", "危险投资", "升级时可用 10% 生命换取 4 选 1\n补偿：下一次升级属性效果 +20%")
	add_definition("early_furnace", "提前开炉", "当前地图 Boss 提前 60 秒\n补偿：击败后额外升级并恢复 15% 最大生命")
	add_definition("summon_overflow", "召唤泛滥", "召唤冷却 -35%，数量 +50%\n补偿：召唤物生命 -40%")


func add_definition(id: String, title: String, description: String) -> void:
	var upgrade := AbilityUpgrade.new()
	upgrade.id = "curse_" + id
	upgrade.name = title
	upgrade.description = description
	upgrade.max_quantity = 1
	definitions[id] = upgrade


func apply_curse(choice: AbilityUpgrade) -> void:
	var curse_id := choice.id.trim_prefix("curse_")
	if selected.has(curse_id):
		return
	selected.append(curse_id)
	GameEvents.active_curses.append(curse_id)
	match curse_id:
		"stampede":
			change_normal_enemy_multipliers(0.8, 1.35)
			GameEvents.curse_experience_multiplier *= 1.5
		"iron_shell":
			change_normal_enemy_multipliers(1.5, 0.75)
		"elite_migration":
			GameEvents.curse_elite_interval_multiplier *= 0.5
			main.get_node("EnemyManager").restart_elite_timer()
		"shrinking_safe_zone":
			create_safe_zone()
		"glass_cannon":
			GameEvents.curse_player_health_multiplier *= 0.65
			GameEvents.curse_weapon_damage_multiplier *= 1.4
			GameEvents.curse_player_speed_multiplier *= 1.1
			refresh_player_stats()
		"unhealed_wound":
			GameEvents.curse_no_normal_healing = true
		"cooldown_freeze":
			GameEvents.curse_attack_interval_multiplier *= 1.25
			GameEvents.curse_weapon_damage_multiplier *= 1.35
			GameEvents.curse_experience_multiplier *= 1.25
			refresh_player_stats()
		"early_furnace":
			early_boss_reward_pending = true
			main.advance_current_boss(60.0)
		"summon_overflow":
			GameEvents.curse_summon_cooldown_multiplier = 0.65
			GameEvents.curse_summon_count_multiplier = 1.5
			GameEvents.curse_summon_health_multiplier = 0.6


func change_normal_enemy_multipliers(health_factor: float, speed_factor: float) -> void:
	GameEvents.curse_enemy_health_multiplier *= health_factor
	GameEvents.curse_enemy_speed_multiplier *= speed_factor
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_in_group("boss") or enemy.is_in_group("elite"):
			continue
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			var ratio := health.get_health_percent()
			health.max_health *= health_factor
			health.current_health = health.max_health * ratio
			health.health_changed.emit()
		var velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
		if velocity != null:
			velocity.max_speed *= speed_factor


func refresh_player_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.call("refresh_support_stats")
		player.call("refresh_missing_health_passive")


func on_enemy_defeated(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.is_in_group("boss"):
		cleanup_summons(enemy.get_instance_id())
		if GameEvents.has_curse("unhealed_wound"):
			heal_player(0.2)
		if early_boss_reward_pending:
			grant_early_boss_reward_if_clear.call_deferred()
		return
	if enemy.is_in_group("elite"):
		if GameEvents.has_curse("unhealed_wound"):
			heal_player(0.2)
		if GameEvents.has_curse("elite_migration"):
			upgrade_manager.show_upgrade_choices(3)
	if GameEvents.has_curse("death_ember") and not enemy.is_in_group("elite"):
		spawn_danger(enemy.global_position, true)
	if GameEvents.has_curse("iron_shell") and not enemy.is_in_group("elite") and randf() < 0.35:
		drop_experience(enemy.global_position)
	if bool(enemy.get_meta("curse_ember_touched", false)):
		drop_experience(enemy.global_position)


func heal_player(fraction: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var health := player.get_node_or_null("HealthComponent") as HealthComponent if player != null else null
	if health != null:
		health.heal(health.max_health * fraction, "curse_reward")


func grant_early_boss_reward_if_clear() -> void:
	if not early_boss_reward_pending:
		return
	for boss: Node in get_tree().get_nodes_in_group("boss"):
		var health := boss.get_node_or_null("HealthComponent") as HealthComponent
		if health != null and health.current_health > 0.0:
			return
	early_boss_reward_pending = false
	heal_player(0.15)
	upgrade_manager.show_upgrade_choices(3)


func drop_experience(point: Vector2) -> void:
	var layer := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if layer == null:
		return
	var vial := EXPERIENCE_VIAL.instantiate() as Node2D
	layer.add_child(vial)
	vial.global_position = point


func spawn_danger(point: Vector2, ember: bool = false) -> DangerZone:
	if ember and get_tree().get_nodes_in_group("curse_ember").size() >= 10:
		return null
	var layer := get_tree().get_first_node_in_group("ground_effects_layer") as Node2D
	if layer == null:
		return null
	var zone := DangerZone.new()
	zone.ember = ember
	zone.radius = EMBER_RADIUS if ember else GROUND_FIRE_RADIUS
	zone.warning = EMBER_WARNING if ember else GROUND_FIRE_WARNING
	zone.active_duration = EMBER_DURATION if ember else GROUND_FIRE_DURATION
	zone.damage = 7.0 if ember else 9.0
	zone.add_to_group("curse_effect")
	if ember:
		zone.add_to_group("curse_ember")
	layer.add_child(zone)
	zone.global_position = point
	return zone


func spawn_ground_fire() -> void:
	if get_tree().get_nodes_in_group("curse_ground_fire").size() >= MAX_GROUND_FIRES:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var angle := randf() * TAU
	var point := player.global_position + Vector2.RIGHT.rotated(angle) * randf_range(90.0, 220.0)
	var zone := spawn_danger(point)
	if zone != null:
		zone.add_to_group("curse_ground_fire")


func create_safe_zone() -> void:
	var layer := get_tree().get_first_node_in_group("ground_effects_layer") as Node2D
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if layer == null or player == null:
		return
	safe_zone = SafeZone.new()
	safe_zone.add_to_group("curse_effect")
	layer.add_child(safe_zone)
	safe_zone.global_position = player.global_position


func experience_multiplier_at(point: Vector2) -> float:
	if is_instance_valid(safe_zone) and point.distance_to(safe_zone.global_position) <= safe_zone.radius:
		return 1.75
	return 1.0


func apply_weapon_cooldowns() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var abilities := player.get_node_or_null("Abilities") if player != null else null
	if abilities == null:
		return
	for timer in find_timers(abilities):
		# These systems already own the timer and include the curse factor themselves.
		if timer.has_meta("pagoda_applied_wait") or timer.has_meta("challenge_base_wait"):
			continue
		var applied := float(timer.get_meta("curse_applied_wait", -1.0))
		if applied < 0.0 or not is_equal_approx(timer.wait_time, applied):
			timer.set_meta("curse_base_wait", timer.wait_time)
		var target := float(timer.get_meta("curse_base_wait")) * GameEvents.curse_attack_interval_multiplier
		timer.wait_time = target
		timer.set_meta("curse_applied_wait", target)


func find_timers(root: Node) -> Array[Timer]:
	var result: Array[Timer] = []
	for child: Node in root.get_children():
		if child is Timer:
			result.append(child as Timer)
		result.append_array(find_timers(child))
	return result


func cleanup_summons(summoner_id: int) -> void:
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if int(enemy.get_meta("summoner_id", -1)) == summoner_id:
			enemy.queue_free()


func on_map_changed() -> void:
	for effect: Node in get_tree().get_nodes_in_group("curse_effect"):
		effect.queue_free()
	if GameEvents.has_curse("shrinking_safe_zone"):
		create_safe_zone.call_deferred()
	ground_fire_time = 0.0
