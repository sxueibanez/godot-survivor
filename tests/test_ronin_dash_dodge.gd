extends Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "endless"
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	player.set_character(load("res://resources/characters/ronin.tres"))
	var passives := player.get_node("CharacterPassives") as CharacterPassives
	passives.set_process(false)
	var health := player.get_node("HealthComponent") as HealthComponent
	health.set_process(false)
	var movement := player.get_node("VelocityComponent") as VelocityComponent
	movement.set_process(false)
	var before := health.current_health
	health.set_shield(20.0)
	get_tree().paused = true
	assert(not passives.try_dash())
	get_tree().paused = false
	assert(passives.try_dash() and player.is_dash_invulnerable())
	assert(passives.status.text == "冲刺免伤")
	health.damage(12.0)
	assert(health.current_health == before and health.shield == 20.0)
	passives.move_dash(0.05)
	assert(player.is_dash_invulnerable())
	health.damage(12.0)
	assert(health.current_health == before and health.shield == 20.0)
	passives.move_dash(0.2)
	assert(not player.is_dash_invulnerable())
	health.damage(12.0)
	assert(health.shield == 8.0)
	passives.dash_cooldown_left = 0.0
	assert(passives.try_dash())
	movement.apply_stun(0.5)
	assert(not player.is_dash_invulnerable())
	passives.move_dash(0.01)
	assert(passives.dash_left == 0.0)
	health.damage(3.0)
	assert(health.shield == 5.0)
	movement.stun_time_left = 0.0
	passives.dash_cooldown_left = 0.0
	assert(passives.try_dash())
	movement.apply_knockback(Vector2.RIGHT, 100.0, 0.5)
	assert(not player.is_dash_invulnerable())
	health.damage(2.0)
	assert(health.shield == 3.0)
	passives.move_dash(0.01)
	assert(passives.dash_left == 0.0)
	movement.knockback_time_left = 0.0
	passives.dash_cooldown_left = 0.0
	health.set_invulnerable(3.0)
	assert(passives.try_dash())
	player.set_character(load("res://resources/characters/warrior.tres"))
	assert(not player.is_dash_invulnerable() and is_equal_approx(health.invulnerable_time_left, 3.0))
	var shield_before := health.shield
	health.damage(3.0)
	assert(health.shield == shield_before)
	health._process(3.0)
	health.damage(3.0)
	assert(health.shield == shield_before - 3.0)
	print("RONIN_DASH_DODGE_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
