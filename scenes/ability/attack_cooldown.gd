extends RefCounted

# One cooldown per attack batch, including bouncing/splitting projectiles.
var timer: Timer
var active_count := 0


func _init(attack_timer: Timer) -> void:
	timer = attack_timer


func track(attack: Node) -> void:
	active_count += 1
	if is_instance_valid(timer):
		timer.stop()
	attack.set_meta("attack_cooldown", self)
	attack.tree_exited.connect(finish, CONNECT_ONE_SHOT)


func begin() -> void:
	active_count += 1
	if is_instance_valid(timer):
		timer.stop()


func finish() -> void:
	active_count -= 1
	if active_count == 0:
		restart()


func restart() -> void:
	if active_count == 0 and is_instance_valid(timer) and timer.is_inside_tree():
		timer.start()
