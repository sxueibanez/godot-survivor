extends Node


func _ready() -> void:
	var king := preload("res://scenes/game_object/slime_king/slime_king.tscn").instantiate()
	add_child(king)
	king.call("show_frame", load("res://assets/enemies/slime_king_jump.png"), 7)
	var sprite := king.get_node("Visuals/Sprite2D") as Sprite2D
	assert(sprite.texture == load("res://assets/enemies/slime_king_jump.png"))
	assert(sprite.region_rect == Rect2(1331, 444, 443, 443))
	var player := Node2D.new()
	player.add_to_group("player")
	player.position = Vector2(40, 0)
	add_child(player)
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	add_child(foreground)
	await king.call("perform_triple_jump")
	assert(not king.performing_ability)
	get_tree().quit()
