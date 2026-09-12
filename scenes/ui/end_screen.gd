extends CanvasLayer
class_name EndScreen

@onready var panel_container := %PanelContainer


func _ready():
	update_summary()
	panel_container.pivot_offset = panel_container.size / 2
	panel_container.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.3) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	
	get_tree().paused = true
	%ContinueButton.pressed.connect(on_continue_button_pressed)
	%QuitButton.pressed.connect(on_quit_button_pressed)


func set_defeat():
	%TitleLabel.text = "失败"
	%DefeatReasonLabel.text = "被%s击败" % GameEvents.last_damage_source
	update_summary()
	play_jingle(true)


func update_summary() -> void:
	var upgrade_manager: Node = get_parent().get_node_or_null("UpgradeManager")
	if upgrade_manager == null:
		%Weapon1Label.text = "武器 1\n未装备"
		%Weapon2Label.text = "武器 2\n未装备"
		%OtherSkillsLabel.text = "其他技能\n暂无"
		return
	var upgrades: Dictionary = upgrade_manager.get("current_upgrades") as Dictionary
	var weapons: Array[AbilityUpgrade] = []
	for upgrade_id: String in upgrades:
		var upgrade_data: Dictionary = upgrades[upgrade_id]
		var weapon: AbilityUpgrade = upgrade_data["resource"] as AbilityUpgrade
		if weapon is Ability:
			weapons.append(weapon)
	%Weapon1Label.text = get_weapon_text(1, weapons[0] if weapons.size() > 0 else null, upgrades)
	%Weapon2Label.text = get_weapon_text(2, weapons[1] if weapons.size() > 1 else null, upgrades)
	%OtherSkillsLabel.text = "其他技能\n%s" % get_skill_text("", upgrades)


func get_weapon_text(slot: int, weapon: AbilityUpgrade, upgrades: Dictionary) -> String:
	if weapon == null:
		return "武器 %d\n未装备" % slot
	return "武器 %d\n%s\n输出 %.0f\n技能：%s" % [slot, weapon.name, GameEvents.weapon_damage.get(weapon.id, 0.0), get_skill_text(weapon.id, upgrades)]


func get_skill_text(weapon_id: String, upgrades: Dictionary) -> String:
	var skills: Array[String] = []
	for upgrade_id: String in upgrades:
		var upgrade_data: Dictionary = upgrades[upgrade_id]
		var upgrade: AbilityUpgrade = upgrade_data["resource"] as AbilityUpgrade
		if upgrade is Ability or get_skill_weapon_id(upgrade.id) != weapon_id:
			continue
		skills.append("%s Lv.%d" % [upgrade.name, int(upgrade_data["quantity"])])
	return "、".join(skills) if not skills.is_empty() else "暂无"


func get_skill_weapon_id(upgrade_id: String) -> String:
	if upgrade_id.begins_with("sword_"):
		return "sword"
	if upgrade_id.begins_with("axe_"):
		return "axe"
	if upgrade_id.begins_with("laser_gun_"):
		return "laser_gun"
	if upgrade_id.begins_with("lightning_whip_") or upgrade_id in ["lightning_chain", "lightning_cloud", "lightning_wide_arc"]:
		return "lightning_whip"
	if upgrade_id.begins_with("bomb_"):
		return "bomb"
	if upgrade_id.begins_with("thunder_orb_"):
		return "thunder_orb_book"
	if upgrade_id.begins_with("azure_dragon_"):
		return "azure_dragon"
	if upgrade_id.begins_with("nine_treasure_"):
		return "nine_treasure_pagoda"
	return ""


func play_jingle(defeat: bool = false):
	if defeat:
		$DefeatStreamPlayer.play()
	else:
		$VictoryStreamPlayer.play()


func on_continue_button_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/meta_menu.tscn")


func on_quit_button_pressed():
	ScreenTransition.transition_to_scene("res://scenes/ui/main_menu.tscn")
	get_tree().paused = false
	await ScreenTransition.transitioned_halfway
