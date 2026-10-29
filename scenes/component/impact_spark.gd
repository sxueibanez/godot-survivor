extends Node2D

const DURATION := 0.25
const TEXTURE := preload("res://assets/effects/impact_spark.png")

var weapon_id := ""
var strong := false
var direction := Vector2.RIGHT
var elapsed := 0.0
var sprite: Sprite2D
var tint := Color.WHITE


func _ready() -> void:
	add_to_group("impact_spark")
	match weapon_id:
		"lightning_whip", "thunder_orb_book", "shield":
			tint = Color(0.55, 0.85, 1.0)
		"bomb":
			tint = Color(1.0, 0.52, 0.24)
		"sniper_rifle", "player":
			tint = Color(1.0, 0.63, 0.46)
		_:
			tint = Color(1.0, 0.93, 0.72)
	sprite = Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.modulate = tint
	sprite.rotation = direction.angle()
	add_child(sprite)
	update_visual()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
		return
	update_visual()


func update_visual() -> void:
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	var size := 84.0 if strong else 62.0
	sprite.scale = Vector2.ONE * size / TEXTURE.get_width() * lerpf(0.55, 1.1, progress)
	sprite.modulate.a = 1.0 - progress * progress
	queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	var color := Color(tint, (1.0 - progress) * 0.8)
	var radius := (5.0 + 13.0 * progress) * (1.35 if strong else 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, color, 1.2, true)
	for index in 4:
		var ray := direction.rotated(index * PI / 2.0)
		draw_line(ray * radius * 0.55, ray * radius * 1.3, color, 1.5, true)
