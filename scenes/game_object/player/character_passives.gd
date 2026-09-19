extends Node
class_name CharacterPassives

var player: CharacterBody2D
var health: HealthComponent
var character: CharacterData
var speed_multiplier := 1.0
var solitude_multiplier := 1.0
var danger_nearby := false
var danger_cooldown_left := 0.0
var danger_boost_left := 0.0
var scan_left := 0.0
var dash_left := 0.0
var dash_cooldown_left := 0.0
var attack_bonus_left := 0.0
var dash_direction := Vector2.RIGHT
var last_direction := Vector2.RIGHT
var rage := 0.0
var frenzy_left := 0.0
var status: Label
var skill_icon: TextureRect
var cooldown_label: Label


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	health = player.get_node("HealthComponent") as HealthComponent
	health.damage_taken.connect(on_damage_taken)
	GameEvents.enemy_defeated.connect(on_enemy_defeated)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	status = Label.new()
	hud.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status.offset_left = 56.0
	status.offset_top = -76.0
	status.offset_right = 620.0
	status.offset_bottom = -48.0
	status.add_theme_font_size_override("font_size", 12)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_icon = TextureRect.new()
	hud.add_child(skill_icon)
	skill_icon.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skill_icon.offset_left = 8.0
	skill_icon.offset_top = -84.0
	skill_icon.offset_right = 48.0
	skill_icon.offset_bottom = -44.0
	skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skill_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	cooldown_label = Label.new()
	skill_icon.add_child(cooldown_label)
	cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 12)
	cooldown_label.add_theme_constant_override("outline_size", 3)
	cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(data: CharacterData) -> void:
	character = data
	speed_multiplier = 1.0
	solitude_multiplier = 1.0
	danger_nearby = false
	danger_cooldown_left = 0.0
	danger_boost_left = 0.0
	scan_left = 0.0
	dash_left = 0.0
	dash_cooldown_left = 0.0
	attack_bonus_left = 0.0
	rage = 0.0
	frenzy_left = 0.0
	health.set_temporary_shield(0.0, 0.0)
	update_status()


func _process(delta: float) -> void:
	if character == null or health.current_health <= 0.0:
		return
	danger_cooldown_left = maxf(danger_cooldown_left - delta, 0.0)
	danger_boost_left = maxf(danger_boost_left - delta, 0.0)
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	attack_bonus_left = maxf(attack_bonus_left - delta, 0.0)
	frenzy_left = maxf(frenzy_left - delta, 0.0)
	var movement: Vector2 = player.call("get_movement_vector")
	if movement != Vector2.ZERO:
		last_direction = movement.normalized()
	if character.id == "lone_gunner":
		scan_left -= delta
		if scan_left <= 0.0:
			scan_left = 0.2
			scan_enemies()
		var new_speed := character.danger_speed_multiplier if danger_boost_left > 0.0 else 1.0
		if new_speed != speed_multiplier:
			speed_multiplier = new_speed
			player.call("refresh_missing_health_passive")
	update_status()


func scan_enemies() -> void:
	var nearby := 0
	var danger := false
	# ponytail: scan at 5 Hz; add spatial queries only if profiling shows enemy counts require it.
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var enemy_health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if enemy_health != null and enemy_health.current_health <= 0.0:
			continue
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance <= character.nearby_enemy_radius * character.nearby_enemy_radius:
			nearby += 1
		if distance <= character.danger_radius * character.danger_radius and (enemy.is_in_group("elite") or enemy.is_in_group("boss")):
			danger = true
	solitude_multiplier = 1.0 + maxi(character.solitude_enemy_cap - nearby, 0) * character.solitude_bonus_per_enemy
	if danger and not danger_nearby and danger_cooldown_left <= 0.0:
		danger_boost_left = character.danger_duration
		danger_cooldown_left = character.danger_cooldown
	danger_nearby = danger


