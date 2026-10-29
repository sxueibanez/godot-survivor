extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var screen := preload("res://scenes/ui/upgrade_screen.tscn").instantiate()
	root.add_child(screen)
	var upgrades: Array[AbilityUpgrade] = [load("res://resources/upgrades/sword_damage.tres")]
	screen.set_ability_upgrades(upgrades)
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	screen._unhandled_key_input(key)
	assert(screen.card_container.get_child(0).disabled)
	paused = false
	quit()
