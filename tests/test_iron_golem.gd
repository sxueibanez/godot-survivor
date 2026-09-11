extends Node


func _ready() -> void:
	var golem := preload("res://scenes/game_object/iron_golem/iron_golem.tscn").instantiate()
	add_child(golem)
	await get_tree().process_frame
	var constants := golem.get_script().get_script_constant_map()
	assert(is_equal_approx(constants["WINDUP_DURATION"], 0.8))
	assert(constants["RUN_FRAME_EDGES"].size() == 9)
	assert(constants["RUN_FRAME_ANCHORS"].size() == 8)
	assert(constants["ATTACK_FRAME_EDGES"].size() == 10)
	assert(constants["ATTACK_FRAME_ANCHORS"].size() == 9)
	assert((golem.get_node("Visuals/Sprite2D") as Sprite2D).region_enabled)
	assert((golem.get_node("HealthComponent") as HealthComponent).max_health == 95.0)
	get_tree().quit()
