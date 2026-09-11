extends SceneTree


func _init() -> void:
	var manager := preload("res://scenes/manager/upgrade_manager.tscn").instantiate()
	manager.upgrade_pool.add_item(AbilityUpgrade.new(), 1)
	manager.choice_screen_open = true
	manager.show_upgrade_choices()
	assert(manager.pending_upgrade_choices == 1)
	quit()
