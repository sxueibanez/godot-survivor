extends Node2D

const PATCH_INTERVAL := 2.4
const WIND_INTERVAL := 8.0

var patch_time := 0.4
var wind_time := 4.0


class IcePatch extends Node2D:
	var time_left := 7.0

	func _process(delta: float) -> void:
		time_left -= delta
		modulate.a = minf(time_left, 1.0)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and global_position.distance_squared_to(player.global_position) <= 42.0 * 42.0:
			var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
			if movement != null:
				movement.apply_slippery(0.2)
		if time_left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 42.0, Color(0.4, 0.82, 1.0, 0.18))
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 20, Color(0.78, 0.96, 1.0, 0.48), 1.5)
		for index in 5:
			var point := Vector2.RIGHT.rotated(index * TAU / 5.0) * 24.0
			draw_line(point - Vector2(7, 0), point + Vector2(7, 0), Color(0.8, 0.95, 1.0, 0.45), 1.0)


class WindWarning extends Node2D:
	var direction: Vector2
	var elapsed := 0.0

	func _init(new_direction: Vector2) -> void:
		direction = new_direction

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= 1.0:
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player != null:
				var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
				if movement != null:
					movement.apply_knockback(direction, 135.0, 0.42)
			queue_free()

	func _draw() -> void:
		var alpha := 0.35 + sin(elapsed * 24.0) * 0.18
		for offset in [-70.0, -24.0, 24.0, 70.0]:
			var start: Vector2 = direction.orthogonal() * float(offset) - direction * 150.0
			draw_line(start, start + direction * 300.0, Color(0.75, 0.94, 1.0, alpha), 3.0)


func _process(delta: float) -> void:
	if not visible:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	patch_time -= delta
	wind_time -= delta
	if patch_time <= 0.0:
		var patch := IcePatch.new()
		add_child(patch)
		patch.global_position = player.global_position + Vector2(randf_range(-190.0, 190.0), randf_range(-120.0, 120.0))
		patch_time = PATCH_INTERVAL
	if wind_time <= 0.0:
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var warning := WindWarning.new(direction)
		add_child(warning)
		warning.global_position = player.global_position
		wind_time = WIND_INTERVAL


func _draw() -> void:
	draw_rect(Rect2(-2048, -2048, 4096, 4096), Color(0.3, 0.62, 0.78, 0.18))
	for x in range(-1600, 1601, 160):
		for y in range(-1600, 1601, 160):
			var center := Vector2(x + (y % 3) * 18, y)
			draw_arc(center, 34.0, 0.2, 2.4, 8, Color(0.72, 0.92, 1.0, 0.18), 1.0)
