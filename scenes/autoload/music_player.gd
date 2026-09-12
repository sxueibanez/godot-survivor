extends AudioStreamPlayer

@export var level_tracks: Array[AudioStream]


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
