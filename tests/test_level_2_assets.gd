extends SceneTree


func _init() -> void:
	assert(load("res://scenes/main/main.tscn") is PackedScene)
	assert(load("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn") is PackedScene)
	assert(load("res://scenes/game_object/ranged_enemy/ranged_enemy.tscn") is PackedScene)
	assert(load("res://scenes/game_object/arcane_projectile/arcane_projectile.tscn") is PackedScene)
	assert(load("res://scenes/game_object/lightning_knight/lightning_knight.tscn") is PackedScene)
	assert(load("res://assets/enemies/exploder_enemy.png") is Texture2D)
	assert(load("res://assets/enemies/ranged_enemy.png") is Texture2D)
	assert(load("res://assets/enemies/arcane_projectile.png") is Texture2D)
	assert(load("res://assets/enemies/explosion_smoke.png") is Texture2D)
	assert(load("res://assets/enemies/lightning_knight.png") is Texture2D)
	for frame_index in 9:
		assert(load("res://assets/enemies/lightning_knight_walk_%d.png" % frame_index) is Texture2D)
	var knight_scene := load("res://scenes/game_object/lightning_knight/lightning_knight.tscn") as PackedScene
	var knight: Node = knight_scene.instantiate()
	var walk_sprite := knight.get_node("Visuals/Sprite2D") as AnimatedSprite2D
	assert(walk_sprite.sprite_frames.get_frame_count(&"walk") == 9)
	assert(load("res://scenes/game_object/explosion_smoke/explosion_smoke.tscn") is PackedScene)
	assert(load("res://scenes/ui/player_stats_panel.tscn") is PackedScene)
	assert(load("res://resources/upgrades/laser_gun_damage_ramp.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/laser_gun_reflect.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/laser_gun_stun.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/critical_hit.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/axe_reflect.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/axe_distance_power.tres") is AbilityUpgrade)
	assert(is_equal_approx(AxeAbility.get_distance_multiplier(0.0), 1.0))
	assert(is_equal_approx(AxeAbility.get_distance_multiplier(100.0), 2.0))
	assert(is_equal_approx(AxeAbility.get_distance_multiplier(200.0), 2.0))
	assert(load("res://resources/upgrades/sword_chain.tres") is AbilityUpgrade)
	var sword := load("res://scenes/ability/sword_ability/sword_ability.tscn").instantiate() as Node2D
	assert((sword.get_node("HitboxComponent") as Area2D).collision_mask == 32)
	assert(load("res://scenes/main/main.tscn") is PackedScene)
	var velocity := VelocityComponent.new()
	velocity.apply_stun(0.5)
	assert(is_equal_approx(velocity.stun_time_left, 0.5))
	GameEvents.critical_chance = 1.0
	var critical_hit: Dictionary = GameEvents.get_critical_damage(10.0)
	assert(critical_hit["critical"] and is_equal_approx(critical_hit["damage"], 20.0))
	quit()
