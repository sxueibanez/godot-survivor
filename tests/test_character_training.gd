extends Node

func _ready() -> void:
	MetaProgression.save_data = {"meta_upgrade_currency": 100, "meta_upgrades": {}, "weapon_skills": {}, "unlocked_weapons": {"sword": true}, "character_upgrades": {"warrior": {"health": 2, "speed": 1}}}
	MetaProgression.save()
	MetaProgression.load_save_file()
	assert(MetaProgression.save_data.meta_upgrade_currency == 175)
	MetaProgression.load_save_file()
	assert(MetaProgression.save_data.meta_upgrade_currency == 175)
	assert(not MetaProgression.purchase_character_upgrade("warrior", "health"))
	assert(MetaProgression.purchase_character_upgrade("ronin", "signature"))
	assert(MetaProgression.save_data.meta_upgrade_currency == 155)
	MetaProgression.load_save_file()
	assert(MetaProgression.get_character_upgrade("ronin", "signature") == 1)
	assert(MetaProgression.get_character_upgrade("warrior", "signature") == 0)
	var player := preload("res://scenes/game_object/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	var passives: CharacterPassives = player.character_passives
	passives.set_process(false)
	var enemy := Node2D.new()
	add_child(enemy)
	enemy.add_to_group("elite")
	player.set_character(load("res://resources/characters/ronin.tres"))
	passives.dash_cooldown_left = 2.0
	passives.attack_bonus_left = 1.0
	passives.on_enemy_defeated(enemy)
	assert(is_equal_approx(passives.dash_cooldown_left, 1.9))
	passives.attack_bonus_left = 0
	passives.on_enemy_defeated(enemy)
	assert(is_equal_approx(passives.dash_cooldown_left, 1.9))
	for id: String in MetaProgression.CHARACTER_IDS:
		MetaProgression.save_data.character_upgrades[id] = {"signature": 1}
	player.set_character(load("res://resources/characters/warrior.tres"))
	passives.on_enemy_defeated(enemy)
	assert(player.health_component.temporary_shield > 0)
	player.set_character(load("res://resources/characters/elf_ranger.tres"))
	for i in 5: passives.on_enemy_defeated(enemy)
	assert(is_equal_approx(passives.get_damage_multiplier(""), 1.1))
	assert(is_equal_approx(passives.get_damage_multiplier(""), 1.0))
	player.set_character(load("res://resources/characters/blooddrinker.tres"))
	player.health_component.current_health = 30
	passives.on_enemy_defeated(enemy)
	assert(player.health_component.current_health > 30)
	player.set_character(load("res://resources/characters/lone_gunner.tres"))
	passives.danger_cooldown_left = 4
	passives.on_enemy_defeated(enemy)
	assert(is_equal_approx(passives.danger_cooldown_left, 3.5))
	player.set_character(load("res://resources/characters/gambling_scholar.tres"))
	player.health_component.current_health = 100
	assert(passives.spend_reroll_health())
	assert(is_equal_approx(player.health_component.current_health, 86.0))
	player.set_character(load("res://resources/characters/avenger.tres"))
	passives.start_frenzy()
	passives.on_enemy_defeated(enemy)
	assert(is_equal_approx(passives.frenzy_left, 5.1))
	player.set_character(load("res://resources/characters/one_armed.tres"))
	for i in 10: passives.on_enemy_defeated(enemy)
	assert(is_equal_approx(passives.get_damage_multiplier(""), 1.575))
	var menu := preload("res://scenes/ui/character_training.gd").new()
	add_child(menu)
	assert(menu.buttons.size() == 1)
	menu.select_character(1)
	assert(menu.selected == 1)
	print("CHARACTER_SIGNATURE_TRAINING_OK")
	get_tree().quit()
