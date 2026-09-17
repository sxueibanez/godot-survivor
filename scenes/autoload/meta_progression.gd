extends Node


const SAVE_FILE_PATH := "user://game.save"
const ENEMY_HEALTH_PER_SPECIAL_SKILL := 0.02
const WEAPON_RESET_COST := 500

var save_data: Dictionary = {
	"meta_upgrade_currency": 0,
	"meta_upgrades": {},
	"weapon_skills": {},
}


func _ready():
	GameEvents.experience_vial_collected.connect(on_experience_collected)
	load_save_file()


func load_save_file() -> void:
	if !FileAccess.file_exists(SAVE_FILE_PATH):
		return
	
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var loaded_data: Variant = file.get_var()
	if loaded_data is Dictionary:
		save_data = loaded_data as Dictionary
	if !save_data.has("meta_upgrades"):
		save_data["meta_upgrades"] = {}
	if !save_data.has("weapon_skills"):
		save_data["weapon_skills"] = {}


func save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_var(save_data)


func add_meta_upgrade(upgrade: MetaUpgrade):
	if !save_data["meta_upgrades"].has(upgrade.id):
		save_data["meta_upgrades"][upgrade.id] = {
			"quantity": 0
		}
	
	save_data["meta_upgrades"][upgrade.id]["quantity"] += 1
	save()


func get_upgrade_count(upgrade_id: String) -> int:
	if save_data["meta_upgrades"].has(upgrade_id):
		return save_data["meta_upgrades"][upgrade_id]["quantity"]
	return 0


func get_weapon_skill_count(skill_id: String) -> int:
	var weapon_skills: Dictionary = save_data["weapon_skills"] as Dictionary
	return int(weapon_skills.get(skill_id, 0))


func get_weapon_tree_bonus(weapon_id: String, stat: String) -> float:
	var count := 0
	var prefix := "tree_bonus_%s_" % weapon_id
	var suffix := "_%s" % stat
	for skill_id: String in (save_data["weapon_skills"] as Dictionary):
		if skill_id.begins_with(prefix) and skill_id.ends_with(suffix) and get_weapon_skill_count(skill_id) > 0:
			count += 1
	return count * 0.05


func get_enemy_health_multiplier() -> float:
	var special_skill_count := 0
	for skill_id: String in (save_data["weapon_skills"] as Dictionary):
		if skill_id.begins_with("tree_") and not skill_id.begins_with("tree_bonus_") and get_weapon_skill_count(skill_id) > 0:
			special_skill_count += 1
	return 1.0 + special_skill_count * ENEMY_HEALTH_PER_SPECIAL_SKILL


func purchase_weapon_skill(skill_id: String, cost: int) -> bool:
	if get_weapon_skill_count(skill_id) > 0:
		return false
	var currency: int = int(save_data["meta_upgrade_currency"])
	if cost <= 0 or currency < cost:
		return false
	var weapon_skills: Dictionary = save_data["weapon_skills"] as Dictionary
	weapon_skills[skill_id] = get_weapon_skill_count(skill_id) + 1
	save_data["weapon_skills"] = weapon_skills
	save_data["meta_upgrade_currency"] = currency - cost
	if not save_data.has("weapon_skill_costs"):
		save_data["weapon_skill_costs"] = {}
	save_data["weapon_skill_costs"][skill_id] = cost
	save()
	return true


func reset_weapon_skills(node_costs: Dictionary) -> bool:
	var currency := int(save_data["meta_upgrade_currency"])
	if currency < WEAPON_RESET_COST:
		return false
	var skills: Dictionary = save_data["weapon_skills"]
	var paid_costs: Dictionary = save_data.get("weapon_skill_costs", {})
	var refund := 0
	var unlocked := false
	for skill_id: String in node_costs:
		if get_weapon_skill_count(skill_id) > 0:
			unlocked = true
			refund += int(paid_costs.get(skill_id, node_costs[skill_id]))
	if not unlocked:
		return false
	for skill_id: String in node_costs:
		skills.erase(skill_id)
		paid_costs.erase(skill_id)
	save_data["meta_upgrade_currency"] = currency - WEAPON_RESET_COST + refund
	save()
	return true


func on_experience_collected(number: float):
	save_data["meta_upgrade_currency"] += number