func get_damage_multiplier(weapon_id: String) -> float:
	if character == null:
		return 1.0
	if character.id == "one_armed":
		return 1.5
	if character.id == "lone_gunner" and int(GameEvents.weapon_types.get(weapon_id, -1)) == Ability.WeaponType.RANGED:
		return solitude_multiplier
	if character.id == "avenger" and frenzy_left > 0.0:
		return character.rage_damage_multiplier
	return 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_dash") and not event.is_echo() and try_dash():
		get_viewport().set_input_as_handled()


func try_dash() -> bool:
	if character == null or character.id != "ronin" or get_tree().paused or health.current_health <= 0.0 or dash_cooldown_left > 0.0:
		return false
	var movement := player.get_node("VelocityComponent") as VelocityComponent
	if movement.stun_time_left > 0.0 or movement.knockback_time_left > 0.0:
		return false
	var direction: Vector2 = player.call("get_movement_vector")
	dash_direction = last_direction if direction == Vector2.ZERO else direction.normalized()
	dash_left = maxf(character.dash_duration, 0.01)
	dash_cooldown_left = character.dash_cooldown
	attack_bonus_left = character.dash_attack_window
	return true


func move_dash(delta: float) -> void:
	if delta <= 0.0:
		return
	var movement := player.get_node("VelocityComponent") as VelocityComponent
	if movement.stun_time_left > 0.0 or movement.knockback_time_left > 0.0:
		dash_left = 0.0
		return
	player.velocity = dash_direction * character.dash_distance / maxf(character.dash_duration, 0.01) * minf(delta, dash_left) / delta
	player.move_and_slide()
	dash_left = maxf(dash_left - delta, 0.0)
	if dash_left <= 0.0:
		movement.velocity = Vector2.ZERO


func get_damage_bonus() -> float:
	if character == null or character.id != "ronin" or attack_bonus_left <= 0.0:
		return 0.0
	return character.dash_damage_bonus


func spend_reroll_health() -> bool:
	return character != null and character.id == "gambling_scholar" and health.spend_health(health.current_health * character.health_reroll_fraction)


func on_enemy_defeated(enemy: Node2D) -> void:
	if character != null and character.id == "gambling_scholar" and enemy.is_in_group("elite") and health.current_health > 0.0:
		health.heal(health.max_health * character.elite_heal_fraction, "elite_reward")


func on_damage_taken(amount: float) -> void:
	if character == null or character.id != "avenger" or frenzy_left > 0.0 or health.current_health <= 0.0:
		return
	rage += amount
	if rage >= maxf(character.rage_damage_threshold, 0.01):
		rage = 0.0
		frenzy_left = character.rage_duration
		health.set_temporary_shield(health.max_health * character.rage_shield_fraction, character.rage_duration)
	update_status()


func update_status() -> void:
	if status == null or character == null:
		return
	match character.id:
		"lone_gunner":
			status.text = "远程 +%.0f%%" % [(solitude_multiplier - 1.0) * 100.0]
		"avenger":
			status.text = "狂怒 %.1fs · 护盾 %.0f" % [frenzy_left, health.temporary_shield] if frenzy_left > 0.0 else "怒气 %.0f/%.0f" % [rage, character.rage_damage_threshold]
		_:
			status.text = ""
	skill_icon.visible = true
	skill_icon.texture = character.sprite if character.sprite != null else preload("res://scenes/game_object/player/player.png")
	skill_icon.tooltip_text = "%s\n%s" % [character.display_name, character.passive_description]
	var cooldown := dash_cooldown_left if character.id == "ronin" else danger_cooldown_left
	var has_cooldown := character.id in ["ronin", "lone_gunner"]
	skill_icon.self_modulate = Color(0.45, 0.45, 0.45) if has_cooldown and cooldown > 0.0 else Color.WHITE
	cooldown_label.text = ("%.1f" % cooldown if cooldown > 0.0 else "就绪") if has_cooldown else "被动"
