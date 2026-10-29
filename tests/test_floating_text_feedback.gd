extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var scene := load("res://scenes/ui/floating_text.tscn") as PackedScene
	var normal := scene.instantiate() as FloatingText
	var critical := scene.instantiate() as FloatingText
	root.add_child(normal)
	root.add_child(critical)
	normal.start("10")
	critical.start("20", true)
	assert(normal.get_node("Label").text == "10")
	assert(critical.get_node("Label").text == "20")
	assert(normal.get_node("Label").get_theme_color("font_color") == Color.WHITE)
	assert(critical.get_node("Label").get_theme_color("font_color") == Color(1.0, 0.85, 0.15))
	await create_timer(0.35).timeout
	assert(normal.position.y < 0.0 and abs(normal.position.x) <= 12.0)
	assert(critical.position.y < 0.0 and abs(critical.position.x) <= 12.0)
	assert(critical.scale.x > normal.scale.x)
	await create_timer(0.6).timeout
	assert(not is_instance_valid(normal) and not is_instance_valid(critical))
	print("FLOATING_TEXT_FEEDBACK_OK")
	call_deferred("quit")
