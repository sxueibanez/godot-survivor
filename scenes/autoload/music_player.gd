extends AudioStreamPlayer

@export var level_tracks: Array[AudioStream]
const SETTINGS_PATH := "user://options.cfg"
var settings_path := SETTINGS_PATH


func _ready() -> void:
	load_options()


func load_options() -> void:
	var config := ConfigFile.new()
	var error := config.load(settings_path)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("读取选项失败：%s" % error_string(error))
		return
	for bus_name: String in ["music", "sfx"]:
		if not config.has_section_key("audio", bus_name):
			continue
		var value: Variant = config.get_value("audio", bus_name)
		if (value is float or value is int) and is_finite(float(value)):
			var bus_index := AudioServer.get_bus_index(bus_name)
			if bus_index >= 0:
				AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(float(value), 0.0, 1.0)))
	if config.has_section_key("display", "fullscreen") and DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		var fullscreen: Variant = config.get_value("display", "fullscreen")
		if fullscreen is bool:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func save_options() -> void:
	var config := ConfigFile.new()
	var error := config.load(settings_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("读取选项失败，未覆盖原文件：%s" % error_string(error))
		return
	for bus_name: String in ["music", "sfx"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			config.set_value("audio", bus_name, clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0))
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		config.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	error = config.save(settings_path)
	if error != OK:
		push_warning("保存选项失败：%s" % error_string(error))


func play_level(level: int) -> void:
	var next_stream := level_tracks[clampi(level - 1, 0, level_tracks.size() - 1)]
	if stream == next_stream and playing:
		return
	stop()
	stream = next_stream
	volume_db = -8.0
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	play()
