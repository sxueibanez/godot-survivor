extends Node


func _ready() -> void:
	var vial := preload("res://scenes/game_object/health_vial/health_vial.tscn").instantiate()
	add_child(vial)
	var sprite := vial.get_node("Sprite2D") as Sprite2D
	await get_tree().create_timer(0.3).timeout
	assert(sprite.position.y < -0.5 and sprite.position.y > -3.1)
	assert(vial.position == Vector2.ZERO)
	print("HEALTH_VIAL_BOB_OK")
	get_tree().quit()
