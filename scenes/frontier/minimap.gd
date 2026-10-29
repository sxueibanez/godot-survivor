extends Control

const MAP_SIZE := 88.0
const VIEW_RADIUS := 1000.0
const DRAW_RADIUS := 40.0

var mode: Node
var refresh_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -96.0
	offset_right = -8.0
	offset_top = 8.0
	offset_bottom = 96.0


func _process(delta: float) -> void:
	refresh_left -= delta
	if refresh_left <= 0.0:
		refresh_left = 0.1
		queue_redraw()


func in_view(world_point: Vector2) -> bool:
	return world_point.distance_squared_to(mode.player.global_position) <= VIEW_RADIUS * VIEW_RADIUS


func map_point(world_point: Vector2) -> Vector2:
	return Vector2.ONE * (MAP_SIZE / 2.0) + (world_point - mode.player.global_position) * (DRAW_RADIUS / VIEW_RADIUS)


func _draw() -> void:
	if not is_instance_valid(mode) or not is_instance_valid(mode.player):
		return
	var center := Vector2.ONE * (MAP_SIZE / 2.0)
	draw_circle(center, MAP_SIZE / 2.0, Color(0.04, 0.08, 0.07, 0.88))
	draw_circle(center, DRAW_RADIUS, Color(0.28, 0.38, 0.28, 0.8))
	for chest: Node2D in get_tree().get_nodes_in_group("frontier_chest"):
		if not chest.is_queued_for_deletion() and in_view(chest.global_position):
			var colors := [Color(0.9, 0.8, 0.6), Color(0.35, 0.8, 1.0), Color(1.0, 0.75, 0.2)]
			draw_rect(Rect2(map_point(chest.global_position) - Vector2(2, 2), Vector2(4, 4)), colors[chest.level - 1])
	for shop: Node2D in get_tree().get_nodes_in_group("frontier_shop"):
		if not shop.is_queued_for_deletion() and in_view(shop.global_position):
			draw_rect(Rect2(map_point(shop.global_position) - Vector2(2, 2), Vector2(4, 4)), Color(1.0, 0.4, 0.25))
	for boss: Node2D in get_tree().get_nodes_in_group("boss"):
		if not boss.is_queued_for_deletion() and in_view(boss.global_position):
			draw_circle(map_point(boss.global_position), 2.0, Color(1.0, 0.32, 0.32))
	var distance: float = mode.player.global_position.length()
	var radius: float = mode.safe_radius
	if distance + radius <= VIEW_RADIUS:
		draw_arc(map_point(Vector2.ZERO), radius * DRAW_RADIUS / VIEW_RADIUS, 0.0, TAU, 64, Color(0.4, 0.9, 1.0), 1.4, true)
	elif distance > 0.0 and absf(radius - VIEW_RADIUS) < distance and distance < radius + VIEW_RADIUS:
		var angle: float = mode.player.global_position.angle()
		var half_arc := acos(clampf((distance * distance + radius * radius - VIEW_RADIUS * VIEW_RADIUS) / (2.0 * distance * radius), -1.0, 1.0))
		draw_arc(map_point(Vector2.ZERO), radius * DRAW_RADIUS / VIEW_RADIUS, angle - half_arc, angle + half_arc, 48, Color(0.4, 0.9, 1.0), 1.4, true)
	if in_view(Vector2.ZERO):
		draw_circle(map_point(Vector2.ZERO), 3.0, Color(1.0, 0.83, 0.3))
	draw_circle(center, 3.0, Color.WHITE)
