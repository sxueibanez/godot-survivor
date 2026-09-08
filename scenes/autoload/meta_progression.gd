extends Node


const SAVE_FILE_PATH := "user://game.save"

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


func purchase_weapon_skill(skill_id: String, cost: int) -> bool:
	var currency: int = int(save_data["meta_upgrade_currency"])
	if cost <= 0 or currency < cost:
		return false
	var weapon_skills: Dictionary = save_data["weapon_skills"] as Dictionary
	weapon_skills[skill_id] = get_weapon_skill_count(skill_id) + 1
	save_data["weapon_skills"] = weapon_skills
	save_data["meta_upgrade_currency"] = currency - cost
	save()
	return true


func on_experience_collected(number: float):
	save_data["meta_upgrade_currency"] += number
