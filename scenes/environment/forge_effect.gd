extends Node2D

const ART = preload("res://scenes/environment/forge_art.gd")
const EXPLOSION := preload("res://assets/abilities/bomb_explosion.png")
var kind := "fire"
var warning_time := 0.8
var active_time := 3.0
var elapsed := 0.0
var radius := 32.0
var direction := Vector2.RIGHT
var cone_angle := 1.1
var line_end := Vector2.ZERO
var shape := "circle"
var player_damage := 6.0
var enemy_damage := 12.0
var damage_interval := 0.5
var damage_source := "熔岩裂缝"
var hit_times: Dictionary = {}
var caster: Node2D
var owner_id := 0
var require_caster := false
var affect_enemies := false
var exploded := false
var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var death_actor := "cinder"
var flight_time := 0.0
var flight_elapsed := 0.0

func _ready() -> void:
	add_to_group("forge_effect")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if kind == "barrel":
		damage_source = "运火工的炸药桶"

func contains(point: Vector2, margin: float = 0.0) -> bool:
	var local := point - global_position
	if shape == "line":
		return Geometry2D.get_closest_point_to_segment(local, Vector2.ZERO, line_end).distance_to(local) <= radius + margin
	if local.length() > radius + margin:
		return false
	if shape == "cone":
		return absf(wrapf(local.angle() - direction.angle(), -PI, PI)) <= cone_angle * 0.5
	if kind == "wave":
		var wave_radius := radius * clampf((elapsed - warning_time) / active_time, 0.0, 1.0)
		return absf(local.length() - wave_radius) <= 12.0 + margin
	return true

func _process(delta: float) -> void:
	if get_tree().paused or is_queued_for_deletion():
		return
	if require_caster and (not is_instance_valid(caster) or caster.is_queued_for_deletion() or caster.get_node("HealthComponent").current_health <= 0):
		queue_free()
		return
	if kind == "barrel" and flight_elapsed < flight_time:
		flight_elapsed = minf(flight_elapsed + delta, flight_time)
		global_position = start_position.lerp(target_position, flight_elapsed / flight_time)
		queue_redraw()
		return
	elapsed += delta
	if kind not in ["slag", "barrel"] and elapsed >= warning_time + active_time:
		queue_free()
		return
	if kind == "slag":
		var progress := clampf(elapsed / warning_time, 0.0, 1.0)
		global_position = start_position.lerp(target_position, progress)
		if elapsed >= warning_time:
			spawn_fire()
			queue_free()
	elif kind == "barrel":
		if not exploded and elapsed >= warning_time:
			detonate()
		if exploded and elapsed >= warning_time + 0.35:
			queue_free()
	elif kind not in ["warning", "death", "steam"] and elapsed >= warning_time:
		apply_damage()
	if kind != "slag" and elapsed >= warning_time + active_time:
		queue_free()
	queue_redraw()

func apply_damage() -> void:
	var targets: Array[Node] = get_tree().get_nodes_in_group("player")
	if affect_enemies:
		targets.append_array(get_tree().get_nodes_in_group("enemy"))
	for target: Node2D in targets:
		if target.is_queued_for_deletion() or target.get_instance_id() == owner_id or not contains(target.global_position):
			continue
		var id := target.get_instance_id()
		if hit_times.has(id) and elapsed - float(hit_times[id]) < damage_interval:
			continue
		var health := target.get_node_or_null("HealthComponent") as HealthComponent
		if health == null or health.current_health <= 0:
			continue
		hit_times[id] = elapsed
		var amount := player_damage if target.is_in_group("player") else enemy_damage
		if target.is_in_group("boss") and damage_source == "熔岩裂缝":
			amount = minf(health.max_health * 0.004, 8.0)
		health.damage(amount, damage_source, global_position, "environment")

func detonate() -> void:
	if exploded:
		return
	exploded = true
	hit_times.clear()
	apply_damage()

func spawn_fire() -> void:
	var fires := 0
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "fire" and effect.owner_id == owner_id and not effect.is_queued_for_deletion():
			fires += 1
	if fires >= 6:
		return
	var fire := get_script().new() as Node2D
	fire.kind = "fire"
	fire.warning_time = 0.0
	fire.owner_id = owner_id
	fire.caster = caster
	fire.require_caster = true
	fire.damage_source = "熔炉暴君的熔渣"
	fire.player_damage = 12
	get_parent().add_child(fire)
	fire.global_position = target_position

