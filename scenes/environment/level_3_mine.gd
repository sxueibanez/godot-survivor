extends Node2D


const TILESET := preload("res://assets/environment/tilemap_packed.png")
const TRACK_TILE := Rect2(48, 48, 16, 16)


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
