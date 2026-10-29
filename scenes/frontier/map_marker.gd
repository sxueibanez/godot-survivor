extends Node2D

var kind := "chest"
var level := 1


func _draw() -> void:
	if kind == "shop":
		draw_rect(Rect2(-14, -11, 28, 22), Color(0.43, 0.24, 0.15))
		draw_colored_polygon(PackedVector2Array([Vector2(-17, -10), Vector2(0, -22), Vector2(17, -10)]), Color(0.85, 0.38, 0.22))
		draw_rect(Rect2(-3, -7, 6, 12), Color(1.0, 0.78, 0.35))
	else:
		var colors := [Color(0.65, 0.42, 0.24), Color(0.35, 0.7, 0.9), Color(1.0, 0.72, 0.18)]
		var color: Color = colors[clampi(level, 1, 3) - 1]
		draw_rect(Rect2(-11, -8, 22, 16), Color(0.16, 0.11, 0.08))
		draw_rect(Rect2(-9, -6, 18, 12), color)
		draw_line(Vector2(-9, -1), Vector2(9, -1), Color(0.18, 0.12, 0.08), 2.0)
		draw_rect(Rect2(-2, -3, 4, 5), Color(1.0, 0.9, 0.6))
