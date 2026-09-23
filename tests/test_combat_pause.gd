extends SceneTree


func _initialize() -> void:
	var actor := Node.new()
	actor.add_to_group("player")
	root.add_child(actor)
	var health := HealthComponent.new()
	health.max_health = 10.0
	actor.add_child(health)

	paused = true
	assert(not health.damage(4.0, "测试伤害"))
	assert(health.current_health == 10.0)
	paused = false
	health.damage(4.0, "测试伤害")
	assert(health.current_health == 6.0)

	var knight := preload("res://scenes/game_object/lightning_knight/lightning_knight.tscn").instantiate()
	root.add_child(knight)
	knight.attacking = true
	GameEvents.ability_upgrade_added.emit(null, {})
	assert(knight.attacking)
	quit()
