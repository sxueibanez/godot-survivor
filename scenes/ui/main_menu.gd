extends CanvasLayer


var options_scene = preload("res://scenes/ui/options_menu.tscn")


func _ready():
	MusicPlayer.play_level(1)
	%PlayButton.pressed.connect(on_play_pressed)
	%EndlessButton.pressed.connect(on_endless_pressed)
	%BossRushButton.pressed.connect(on_boss_rush_pressed)
	%ExpeditionButton.pressed.connect(on_expedition_pressed)
	%FrontierButton.pressed.connect(on_frontier_pressed)
	for child: Node in %PlayButton.get_parent().get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size", 14)
	var character_button := preload("res://scenes/ui/sound_button.tscn").instantiate() as Button
	character_button.text = "角色培养"
	character_button.add_theme_font_size_override("font_size", 14)
	%UpgradesButton.get_parent().add_child(character_button)
	%UpgradesButton.get_parent().move_child(character_button, %UpgradesButton.get_index() + 1)
	character_button.pressed.connect(on_character_upgrades_pressed)
	%UpgradesButton.pressed.connect(on_upgrades_pressed)
	%WeaponSkillsButton.pressed.connect(on_weapon_skills_pressed)
	%OptionsButton.pressed.connect(on_options_pressed)
	%QuitButton.pressed.connect(on_quit_pressed)


func on_play_pressed():
	GameEvents.game_mode = "campaign"
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func on_endless_pressed():
	GameEvents.game_mode = "endless"
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func on_boss_rush_pressed():
	GameEvents.game_mode = "boss_rush"
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func on_expedition_pressed():
	GameEvents.game_mode = "expedition"
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func on_frontier_pressed():
	GameEvents.game_mode = "frontier"
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/frontier/frontier.tscn")


func on_upgrades_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/ui/meta_menu.tscn")


func on_character_upgrades_pressed():
	var panel := preload("res://scenes/ui/character_training.gd").new()
	add_child(panel)


func on_weapon_skills_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/ui/weapon_skill_tree.tscn")


func on_options_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway

	var options_instance = options_scene.instantiate() as OptionsMenu
	add_child(options_instance)
	options_instance.back_pressed.connect(on_options_closed.bind(options_instance))

	
func on_quit_pressed():
	get_tree().quit()


func on_options_closed(options_instance: OptionsMenu):
	options_instance.queue_free()
