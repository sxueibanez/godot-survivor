extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var menu = load("res://scenes/ui/pause_menu.gd").new()
	var weapon := load("res://resources/upgrades/sword.tres") as Ability
	var abilities := Node.new()
	var controller := Node.new()
	controller.scene_file_path = weapon.ability_controller_scene.resource_path
	abilities.add_child(controller)
	assert(menu.get_weapon_timing(weapon, abilities) == "被动 · 无CD")
	var timer := Timer.new()
	timer.name = "Timer"
	timer.wait_time = 0.5
	controller.add_child(timer)
	assert(menu.get_weapon_timing(weapon, abilities) == "CD 0.50s · 2.00次/秒")
	timer.wait_time = 2.0
	assert(menu.get_weapon_timing(weapon, abilities) == "CD 2.00s · 0.50次/秒")
	abilities.free()
	menu.free()
	quit()
