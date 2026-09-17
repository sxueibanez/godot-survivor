extends CanvasLayer

const MAP_NAMES := ["暮色平原", "幽影荒原", "赤铜矿坑", "霜冻雪原", "熔火铸炉"]

@export var arena_time_manager: Node
@onready var label = %Label
var map_name: String = MAP_NAMES[0]


func set_map(map_id: int) -> void:
	map_name = MAP_NAMES[clampi(map_id - 1, 0, MAP_NAMES.size() - 1)]

func _process(delta):
	if arena_time_manager == null:
		return

	var time_elapsed = arena_time_manager.get_time_elapsed()
	label.text = "%s   %s" % [map_name, format_seconds_to_string(time_elapsed)]


func format_seconds_to_string(seconds: float) -> String:
	var minutes = floor(seconds / 60)
	var remaining_seconds = floor(seconds - (minutes * 60))
	return "%d:%02d" % [minutes, remaining_seconds]
