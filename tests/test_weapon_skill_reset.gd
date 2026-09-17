extends SceneTree

func _initialize() -> void:
	call_deferred("run_check")

func run_check() -> void:
	var test_script := GDScript.new()
	test_script.source_code = 'extends "res://scenes/autoload/meta_progression.gd"\nfunc save() -> void:\n\tpass\n'
	assert(test_script.reload() == OK)
	var progression = test_script.new()
	progression.save_data = {
		"meta_upgrade_currency": 499,
		"weapon_skills": {"tree_sword_chain": 1, "tree_bonus_sword_0_damage": 1, "tree_axe_return": 1},
		"weapon_skill_costs": {"tree_sword_chain": 300},
	}
	var costs := {"tree_sword_chain": 200, "tree_bonus_sword_0_damage": 50}
	assert(not progression.reset_weapon_skills(costs))
	assert(progression.get_weapon_skill_count("tree_sword_chain") == 1)
	progression.save_data["meta_upgrade_currency"] = 500
	assert(progression.reset_weapon_skills(costs))
	assert(progression.save_data["meta_upgrade_currency"] == 350)
	assert(progression.get_weapon_skill_count("tree_sword_chain") == 0)
	assert(progression.get_weapon_skill_count("tree_bonus_sword_0_damage") == 0)
	assert(progression.get_weapon_skill_count("tree_axe_return") == 1)
	assert(is_equal_approx(progression.get_enemy_health_multiplier(), 1.02))
	progression.save_data["meta_upgrade_currency"] = 500
	assert(not progression.reset_weapon_skills(costs))
	progression.free()
	var ui = load("res://scenes/ui/weapon_skill_tree.tscn").instantiate()
	root.add_child(ui)
	ui.on_weapon_selected("bomb")
	assert(is_instance_valid(ui.health_info))
	assert(is_instance_valid(ui.reset_button))
	assert(ui.health_info.text.contains("+2%"))
	ui.queue_free()
	await process_frame
	quit()
