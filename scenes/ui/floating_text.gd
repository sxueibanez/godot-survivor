extends Node2D
class_name FloatingText

static var visual_rng := RandomNumberGenerator.new()


func start(text: String, is_critical: bool = false):
	$Label.text = text
	$Label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15) if is_critical else Color.WHITE)

	# Spread simultaneous hits so their numbers are easier to read.
	var destination := global_position + Vector2(visual_rng.randf_range(-12.0, 12.0), -48.0)
	var peak_scale := 1.7 if is_critical else 1.25
	scale = Vector2.ONE * 0.7

	var movement = create_tween()
	movement.tween_property(self, "global_position", destination, 0.75) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	movement.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.45)
	movement.tween_callback(queue_free)

	var pop = create_tween()
	pop.tween_property(self, "scale", Vector2.ONE * peak_scale, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop.tween_property(self, "scale", Vector2.ONE * (1.2 if is_critical else 1.0), 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
