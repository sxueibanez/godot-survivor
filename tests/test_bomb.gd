extends Node


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var bomb_upgrade := load("res://resources/upgrades/bomb.tres") as Ability
	assert(bomb_upgrade != null and bomb_upgrade.weapon_type == Ability.WeaponType.RANGED)
	assert((load("res://resources/upgrades/bomb_bounce.tres") as AbilityUpgrade).max_quantity == 3)
	assert(load("res://resources/upgrades/bomb_burn.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/bomb_cluster.tres") is AbilityUpgrade)
	assert(is_equal_approx(BombAbility.get_child_damage(100.0), 30.0))
	assert(is_equal_approx(BombAbility.get_burn_damage(100.0), 60.0))
	assert(is_equal_approx(BombAbilityController.BASE_RADIUS, 30.0))
	var controller := BombAbilityController.new()
	assert(is_equal_approx(controller.base_damage, 15.0))
	controller.free()
	var enemies: Array = []
	for enemy_position: Vector2 in [Vector2(10, 10), Vector2(20, 10), Vector2(200, 200)]:
		var enemy := Node2D.new()
		enemy.position = enemy_position
		add_child(enemy)
		enemies.append(enemy)
	assert(BombAbilityController.find_densest_enemy(enemies) == enemies[0])
	var foreground := Node2D.new()
	add_child(foreground)
	var bomb := load("res://scenes/ability/bomb_ability/bomb_ability.tscn").instantiate() as BombAbility
	bomb.configure(Vector2.ZERO, Vector2.RIGHT, 100.0, 30.0, 2, true, true)
	foreground.add_child(bomb)
	assert((bomb.get_node("ExplosionSound") as AudioStreamPlayer2D).stream != null)
	var previous_target := Node2D.new()
	previous_target.position = Vector2(20, 0)
	previous_target.add_to_group("enemy")
	add_child(previous_target)
	var near_target := Node2D.new()
	near_target.position = Vector2(0, 100)
	near_target.add_to_group("enemy")
	add_child(near_target)
	var far_target := Node2D.new()
	far_target.position = Vector2(BombAbility.BOUNCE_TARGET_RANGE + 1.0, 0)
	far_target.add_to_group("enemy")
	add_child(far_target)
	assert(bomb.find_bounce_target() == near_target.global_position)
	near_target.remove_from_group("enemy")
	assert(bomb.find_bounce_target() != far_target.global_position)
	bomb.spawn_cluster_bombs()
	assert(foreground.get_child_count() == 6)
	bomb.spawn_bounce()
	assert(foreground.get_child_count() == 7)
	var bounced_bomb := foreground.get_child(6) as BombAbility
	assert(bounced_bomb.bounce_remaining == 1 and bounced_bomb.cluster_enabled)
	previous_target.remove_from_group("enemy")
	far_target.remove_from_group("enemy")
	foreground.add_to_group("foreground_layer")
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var boss := Node2D.new()
	boss.position = Vector2(40, 0)
	boss.add_to_group("enemy")
	boss.add_to_group("boss")
	var health := HealthComponent.new()
	health.max_health = 1000.0
	boss.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.health_component = health
	boss.add_child(hurtbox)
	add_child(boss)
	var boss_controller := load("res://scenes/ability/bomb_ability_controller/bomb_ability_controller.tscn").instantiate() as BombAbilityController
	add_child(boss_controller)
	boss_controller.get_node("Timer").stop()
	var bomb_count := foreground.get_child_count()
	boss_controller.on_timer_timeout()
	assert(foreground.get_child_count() == bomb_count + 1, "Only a boss remains: bomb must still launch")
	var boss_bomb := foreground.get_child(bomb_count) as BombAbility
	assert(boss_bomb.target_position == boss.global_position)
	var health_before := health.current_health
	boss_bomb.global_position = boss.global_position
	boss_bomb.damage_enemies()
	assert(health.current_health < health_before, "Bomb explosion must damage bosses")
	get_tree().quit()
