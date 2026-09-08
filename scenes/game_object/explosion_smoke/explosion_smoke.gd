extends Node2D

const DURATION := 0.75


func _ready() -> void:
	scale = Vector2.ONE * 0.6
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(queue_free)
