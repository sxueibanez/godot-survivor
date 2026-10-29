extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var layer := Node2D.new()
	layer.add_to_group("combat_effects_layer")
	add_child(layer)
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	add_child(enemy)
	var health := HealthComponent.new()
	health.max_health = 100.0
	enemy.add_child(health)
	var image := Sprite2D.new()
	enemy.add_child(image)
	var flash := preload("res://scenes/component/hit_flash_component.tscn").instantiate()
	flash.health_component = health
	flash.sprite = image
	enemy.add_child(flash)
	var shader := image.material as ShaderMaterial
	assert(shader != flash.hit_flash_material)
	health.heal(5.0)
	assert(flash.hit_flash_tween == null and layer.get_child_count() == 0)
	var initial := health.current_health
	health.damage(initial * 0.25, "", Vector2(-10, 0), "direct", "bomb")
	assert(is_equal_approx(health.current_health, initial * 0.75) and layer.get_child_count() == 1, "health=%s initial=%s effects=%d" % [health.current_health, initial, layer.get_child_count()])
	var spark := layer.get_child(0)
	assert(spark.weapon_id == "bomb" and spark.strong and spark.direction == Vector2.RIGHT)
	assert(spark.sprite.texture != null and flash.hit_flash_tween != null)
	health.damage(1.0)
	assert(layer.get_child_count() == 1)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var player_health := HealthComponent.new()
	player_health.max_health = 100.0
	player.add_child(player_health)
	player_health.set_shield(10.0)
	player_health.damage(5.0)
	assert(player_health.current_health == 100.0 and layer.get_child_count() == 2)
	assert(layer.get_child(1).weapon_id == "shield")
	await get_tree().create_timer(0.3).timeout
	assert(layer.get_child_count() == 0)
	health.set_invulnerable(1.0)
	health.damage(1.0)
	assert(layer.get_child_count() == 0)
	health.invulnerable_time_left = 0.0
	for index in 40:
		var dummy := Node2D.new()
		dummy.add_to_group("impact_spark")
		layer.add_child(dummy)
	health.damage(1.0)
	assert(layer.get_child_count() == 40)
	print("COMBAT_VISUALS_OK")
	get_tree().quit()
