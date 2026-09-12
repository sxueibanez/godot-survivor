extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var music_player := get_root().get_node("MusicPlayer") as AudioStreamPlayer
	for level in [2, 3]:
		music_player.play_level(level)
		await process_frame
		assert(music_player.stream.resource_path.ends_with("level_%d_bgm.ogg" % level))
		assert(music_player.playing)
	quit()
