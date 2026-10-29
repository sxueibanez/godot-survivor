extends Node2D


func make_enemy(point: Vector2) -> HealthComponent:
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	enemy.position = point
	add_child(enemy)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	enemy.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.health_component = health
	enemy.add_child(hurtbox)
	return health


func _ready() -> void:
	GameEvents.game_mode = "endless"
	GameEvents.critical_disabled = true
	var text_layer := Node2D.new()
	text_layer.add_to_group("floating_text_layer")
	add_child(text_layer)
	var narrow_target := make_enemy(Vector2.UP.rotated(deg_to_rad(30)) * 90.0)
	var wide_target := make_enemy(Vector2.UP.rotated(deg_to_rad(70)) * 90.0)
	var out_of_range := make_enemy(Vector2.UP * 105.0)
	var initial := narrow_target.current_health
	var scene := preload("res://scenes/ability/lightning_whip_ability/lightning_whip_ability.tscn")
	var whip := scene.instantiate() as LightningWhipAbility
	whip.direction = Vector2.UP
	whip.size_multiplier = 2.0
	add_child(whip)
	whip.set_physics_process(false)
	assert(is_equal_approx(whip.attack_half_angle, PI / 4.0))
	assert(whip.scale == Vector2(2.0, 2.0) and is_equal_approx(whip.rotation, -PI / 2.0))
	assert(is_equal_approx(narrow_target.current_health, initial - 8.0))
	assert(is_equal_approx(wide_target.current_health, initial))
	assert(is_equal_approx(out_of_range.current_health, initial))
	whip._physics_process(0.2)
	assert(is_equal_approx(whip.time_left, 0.2))
	whip.queue_free()
	var wide := scene.instantiate() as LightningWhipAbility
	wide.direction = Vector2.UP
	wide.size_multiplier = 2.0
	wide.wide_arc_enabled = true
	add_child(wide)
	assert(is_equal_approx(wide.attack_half_angle, PI / 2.0))
	assert(is_equal_approx(wide_target.current_health, initial - 8.0))
	assert(is_equal_approx(out_of_range.current_health, initial))
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	print("LIGHTNING_WHIP_FEEDBACK_OK")
	get_tree().quit()
