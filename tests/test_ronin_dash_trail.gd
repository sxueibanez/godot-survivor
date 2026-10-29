extends Node


func _ready() -> void:
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	player.set_character(load("res://resources/characters/ronin.tres"))
	var passives := player.get_node("CharacterPassives") as CharacterPassives
	passives.set_process(false)
	assert(passives.try_dash())
	passives.move_dash(0.05)
	var trail := get_child(get_child_count() - 1) as Sprite2D
	assert(trail != null and trail.texture == player.get_node("Visuals/Sprite2D").texture)
	assert(trail.modulate.a < 1.0 and trail.z_index == -1)
	await get_tree().create_timer(0.35).timeout
	assert(not is_instance_valid(trail))
	print("RONIN_DASH_TRAIL_OK")
	get_tree().quit()
