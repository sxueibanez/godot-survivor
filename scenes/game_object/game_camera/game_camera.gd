extends Camera2D

const SNAP_DISTANCE := 160.0
var target_position = Vector2.ZERO
var target_id := 0


func _ready():
	make_current()


func _process(delta):
	var player := acquire_target()
	if player == null:
		target_id = 0
		return
	if target_id != player.get_instance_id() or global_position.distance_squared_to(target_position) > SNAP_DISTANCE * SNAP_DISTANCE:
		target_id = player.get_instance_id()
		global_position = target_position
		reset_smoothing()
		return
	global_position = global_position.lerp(target_position, 1.0 - exp(-delta * 20))


func acquire_target() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		target_position = player.global_position
	return player
