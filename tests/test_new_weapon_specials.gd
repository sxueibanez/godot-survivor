extends Node

const Paralysis = preload("res://scenes/ability/lightning_paralysis.gd")


func _ready() -> void:
	var player_projectiles := Node2D.new()
	player_projectiles.add_to_group("player_projectiles_layer")
	player_projectiles.add_to_group("foreground_layer")
	add_child(player_projectiles)
	var floating_texts := Node2D.new()
	floating_texts.add_to_group("floating_text_layer")
	add_child(floating_texts)
	var combat_effects := Node2D.new()
	combat_effects.add_to_group("combat_effects_layer")
	add_child(combat_effects)
	var enemy := CharacterBody2D.new()
	enemy.position = Vector2(20, 0)
	enemy.add_to_group("enemy")
	add_child(enemy)
	var health := HealthComponent.new()
	health.max_health = 1000.0
	enemy.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	hurtbox.health_component = health
	enemy.add_child(hurtbox)
	var velocity := VelocityComponent.new()
	velocity.name = "VelocityComponent"
	enemy.add_child(velocity)

	var bomb := load("res://scenes/ability/bomb_ability/bomb_ability.tscn").instantiate() as BombAbility
	bomb.configure(Vector2.ZERO, Vector2.ZERO, 0.0, 30.0, 0, false, false)
	bomb.implosion_enabled = true
	player_projectiles.add_child(bomb)
	bomb.global_position = Vector2.ZERO
	bomb.damage_enemies()
	assert(is_equal_approx(enemy.position.x, 10.0))
	enemy.position = Vector2(20, 0)
	enemy.add_to_group("boss")
	bomb.damage_enemies()
	assert(is_equal_approx(enemy.position.x, 20.0))
	enemy.remove_from_group("boss")

	assert(Paralysis.try_apply(enemy, true, 0.2))
	assert(is_equal_approx(velocity.stun_time_left, 0.5))
	velocity.stun_time_left = 0.0
	assert(not Paralysis.try_apply(enemy, true, 0.2001))
	assert(not Paralysis.try_apply(enemy, false, 0.0))

	enemy.position = Vector2(42, 0)
	var hammer := load("res://scenes/ability/heaven_shaking_hammer/heaven_shaking_hammer.tscn").instantiate() as HeavenShakingHammerAbility
	hammer.configure(Vector2.ZERO, Vector2(42, 0), 10.0, 20.0, 0)
	hammer.aftershock_enabled = true
	player_projectiles.add_child(hammer)
	hammer.spawn_shockwaves()
	assert(combat_effects.get_child_count() == 2)
	var aftershock := combat_effects.get_child(1) as HeavenShakingHammerShockwave
	assert(is_equal_approx(aftershock.damage, 3.0))
	assert(is_equal_approx(aftershock.radius, 30.0))

	for resource_name in ["bomb_implosion", "lightning_paralysis", "heaven_shaking_hammer_aftershock"]:
		var upgrade := load("res://resources/upgrades/%s.tres" % resource_name) as AbilityUpgrade
		assert(upgrade != null and upgrade.max_quantity == 1)
		assert(upgrade.description.length() < 30)
		assert(AbilityUpgradeCard.get_upgrade_icon(upgrade) != null)
	var manager_script = load("res://scenes/manager/upgrade_manager.gd")
	assert(manager_script != null and manager_script.can_instantiate())
	var tree_script = load("res://scenes/ui/weapon_skill_tree.gd")
	assert(tree_script.WEAPON_SKILLS.bomb.any(func(skill): return skill.id == "tree_bomb_implosion"))
	assert(tree_script.WEAPON_SKILLS.lightning_whip.any(func(skill): return skill.id == "tree_lightning_paralysis"))
	assert(tree_script.WEAPON_SKILLS.heaven_shaking_hammer.any(func(skill): return skill.id == "tree_heaven_shaking_hammer_aftershock"))
	print("New weapon specials passed: bomb pull, boss immunity, paralysis threshold, hammer 30% damage / 1.5x radius, resources and tree.")
	get_tree().quit()
