extends SceneTree


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	root.add_child(foreground)

	var enemy := make_enemy(Vector2(100, 0))
	var second_enemy := make_enemy(Vector2(90, 40))

	var whip := preload("res://scenes/ability/lightning_whip_ability/lightning_whip_ability.tscn").instantiate() as LightningWhipAbility
	root.add_child(whip)
	assert((enemy.get_node("HealthComponent") as HealthComponent).current_health == 92.0)
	assert((second_enemy.get_node("HealthComponent") as HealthComponent).current_health == 92.0)
	assert((enemy.get_node("VelocityComponent") as VelocityComponent).slow_multiplier == 0.75)
	quit()


func make_enemy(position: Vector2) -> Node2D:
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	enemy.global_position = position
	root.add_child(enemy)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	enemy.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.health_component = health
	enemy.add_child(hurtbox)
	var velocity := VelocityComponent.new()
	velocity.name = "VelocityComponent"
	enemy.add_child(velocity)
	return enemy
