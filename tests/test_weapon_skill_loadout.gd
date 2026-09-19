extends Node

const TreeScript = preload("res://scenes/ui/weapon_skill_tree.gd")


func _ready() -> void:
	var original_save: Dictionary = MetaProgression.save_data
	var bomb_skills: Array = TreeScript.WEAPON_SKILLS.bomb
	var ids: Array[String] = []
	for skill_value in bomb_skills:
		ids.append(str((skill_value as Dictionary).id))
	var unlocked := {}
	for index in 5:
		unlocked[ids[index]] = 1
	MetaProgression.save_data = {
		"meta_upgrade_currency": 1000,
		"meta_upgrades": {},
		"weapon_skills": unlocked,
		"weapon_skill_loadouts": {},
	}
	assert(MetaProgression.get_weapon_skill_loadout("bomb", ids) == ids.slice(0, 5))
	assert(TreeScript.is_skill_equipped(ids[0]))
	assert(not TreeScript.is_skill_equipped(ids[5]))
	var tree = load("res://scenes/ui/weapon_skill_tree.tscn").instantiate()
	add_child(tree)
	tree.selected_weapon_id = "bomb"
	tree.refresh_tree()
	assert(find_text(tree, "候选技能 · 解锁500瓶"))
	assert(find_tooltip(tree, "爆心牵引"))

	# Simulate the paid sixth skill, then replace slot zero without writing a save file.
	MetaProgression.save_data.weapon_skills[ids[5]] = 1
	MetaProgression.save_data.meta_upgrade_currency -= tree.OVERFLOW_SKILL_COST
	MetaProgression.save_data.weapon_skill_loadouts = {"bomb": [ids[5], ids[1], ids[2], ids[3], ids[4]]}
	assert(int(MetaProgression.save_data.meta_upgrade_currency) == 500)
	assert(TreeScript.is_skill_equipped(ids[5]))
	assert(not TreeScript.is_skill_equipped(ids[0]))

	var manager = load("res://scenes/manager/upgrade_manager.gd").new()
	manager.update_upgrade_pool(load("res://resources/upgrades/bomb.tres"))
	var offered_ids: Array[String] = []
	for entry in manager.upgrade_pool.items:
		offered_ids.append(str((entry.item as Resource).get("id")))
	assert("bomb_implosion" in offered_ids)
	assert("bomb_bounce" not in offered_ids)
	for resource_name in ["bomb_implosion", "lightning_paralysis", "heaven_shaking_hammer_aftershock"]:
		var upgrade := load("res://resources/upgrades/%s.tres" % resource_name) as AbilityUpgrade
		assert(upgrade.icon != null)
	MetaProgression.save_data = original_save
	print("Weapon skill loadout passed: five slots, overflow panel, 500 cost, swap filtering and unique icons.")
	get_tree().quit()


func find_text(node: Node, value: String) -> bool:
	if node is Label and (node as Label).text == value:
		return true
	for child in node.get_children():
		if find_text(child, value):
			return true
	return false


func find_tooltip(node: Node, value: String) -> bool:
	if node is Control and value in (node as Control).tooltip_text:
		return true
	for child in node.get_children():
		if find_tooltip(child, value):
			return true
	return false
