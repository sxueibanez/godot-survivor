extends Node2D

const HALF_SIZE := 3200.0
const ROCK_COUNT := 320
const SAFE_CENTER_RADIUS := 390.0

var rocks: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


class Rock extends StaticBody2D:
	var radius := 24.0

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)

	func _draw() -> void:
		draw_circle(Vector2(2, 4), radius + 2, Color(0.08, 0.12, 0.11, 0.3))
		draw_circle(Vector2.ZERO, radius, Color(0.27, 0.32, 0.30))
		draw_arc(Vector2.ZERO, radius - 2, PI, TAU, 20, Color(0.57, 0.61, 0.53), 2.0)


func generate(start_position: Vector2) -> void:
	for index in ROCK_COUNT:
		for attempt in 50:
			var point := Vector2(rng.randf_range(-HALF_SIZE + 80, HALF_SIZE - 80), rng.randf_range(-HALF_SIZE + 80, HALF_SIZE - 80))
			var radius := rng.randf_range(18.0, 32.0)
			if point.length() < SAFE_CENTER_RADIUS or point.distance_to(start_position) < 160.0 or not is_clear(point, radius + 12.0):
				continue
			var rock := Rock.new()
			rock.radius = radius
			rock.position = point
			add_child(rock)
			rocks.append({"position": point, "radius": radius})
			break
	for side in 4:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 0
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(HALF_SIZE * 2.0 + 80.0, 40.0) if side < 2 else Vector2(40.0, HALF_SIZE * 2.0 + 80.0)
		collision.shape = rectangle
		wall.position = [Vector2(0, -HALF_SIZE - 20), Vector2(0, HALF_SIZE + 20), Vector2(-HALF_SIZE - 20, 0), Vector2(HALF_SIZE + 20, 0)][side]
		wall.add_child(collision)
		add_child(wall)
	queue_redraw()


func is_clear(point: Vector2, margin: float = 20.0) -> bool:
	if absf(point.x) > HALF_SIZE - margin or absf(point.y) > HALF_SIZE - margin:
		return false
	for rock: Dictionary in rocks:
		if point.distance_squared_to(rock.position) < pow(float(rock.radius) + margin, 2):
			return false
	return true


func _draw() -> void:
	draw_rect(Rect2(-HALF_SIZE, -HALF_SIZE, HALF_SIZE * 2.0, HALF_SIZE * 2.0), Color(0.25, 0.35, 0.27))
	for index in range(-int(HALF_SIZE / 100.0), int(HALF_SIZE / 100.0) + 1):
		var coordinate := index * 100.0
		draw_line(Vector2(-HALF_SIZE, coordinate), Vector2(HALF_SIZE, coordinate), Color(0.32, 0.43, 0.31, 0.22), 1.0)
		draw_line(Vector2(coordinate, -HALF_SIZE), Vector2(coordinate, HALF_SIZE), Color(0.32, 0.43, 0.31, 0.22), 1.0)
	draw_arc(Vector2.ZERO, SAFE_CENTER_RADIUS - 10.0, 0.0, TAU, 96, Color(0.5, 0.65, 0.45, 0.3), 2.0)
