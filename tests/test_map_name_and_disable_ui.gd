extends SceneTree


class Clock extends Node:
	func get_time_elapsed() -> float:
		return 37.0


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var clock := Clock.new()
	root.add_child(clock)
	var hud := preload("res://scenes/ui/arena_time_ui.tscn").instantiate()
	hud.arena_time_manager = clock
	root.add_child(hud)
	for map_id in range(1, 5):
		hud.set_map(map_id)
		hud._process(0.0)
		assert(hud.label.text == "%s   0:37" % hud.MAP_NAMES[map_id - 1])
	var card := preload("res://scenes/ui/ability_upgrade_card.tscn").instantiate()
	root.add_child(card)
	var button: Button = card.get_node("DisableOverlay/DisableButton")
	assert(button.text == "X")
	assert(button.anchor_right == 1.0)
	assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
	button.pressed.emit()
	assert(card.disabled)
	card.queue_free()
	hud.queue_free()
	clock.queue_free()
	await process_frame
	quit()
