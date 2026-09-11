extends Node


func _ready() -> void:
	var slime := preload("res://scenes/game_object/stone_slime/stone_slime.tscn").instantiate()
	add_child(slime)
	await get_tree().process_frame
	var constants := slime.get_script().get_script_constant_map()
	assert(constants["FRAME_COLUMNS"].size() == 5)
	assert(constants["FRAME_ROWS"].size() == 3)
	assert(is_equal_approx(constants["WARNING_DURATION"], 0.55))
	assert(is_equal_approx(constants["CHARGE_SPEED"], 280.0))
	slime.set("animation_time", 0.0)
	slime.call("animate", 0.125)
	assert((slime.get_node("Visuals/Sprite2D") as Sprite2D).region_rect.position.x == 328.0)
	slime.set("animation_time", 0.0)
	slime.call("animate", 0.125, 3.0)
	assert((slime.get_node("Visuals/Sprite2D") as Sprite2D).region_rect.position.x == 933.0)
	var target := Node2D.new()
	target.add_to_group("enemy")
	add_child(target)
	var target_velocity := VelocityComponent.new()
	target_velocity.name = "VelocityComponent"
	target.add_child(target_velocity)
	slime.set("charge_direction", Vector2.RIGHT)
	slime.call("knockback_enemies")
	assert(target_velocity.knockback_time_left > 0.0)
	assert(slime.get("knocked_enemies").size() == 1)
	target_velocity.knockback_time_left = 0.0
	slime.call("knockback_enemies")
	assert(target_velocity.knockback_time_left == 0.0)
	assert((slime.get_node("HealthComponent") as HealthComponent).max_health == 72.0)
	get_tree().quit()
