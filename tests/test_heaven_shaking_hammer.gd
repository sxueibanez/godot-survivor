extends SceneTree


func _initialize() -> void:
	var upgrade := load("res://resources/upgrades/heaven_shaking_hammer_extra_wave.tres") as AbilityUpgrade
	assert(upgrade != null)
	assert(upgrade.max_quantity == 4)
	assert(load("res://scenes/ability/heaven_shaking_hammer_controller/heaven_shaking_hammer_controller.tscn") != null)
	quit()
