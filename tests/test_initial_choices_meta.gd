extends Node

func _ready() -> void:
	var upgrade := load("res://resources/meta_upgrade/initial_choices.tres") as MetaUpgrade
	assert(upgrade != null and upgrade.max_quantity == 1)
	assert(upgrade.get_experience_cost(0) == 1000)
	var menu := load("res://scenes/ui/meta_menu.tscn").instantiate() as MetaMenu
	assert(menu.upgrades.any(func(item: MetaUpgrade): return item.id == upgrade.id))
	menu.free()
	var original_upgrades: Dictionary = MetaProgression.save_data["meta_upgrades"]
	MetaProgression.save_data["meta_upgrades"] = {}
	var manager = load("res://scenes/manager/upgrade_manager.tscn").instantiate()
	manager.start_initial_choices()
	assert(manager.initial_choices_remaining == 1)
	MetaProgression.save_data["meta_upgrades"] = {upgrade.id: {"quantity": 1}}
	manager.start_initial_choices()
	assert(manager.initial_choices_remaining == 2)
	manager.start_initial_choices(5)
	assert(manager.initial_choices_remaining == 6)
	MetaProgression.save_data["meta_upgrades"][upgrade.id]["quantity"] = 2
	manager.start_initial_choices()
	assert(manager.initial_choices_remaining == 2)
	MetaProgression.save_data["meta_upgrades"] = original_upgrades
	manager.free()
	print("Initial choices meta upgrade test passed: cost 1000, max level 1, campaign 2, endless 6.")
	get_tree().quit()
