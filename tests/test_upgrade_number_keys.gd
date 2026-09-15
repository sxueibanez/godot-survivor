extends SceneTree


func _initialize() -> void:
	var screen := preload("res://scenes/ui/upgrade_screen.tscn").instantiate()
	root.add_child(screen)
	screen.set_ability_upgrades([load("res://resources/upgrades/sword_damage.tres")])
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	screen._unhandled_key_input(key)
	assert(screen.card_container.get_child(0).disabled)
	paused = false
	quit()
