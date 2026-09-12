extends Node


const SAVE_FILE_PATH := "user://game.save"
const WEAPON_SKILL_BASE_COST := 200
const WEAPON_SKILL_COST_INCREMENT := 200

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


func get_next_weapon_skill_cost() -> int:
	var unlocked_count := 0
	for count: Variant in (save_data["weapon_skills"] as Dictionary).values():
		if int(count) > 0:
			unlocked_count += 1
	return calculate_weapon_skill_cost(unlocked_count)


static func calculate_weapon_skill_cost(unlocked_count: int) -> int:
	return WEAPON_SKILL_BASE_COST + maxi(0, unlocked_count) * WEAPON_SKILL_COST_INCREMENT


func purchase_weapon_skill(skill_id: String) -> bool:
	if get_weapon_skill_count(skill_id) > 0:
		return false
	var cost := get_next_weapon_skill_cost()
	var currency: int = int(save_data["meta_upgrade_currency"])
	if currency < cost:
		return false
	var weapon_skills: Dictionary = save_data["weapon_skills"] as Dictionary
	weapon_skills[skill_id] = get_weapon_skill_count(skill_id) + 1
	save_data["weapon_skills"] = weapon_skills
	save_data["meta_upgrade_currency"] = currency - cost
	save()
	return true


func on_experience_collected(number: float):
	save_data["meta_upgrade_currency"] += number
