extends Node2D


const TILESET := preload("res://assets/environment/tilemap_packed.png")
const TRACK_TILE := Rect2(48, 48, 16, 16)
const CART_INTERVAL := 16.0
const CART_START_DELAY := 6.0

var cart_time := CART_START_DELAY


class Minecart extends Node2D:
	const WARNING_TIME := 1.2
	const SPEED := 340.0
	const TRACK_LENGTH := 1408.0
	const HIT_RADIUS := 22.0
	const DAMAGE := 12.0
	var direction := 1.0
	var elapsed := 0.0
	var travelled := 0.0
	var hit_player := false


	func _init(new_direction: float = 1.0) -> void:
		direction = 1.0 if new_direction >= 0.0 else -1.0


	func _ready() -> void:
		z_as_relative = false
		z_index = -5


	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			queue_free()
			return
		elapsed += delta
		if elapsed >= WARNING_TIME:
			var moving_time := minf(delta, elapsed - WARNING_TIME)
			var previous := global_position
			var distance := minf(SPEED * moving_time, TRACK_LENGTH - travelled)
			global_position.x += direction * distance
			travelled += distance
			check_player(previous, global_position)
			if travelled >= TRACK_LENGTH:
				queue_free()
		queue_redraw()


	func check_player(from: Vector2, to: Vector2) -> void:
		if hit_player or elapsed < WARNING_TIME:
			return
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return
		var closest := Geometry2D.get_closest_point_to_segment(player.global_position, from, to)
		if closest.distance_squared_to(player.global_position) > HIT_RADIUS * HIT_RADIUS:
			return
		var health := player.get_node_or_null("HealthComponent") as HealthComponent
		if health == null or health.current_health <= 0.0:
			return
		hit_player = true
		health.damage(DAMAGE, "失控矿车")
		var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
		if movement != null:
			movement.apply_knockback(Vector2(direction, 0.0), 240.0, 0.25)


	func _draw() -> void:
		if elapsed < WARNING_TIME:
			var pulse := 0.16 + 0.12 * absf(sin(elapsed * 8.0))
			draw_line(Vector2.ZERO, Vector2(direction * TRACK_LENGTH, 0.0), Color(1.0, 0.5, 0.15, pulse), HIT_RADIUS * 2.0)
			draw_line(Vector2.ZERO, Vector2(direction * TRACK_LENGTH, 0.0), Color(1.0, 0.8, 0.35, 0.8), 1.5)
			for distance in range(80, int(TRACK_LENGTH), 120):
				var base := Vector2(direction * distance, 0.0)
				var tip := base + Vector2(direction * 10.0, 0.0)
				draw_line(tip, base + Vector2(0, -6), Color(1.0, 0.8, 0.35, 0.8), 1.5)
				draw_line(tip, base + Vector2(0, 6), Color(1.0, 0.8, 0.35, 0.8), 1.5)
			return
		draw_rect(Rect2(-17, -11, 34, 22), Color(0.42, 0.25, 0.16))
		draw_rect(Rect2(-14, -8, 28, 12), Color(0.72, 0.48, 0.28))
		draw_circle(Vector2(-10, 12), 4.0, Color(0.12, 0.1, 0.1))
		draw_circle(Vector2(10, 12), 4.0, Color(0.12, 0.1, 0.1))
		draw_line(Vector2(direction * 8, 0), Vector2(direction * 16, 0), Color(1.0, 0.8, 0.35), 3.0)


func _ready() -> void:
	visibility_changed.connect(on_visibility_changed)


func on_visibility_changed() -> void:
	if not is_visible_in_tree():
		for child in get_children():
			if child is Minecart:
				child.queue_free()
		cart_time = CART_START_DELAY


func _process(delta: float) -> void:
	if not is_visible_in_tree() or get_tree().get_first_node_in_group("player") == null:
		return
	cart_time -= delta
	if cart_time <= 0.0:
		var direction := 1.0 if randf() < 0.5 else -1.0
		var cart := Minecart.new(direction)
		add_child(cart)
		cart.global_position = Vector2(-128.0 if direction > 0.0 else 1280.0, 384.0)
		cart_time = CART_INTERVAL


func _draw() -> void:
	draw_track(Vector2(-128, 384), Vector2(1280, 384))
	draw_track(Vector2(0, 784), Vector2(1152, 784))
	draw_track(Vector2(496, -128), Vector2(496, 1056))


func draw_track(start: Vector2, end: Vector2) -> void:
	var direction := start.direction_to(end)
	var crossbar := direction.rotated(PI * 0.5) * 12.0
	draw_line(start + crossbar, end + crossbar, Color("5d4a3b"), 4.0)
	draw_line(start - crossbar, end - crossbar, Color("5d4a3b"), 4.0)
	for distance in range(0, int(start.distance_to(end)), 24):
		var tie := start + direction * distance
		draw_line(tie - crossbar * 1.4, tie + crossbar * 1.4, Color("8a5e35"), 5.0)
		draw_texture_rect_region(TILESET, Rect2(tie - Vector2(8, 8), Vector2(16, 16)), TRACK_TILE, Color("c69b60"))
