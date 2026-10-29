extends Node


func _ready() -> void:
	var manager := ExperienceManager.new()
	var levels: Array[int] = []
	manager.level_up.connect(func(level: int): levels.append(level))
	manager.increment_experience(10.5)
	assert(levels == [2, 3])
	assert(manager.current_level == 3)
	assert(is_equal_approx(manager.current_experience, 3.5))
	assert(manager.target_experience == 11)
	manager.increment_experience(7.5)
	assert(levels == [2, 3, 4])
	assert(is_zero_approx(manager.current_experience))
	var bar := preload("res://scenes/ui/experience_bar.tscn").instantiate()
	bar.experience_manager = manager
	add_child(bar)
	assert(bar.get_node("%LevelLabel").text == "等级 4")
	assert(bar.get_node("%AmountLabel").text == "0 / 16")
	manager.increment_experience(2.5)
	assert(bar.get_node("%AmountLabel").text == "2.5 / 16")
	assert(is_equal_approx(bar.get_node("%ProgressBar").value, 2.5 / 16.0))
	var upgrade_manager := preload("res://scenes/manager/upgrade_manager.tscn").instantiate()
	upgrade_manager.experience_manager = manager
	add_child(upgrade_manager)
	upgrade_manager.choice_screen_open = true
	manager.increment_experience(40.0)
	assert(manager.current_level == 6)
	assert(upgrade_manager.pending_upgrade_choices == 2)
	upgrade_manager.free()
	bar.free()
	manager.free()
	print("EXPERIENCE_OVERFLOW_TEST_PASSED")
	get_tree().call_deferred("quit")
