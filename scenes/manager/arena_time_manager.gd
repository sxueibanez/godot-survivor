extends Node
class_name ArenaTimeManager

signal arena_difficulty_increased(arena_difficulty: int)

const DIFFICULTY_INTERVAL := 5

var arena_difficulty = 0
var time_elapsed := 0.0


func _ready() -> void:
	GameEvents.arena_difficulty = 0


func _process(delta):
	time_elapsed += delta
	while time_elapsed >= (arena_difficulty + 1) * DIFFICULTY_INTERVAL:
		arena_difficulty += 1
		GameEvents.arena_difficulty = arena_difficulty
		arena_difficulty_increased.emit(arena_difficulty)


func get_time_elapsed():
	return time_elapsed
