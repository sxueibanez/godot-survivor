extends CanvasLayer


var options_scene = preload("res://scenes/ui/options_menu.tscn")


func _ready():
	%PlayButton.pressed.connect(on_play_pressed)
	%EndlessButton.pressed.connect(on_endless_pressed)
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


func on_upgrades_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/ui/meta_menu.tscn")


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
