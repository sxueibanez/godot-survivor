extends Node

const STREAK_WINDOW := 4.0
const SHIELD_INTERVAL := 12
const SHIELD_FRACTION := 0.05
const SHIELD_CAP_FRACTION := 0.15

var streak := 0
var best_streak := 0
var kills := 0
var time_left := 0.0
var status: Label


func _ready() -> void:
	GameEvents.enemy_defeated.connect(on_enemy_defeated)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	status = Label.new()
	hud.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status.offset_left = 12.0
	status.offset_right = 230.0
	status.offset_top = -125.0
	status.offset_bottom = -85.0
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_constant_override("outline_size", 3)
	status.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.1))
	status.add_theme_color_override("font_color", Color(1.0, 0.83, 0.45))
	update_status()


func _process(delta: float) -> void:
	if time_left > 0.0:
		time_left = maxf(time_left - delta, 0.0)
		if time_left <= 0.0:
			streak = 0
		update_status()


func on_enemy_defeated(enemy: Node2D) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or player.is_queued_for_deletion():
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health == null or health.current_health <= 0.0:
		return
	var points := 5 if enemy.is_in_group("boss") else (3 if enemy.is_in_group("elite") else 1)
	var previous := streak
	streak += points
	kills += 1
	best_streak = maxi(best_streak, streak)
	time_left = STREAK_WINDOW
	var rewards := floori(streak / float(SHIELD_INTERVAL)) - floori(previous / float(SHIELD_INTERVAL))
	if rewards > 0 and health.shield < health.max_health * SHIELD_CAP_FRACTION:
		health.set_shield(minf(health.shield + health.max_health * SHIELD_FRACTION * rewards, health.max_health * SHIELD_CAP_FRACTION))
	update_status()


func update_status() -> void:
	if streak > 0:
		status.text = "连击 %d · %.1fs\n护盾 +5%%：%d/%d" % [streak, time_left, streak % SHIELD_INTERVAL, SHIELD_INTERVAL]
	else:
		status.text = "击败 %d · 连击最高 %d" % [kills, best_streak]
