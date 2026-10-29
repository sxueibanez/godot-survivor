extends Node2D


func _ready() -> void:
	GameEvents.game_mode = "endless"
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	var avenger := preload("res://resources/characters/avenger.tres") as CharacterData
	player.set_character(avenger)
	var passives := player.get_node("CharacterPassives") as CharacterPassives
	var health := player.get_node("HealthComponent") as HealthComponent
	passives.set_process(false)
	health.set_process(false)
	health.damage(55.0)
	assert(passives.frenzy_left == 5.0 and passives.rage == 15.0)
	assert(passives.status.text.contains("储备 15/40"))
	health.damage(25.0)
	assert(passives.rage == 15.0) # Damage during frenzy does not add rage.
	health._process(5.0)
	passives._process(5.0)
	assert(passives.frenzy_left == 0.0 and passives.rage == 15.0)
	health.damage(25.0)
	assert(passives.frenzy_left == 5.0 and passives.rage == 0.0)

	player.set_character(avenger)
	health.damage(85.0)
	assert(passives.frenzy_left == 5.0 and passives.rage == 40.0)
	health._process(5.0)
	passives._process(5.0)
	assert(passives.frenzy_left == 5.0 and passives.rage == 0.0)
	assert(is_equal_approx(health.temporary_shield, health.max_health * 0.2))
	health._process(5.0)
	passives._process(5.0)
	assert(passives.frenzy_left == 0.0 and health.temporary_shield == 0.0)

	player.set_character(avenger)
	health.damage(health.max_health)
	assert(health.current_health == 0.0 and passives.frenzy_left == 0.0)
	print("AVENGER_RAGE_OVERFLOW_OK")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
