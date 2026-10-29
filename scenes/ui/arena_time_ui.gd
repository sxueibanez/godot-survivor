extends CanvasLayer

const MAP_NAMES := ["暮色平原", "幽影荒原", "赤铜矿坑", "霜冻雪原", "熔火铸炉"]

@export var arena_time_manager: Node
@export var game_state: Node
@onready var label = %Label
@onready var boss_countdown: Label = %BossCountdown
var map_name: String = MAP_NAMES[0]
var notification_text := ""
var notification_time_left := 0.0


func set_map(map_id: int) -> void:
	map_name = MAP_NAMES[clampi(map_id - 1, 0, MAP_NAMES.size() - 1)]

func _process(delta):
	update_boss_countdown()
	if notification_time_left > 0.0:
		notification_time_left = maxf(notification_time_left - delta, 0.0)
		label.text = notification_text
		return
	if arena_time_manager == null:
		return

	var time_elapsed = arena_time_manager.get_time_elapsed()
	label.text = "%s   %s" % [map_name, format_seconds_to_string(time_elapsed)]


func update_boss_countdown() -> void:
	boss_countdown.hide()
	var events := get_node_or_null("/root/GameEvents")
	if game_state == null or arena_time_manager == null or events == null:
		return
	var mode := str(events.get("game_mode"))
	if mode not in ["campaign", "endless"]:
		return
	if int(game_state.get("current_map_id")) <= 0 or not get_tree().get_nodes_in_group("boss").is_empty():
		return
	if mode == "campaign" and bool(game_state.get("current_level_boss_started")):
		return
	var next_spawn := float(game_state.get("next_endless_boss_time")) if mode == "endless" else float(game_state.get("current_boss_spawn_time"))
	var remaining := maxf(next_spawn - float(arena_time_manager.get_time_elapsed()), 0.0)
	boss_countdown.text = "Boss 来袭 %s" % format_seconds_to_string(ceilf(remaining))
	boss_countdown.add_theme_color_override("font_color", Color(1.0, 0.38, 0.28) if remaining <= 10.0 else Color.WHITE)
	boss_countdown.show()


func show_notification(message: String, duration: float = 3.0) -> void:
	notification_text = message
	notification_time_left = maxf(duration, 0.0)
	label.text = message


func format_seconds_to_string(seconds: float) -> String:
	var minutes = floor(seconds / 60)
	var remaining_seconds = floor(seconds - (minutes * 60))
	return "%d:%02d" % [minutes, remaining_seconds]
