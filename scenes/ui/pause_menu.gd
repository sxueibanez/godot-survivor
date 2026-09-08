extends CanvasLayer
class_name PauseMenu

@onready var panel_container = %PanelContainer
@onready var attributes_label: Label = %AttributesLabel
@onready var skills_label: Label = %SkillsLabel
@onready var character_portrait: TextureRect = %CharacterPortrait

var options_scene = preload("res://scenes/ui/options_menu.tscn")
var is_closing := false


func _ready():
	get_tree().paused = true
	update_character_panel()
	panel_container.pivot_offset = panel_container.size / 2
	
	%ResumeButton.pressed.connect(on_resume_pressed)
	%OptionsButton.pressed.connect(on_options_pressed)
	%QuitButton.pressed.connect(on_quit_pressed)
	
	$AnimationPlayer.play("default")
	
	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.3) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)


func update_character_panel() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	var velocity: VelocityComponent = player.get_node_or_null("VelocityComponent") as VelocityComponent
	if health == null or velocity == null:
		return
	var character: Resource = player.get("character") as Resource
	var portrait_texture := character.get("sprite") as Texture2D
	if portrait_texture != null:
		character_portrait.texture = portrait_texture
	attributes_label.text = "属性\n生命  %.0f / %.0f\n移速  %d\n暴击  %.0f%%\n吸血  %.0f%%\n攻击数量  %d" % [health.current_health, health.max_health, roundi(velocity.max_speed), GameEvents.critical_chance * 100.0, GameEvents.life_steal_percent * 100.0, GameEvents.weapon_attack_count]
	var upgrade_manager: Node = get_parent().get_node_or_null("UpgradeManager")
	if upgrade_manager == null:
		return
	var upgrades: Dictionary = upgrade_manager.get("current_upgrades") as Dictionary
	var weapons: Array[AbilityUpgrade] = []
	for upgrade_id: String in upgrades:
		var upgrade_data: Dictionary = upgrades[upgrade_id]
		var upgrade: AbilityUpgrade = upgrade_data["resource"] as AbilityUpgrade
		if upgrade is Ability:
			weapons.append(upgrade)
	var skill_text := "武器与技能\n"
	for index in 2:
		if index >= weapons.size():
			skill_text += "\n【武器 %d】未装备\n" % (index + 1)
			continue
		var weapon: AbilityUpgrade = weapons[index]
		skill_text += "\n【武器 %d · %s】\n%s" % [index + 1, weapon.name, get_skill_lines(weapon.id, upgrades)]
	skill_text += "\n【其他技能】\n%s" % get_skill_lines("", upgrades)
	skills_label.text = skill_text


func get_skill_lines(weapon_id: String, upgrades: Dictionary) -> String:
	var lines: Array[String] = []
	for upgrade_id: String in upgrades:
		var upgrade_data: Dictionary = upgrades[upgrade_id]
		var upgrade: AbilityUpgrade = upgrade_data["resource"] as AbilityUpgrade
		if upgrade is Ability:
			continue
		if get_skill_weapon_id(upgrade.id) != weapon_id:
			continue
		lines.append("• %s Lv.%d" % [upgrade.name, int(upgrade_data["quantity"])])
	return "\n".join(lines) if not lines.is_empty() else "• 暂无"


func get_skill_weapon_id(upgrade_id: String) -> String:
	if upgrade_id.begins_with("sword_"):
		return "sword"
	if upgrade_id.begins_with("axe_"):
		return "axe"
	if upgrade_id.begins_with("laser_gun_"):
		return "laser_gun"
	if upgrade_id.begins_with("lightning_whip_") or upgrade_id == "lightning_chain":
		return "lightning_whip"
	return ""


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		close()
		get_tree().root.set_input_as_handled()


func close():
	if is_closing:
		return
	is_closing = true
	
	$AnimationPlayer.play_backwards("default")
	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0)
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.3) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_BACK)
	await tween.finished
	
	get_tree().paused = false
	queue_free()


func on_resume_pressed():
	close()


func on_options_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	var options_instance = options_scene.instantiate() as OptionsMenu
	add_child(options_instance)
	options_instance.back_pressed.connect(on_options_closed.bind(options_instance))


func on_options_closed(options_instance: OptionsMenu):
	options_instance.queue_free()


func on_quit_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
