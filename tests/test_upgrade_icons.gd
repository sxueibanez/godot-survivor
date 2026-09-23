extends Node

const CARD_SCRIPT = preload("res://scenes/ui/ability_upgrade_card.gd")


func _ready() -> void:
	for file_name in DirAccess.get_files_at("res://resources/upgrades"):
		if not file_name.ends_with(".tres"):
			continue
		var upgrade := load("res://resources/upgrades/%s" % file_name) as AbilityUpgrade
		assert(upgrade != null, "无法读取升级资源：%s" % file_name)
		assert(CARD_SCRIPT.get_upgrade_icon(upgrade) != null, "升级缺少图案：%s" % file_name)

	var sword_damage := CARD_SCRIPT.get_upgrade_icon(load("res://resources/upgrades/sword_damage.tres")) as AtlasTexture
	var bomb_damage := CARD_SCRIPT.get_upgrade_icon(load("res://resources/upgrades/bomb_damage.tres")) as AtlasTexture
	assert(sword_damage.atlas == bomb_damage.atlas and sword_damage.region == bomb_damage.region,
		"所有武器的通用加伤害技能必须共用同一张图案")
	print("UPGRADE_ICON_TEST_PASSED")
	get_tree().quit()
