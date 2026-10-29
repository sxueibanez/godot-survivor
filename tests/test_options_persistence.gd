extends Node


func _ready() -> void:
	var old_path: String = MusicPlayer.settings_path
	var temp_path := "user://options_test_%d.cfg" % Time.get_ticks_usec()
	MusicPlayer.settings_path = temp_path
	var music := AudioServer.get_bus_index("music")
	var sfx := AudioServer.get_bus_index("sfx")
	assert(music >= 0 and sfx >= 0)
	var old_music := AudioServer.get_bus_volume_db(music)
	var old_sfx := AudioServer.get_bus_volume_db(sfx)
	MusicPlayer.load_options()
	assert(AudioServer.get_bus_volume_db(music) == old_music and AudioServer.get_bus_volume_db(sfx) == old_sfx)
	assert(not FileAccess.file_exists(temp_path))
	var config := ConfigFile.new()
	config.set_value("other", "preserve", "yes")
	assert(config.save(temp_path) == OK)
	AudioServer.set_bus_volume_db(music, linear_to_db(0.25))
	AudioServer.set_bus_volume_db(sfx, linear_to_db(0.75))
	MusicPlayer.save_options()
	AudioServer.set_bus_volume_db(music, 0.0)
	AudioServer.set_bus_volume_db(sfx, 0.0)
	MusicPlayer.load_options()
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.25))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(sfx)), 0.75))
	config = ConfigFile.new()
	assert(config.load(temp_path) == OK and config.get_value("other", "preserve") == "yes")
	config.set_value("audio", "music", "invalid")
	config.set_value("audio", "sfx", 2.0)
	assert(config.save(temp_path) == OK)
	MusicPlayer.load_options()
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.25))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(sfx)), 1.0))
	AudioServer.set_bus_volume_db(sfx, linear_to_db(0.75))
	MusicPlayer.save_options()
	var options := preload("res://scenes/ui/options_menu.tscn").instantiate() as OptionsMenu
	add_child(options)
	await get_tree().process_frame
	assert(options.music_label.text == "音乐音量 25%")
	assert(options.sfx_label.text == "音效音量 75%")
	options.music_slider.value = 0.38
	options.sfx_slider.value = 0.0
	assert(options.music_label.text == "音乐音量 38%")
	assert(options.sfx_label.text == "音效音量 0%")
	config = ConfigFile.new()
	assert(config.load(temp_path) == OK)
	assert(is_equal_approx(config.get_value("audio", "music"), 0.38))
	assert(is_zero_approx(config.get_value("audio", "sfx")))
	assert(config.get_value("other", "preserve") == "yes")
	options.queue_free()
	AudioServer.set_bus_volume_db(music, old_music)
	AudioServer.set_bus_volume_db(sfx, old_sfx)
	MusicPlayer.settings_path = old_path
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path)) == OK)
	await get_tree().process_frame
	print("OPTIONS_PERSISTENCE_OK")
	get_tree().quit()