func _draw() -> void:
	if kind == "barrel" and exploded:
		var frame := clampi(int((elapsed - warning_time) / 0.35 * 16), 0, 15)
		var cell := Vector2(EXPLOSION.get_width(), EXPLOSION.get_height()) / 4.0
		draw_texture_rect_region(EXPLOSION, Rect2(-radius, -radius, radius * 2, radius * 2), Rect2(Vector2(frame % 4, frame / 4) * cell, cell), Color(1, 0.8, 0.6))
		return
	if kind == "steam":
		draw_texture_rect_region(ART.texture("steam"), Rect2(-32, -64, 64, 64), Rect2(int(elapsed * 12) % 6 * 64, 0, 64, 64))
		return
	if kind == "death":
		var count := ART.frame_count(death_actor, "death")
		var height := 96.0 if death_actor == "tyrant" else 70.0 if death_actor == "guard" else 22.0 if death_actor == "cinder" else 30.0
		var frame := mini(int(elapsed / active_time * count), count - 1)
		draw_texture_rect(ART.frame_texture(death_actor, "death", frame), Rect2(-height / 2, -height + 8, height, height), false, Color(1, 1, 1, 1.0 - elapsed / active_time * 0.7))
		return
	if kind == "slag":
		var progress := clampf(elapsed / warning_time, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 5, Color(0.1, 0.05, 0.02, 0.4))
		var texture := ART.texture("slag")
		draw_texture_rect_region(texture, Rect2(-9, -9 - sin(progress * PI) * 75.0, 18, 18), Rect2(int(elapsed * 12) % 4 * 24, 0, 24, 24))
		return
	if kind == "barrel" and flight_elapsed < flight_time:
		var progress := flight_elapsed / flight_time
		var height := sin(progress * PI) * 72.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 10.0 * (1.0 - height / 144.0), Color(0.05, 0.02, 0.01, 0.45))
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(ART.texture("barrel"), Rect2(-12, -24 - height, 24, 24), false, Color.WHITE)
		return
	var warning := elapsed < warning_time
	var color := Color(1.0, 0.46, 0.06, 0.18 + sin(elapsed * 18.0) * 0.07) if warning else Color(1.0, 0.2, 0.03, 0.38)
	if kind == "warning":
		color = Color(1.0, 0.15, 0.03, 0.18)
	if shape == "line":
		draw_line(Vector2.ZERO, line_end, color, radius * 2)
		draw_line(Vector2.ZERO, line_end, Color(1, 0.6, 0.12), 2)
	elif shape == "cone":
		var points := PackedVector2Array([Vector2.ZERO])
		for index in 25:
			points.append(direction.rotated(-cone_angle / 2.0 + cone_angle * index / 24.0) * radius)
		draw_colored_polygon(points, color if warning else Color(1, 0.2, 0.03, 0.08))
		if warning:
			draw_polyline(points, Color(1.0, 0.7, 0.3, 0.8), 1.5)
	elif kind == "wave" and not warning:
		draw_arc(Vector2.ZERO, maxf(1, radius * (elapsed - warning_time) / active_time), 0, TAU, 48, Color(1, 0.6, 0.12), 5)
	else:
		draw_circle(Vector2.ZERO, radius, color)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1, 0.65, 0.18, 0.9), 1.5)
		if warning and warning_time > 0:
			draw_arc(Vector2.ZERO, radius - 3, -PI / 2, -PI / 2 + TAU * elapsed / warning_time, 48, Color(1, 0.18, 0.08), 2)
	if kind == "flame" and not warning:
		draw_set_transform(Vector2.ZERO, direction.angle())
		# The jet starts at 24/256 and ends near 220/256 in the generated cell.
		var length := radius * 256.0 / 196.0
		var width := radius * sin(cone_angle * 0.5) * 2.0
		draw_texture_rect(ART.fire_frame_texture("flame", int(elapsed * 12) % 6), Rect2(-length * 24.0 / 256.0, -width / 2, length, width), false)
		draw_set_transform(Vector2.ZERO)
	if kind == "barrel" and not exploded:
		draw_texture_rect(ART.texture("barrel"), Rect2(-12, -24, 24, 24), false, Color(1.0, 0.6 + sin(elapsed * 20) * 0.3, 0.5))
	elif not warning and kind in ["fire", "ember", "eruption"]:
		var count := maxi(2, ceili(line_end.length() / (radius * 1.4)) + 1) if shape == "line" else 1
		for index in count:
			var offset := line_end * float(index) / (count - 1) if shape == "line" else Vector2.ZERO
			var height := radius * 4.0 if kind == "eruption" else radius * 2.6
			var anchor := 210.0 / 256.0 if kind == "eruption" else 184.0 / 256.0
			draw_texture_rect(ART.fire_frame_texture(kind, (int(elapsed * 12) + index) % 6), Rect2(offset - Vector2(radius * 1.2, height * anchor), Vector2(radius * 2.4, height)), false)
