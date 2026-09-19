extends CanvasLayer


const WEAPON_IDS: Array[String] = ["sword", "axe", "laser_gun", "lightning_whip", "bomb", "thunder_orb_book", "azure_dragon", "nine_treasure_pagoda", "heaven_shaking_hammer", "sniper_rifle"]
const WEAPON_NAMES: Dictionary = {
	"sword": "剑",
	"axe": "飞斧",
	"laser_gun": "激光枪",
	"lightning_whip": "闪电鞭",
	"bomb": "炸弹",
	"thunder_orb_book": "雷球书",
	"azure_dragon": "四圣兽",
	"nine_treasure_pagoda": "九宝琉璃塔",
	"heaven_shaking_hammer": "震天锤",
	"sniper_rifle": "狙击枪",
}
const WEAPON_SKILLS: Dictionary = {
	"sword": [
		{"id": "tree_sword_chain", "title": "剑影追击", "description": "剑命中后有 30% 概率触发追击剑。", "requires": []},
		{"id": "tree_sword_rain", "title": "剑阵", "description": "场上同时有超过 5 柄剑时，在怪物最密集处释放持续剑阵。", "requires": ["tree_sword_chain"]},
		{"id": "tree_sword_rain_giant", "title": "巨型剑阵", "description": "同时存在 3 个剑阵时，在主角位置释放双倍剑阵。", "requires": ["tree_sword_rain"]},
		{"id": "tree_sword_barrage", "title": "剑雨", "description": "同一敌人受到 10 次剑伤害后，从主角当前位置连续发射 10 把剑。", "requires": ["tree_sword_rain"]},
		{"id": "tree_sword_greatsword_sweep", "title": "横贯天锋", "description": "解锁局内大剑升级；每10秒从地图右侧冲向左侧，造成一次350%武器伤害。", "requires": []},
	],
	"axe": [
		{"id": "tree_axe_return", "title": "归手回旋", "description": "飞斧到达最远处后回到主角。", "requires": []},
		{"id": "tree_axe_knockback", "title": "震荡飞斧", "description": "飞斧命中敌人时造成击退。", "requires": ["tree_axe_return"]},
		{"id": "tree_axe_reflect", "title": "弹幕反弹", "description": "飞斧接触敌方弹幕后将其反弹。", "requires": ["tree_axe_knockback"]},
		{"id": "tree_axe_count", "title": "飞斧增殖", "description": "解锁局内“飞斧数量 +1”升级。", "requires": []},
		{"id": "tree_axe_distance_power", "title": "远行巨斧", "description": "飞斧离主角越远，体积与伤害越高，最高为初始值的 200%。", "requires": []},
	],
	"laser_gun": [
		{"id": "tree_laser_ramp", "title": "灼热聚焦", "description": "射线持续伤害可提高至初始伤害的 200%。", "requires": []},
		{"id": "tree_laser_reflect", "title": "边界反射", "description": "主射线长度提升 50%；碰到地图边缘后反射三根扇形射线：长度 150%、伤害 75%、宽度 25%。", "requires": ["tree_laser_ramp"]},
		{"id": "tree_laser_stun", "title": "过载眩晕", "description": "1 秒内受到 5 次激光伤害的敌人眩晕。", "requires": ["tree_laser_ramp"]},
		{"id": "tree_laser_auto_aim", "title": "聚群校准", "description": "激光每 0.1 秒自动重新瞄准怪物最密集处。", "requires": []},
		{"id": "tree_laser_kill_duration", "title": "余晖延迟", "description": "每击杀一名非首领小怪，激光结束延迟 0.3 秒。", "requires": []},
	],
	"lightning_whip": [
		{"id": "tree_lightning_chain", "title": "电弧连锁", "description": "命中时有 50% 概率对附近敌人释放两条可连锁闪电链，每条造成 50% 武器伤害。", "requires": []},
		{"id": "tree_lightning_cloud", "title": "雷云召唤", "description": "普通攻击命中有 10% 概率生成雷云；雷云持续 5 秒，每秒电击一名敌人，造成 150% 武器伤害。", "requires": []},
		{"id": "tree_lightning_wide_arc", "title": "雷霆横扫", "description": "普通攻击范围从 90° 提升至 180°。", "requires": []},
		{"id": "tree_lightning_paralysis", "title": "麻痹电流", "description": "所有伤害有20%概率麻痹0.5秒。", "requires": []},
	],
	"bomb": [
		{"id": "tree_bomb_bounce", "title": "跳弹", "description": "解锁局内跳弹升级；每级增加1次弹跳爆炸，最多3级。", "requires": []},
		{"id": "tree_bomb_burn", "title": "燃烧弹", "description": "解锁局内燃烧弹升级；命中后每秒造成60%武器伤害，持续5秒。", "requires": []},
		{"id": "tree_bomb_cluster", "title": "子母弹", "description": "解锁局内子母弹升级；每次主炸弹爆炸洒出5枚30%威力与范围的小炸弹。", "requires": []},
		{"id": "tree_bomb_heat_reaction", "title": "热爆反应", "description": "结算50%剩余燃烧伤害并刷新燃烧。", "requires": ["tree_bomb_burn"]},
		{"id": "tree_bomb_giant_charge", "title": "巨型装药", "description": "每第4轮主弹巨化，首爆半径+50%，击退小怪。", "requires": []},
		{"id": "tree_bomb_implosion", "title": "爆心牵引", "description": "爆炸轻微拉近范围内的小怪。", "requires": []},
	],
	"thunder_orb_book": [
		{"id": "tree_thunder_orb_chain", "title": "雷链", "description": "解锁局内雷链升级；雷球每秒攻击周围最多3名敌人。", "requires": []},
		{"id": "tree_thunder_orb_count", "title": "雷球增殖", "description": "解锁局内雷球数量升级；每级数量+1，最多3级。", "requires": []},
		{"id": "tree_thunder_orb_growth", "title": "雷霆膨胀", "description": "解锁局内成长升级；雷球距离越远体积越大。", "requires": []},
		{"id": "tree_thunder_orb_plasma", "title": "雷浆爆裂", "description": "解锁局内终点爆炸与持续3秒的雷浆。", "requires": []},
		{"id": "tree_thunder_orb_boss_tracking", "title": "雷霆追猎", "description": "解锁局内BOSS追踪；没有BOSS时雷球保持原本直线轨迹。", "requires": []},
	],
	"azure_dragon": [
		{"id": "tree_azure_dragon_vermilion_bird", "title": "朱雀降临", "description": "解锁局内朱雀召唤；每秒发射3枚燃烧火球。", "requires": []},
		{"id": "tree_azure_dragon_xuanwu", "title": "玄武守护", "description": "解锁局内玄武召唤；提供护盾与一次免死。", "requires": []},
		{"id": "tree_azure_dragon_white_tiger", "title": "白虎啸风", "description": "解锁局内白虎召唤；定期释放聚怪龙卷风。", "requires": []},
		{"id": "tree_azure_dragon_four_beasts", "title": "四圣共鸣", "description": "集齐四圣兽后，解锁每15秒一次的持续5秒穿梭攻击。", "requires": ["tree_azure_dragon_vermilion_bird", "tree_azure_dragon_xuanwu", "tree_azure_dragon_white_tiger"]},
	],
	"nine_treasure_pagoda": [
		{"id": "tree_nine_treasure_damage", "title": "一曰·增幅", "description": "解锁局内伤害加成+15%。", "requires": []},
		{"id": "tree_nine_treasure_attack_speed", "title": "二曰·速攻", "description": "解锁局内攻速加成+20%。", "requires": ["tree_nine_treasure_damage"]},
		{"id": "tree_nine_treasure_health", "title": "三曰·生息", "description": "解锁局内生命加成+20%。", "requires": ["tree_nine_treasure_attack_speed"]},
		{"id": "tree_nine_treasure_move_speed", "title": "四曰·疾行", "description": "解锁局内移速加成+20%。", "requires": ["tree_nine_treasure_health"]},
		{"id": "tree_nine_treasure_extra_attack", "title": "五曰·连击", "description": "解锁局内所有武器额外释放1次攻击。", "requires": ["tree_nine_treasure_move_speed"]},
	],
	"heaven_shaking_hammer": [
		{"id": "tree_heaven_shaking_hammer_extra_wave", "title": "连环震波", "description": "解锁局内冲击波升级；每级额外向锤击方向释放一道冲击波，最多4级。", "requires": []},
		{"id": "tree_heaven_shaking_hammer_lava", "title": "熔岩震地", "description": "解锁局内岩浆升级；震地波后留下持续3秒的岩浆，每0.5秒造成30%武器伤害。", "requires": []},
		{"id": "tree_heaven_shaking_hammer_pull", "title": "万钧聚震", "description": "解锁局内聚震升级；落锤前短暂将附近敌人拉向砸击点。", "requires": []},
		{"id": "tree_heaven_shaking_hammer_heavy", "title": "天外重锤", "description": "解锁局内重锤升级；持续战斗每秒积攒1层震势，满10层后下一锤体型、范围和伤害翻倍。", "requires": []},
		{"id": "tree_heaven_shaking_hammer_aftershock", "title": "震荡余波", "description": "中心扩散1.5倍余波，造成30%伤害。", "requires": []},
	],
	"sniper_rifle": [
		{"id": "tree_sniper_rifle_diamond_bullet", "title": "金刚弹", "description": "解锁局内金刚弹升级；子弹穿透敌人后不再衰减伤害。", "requires": []},
		{"id": "tree_sniper_rifle_scope", "title": "狙击镜", "description": "解锁局内狙击镜升级；视野扩大30%，狙击枪伤害提升10%。", "requires": []},
		{"id": "tree_sniper_rifle_shadowless_bullet", "title": "无影弹", "description": "解锁局内无影弹升级；主弹在终点分裂成四枚25%伤害、不可穿透的碎片。", "requires": []},
		{"id": "tree_sniper_rifle_ricochet", "title": "折射弹", "description": "解锁局内折射弹升级；伤害提升10%，子弹碰墙后可以反弹。", "requires": []},
		{"id": "tree_sniper_rifle_explosive_bullet", "title": "爆裂弹", "description": "解锁局内爆裂弹升级；命中产生小范围爆炸，造成50%伤害。", "requires": []},
	],
}
const NODE_COSTS := [50, 100, 150, 200]
const NODE_COLORS := [Color("35b95a"), Color("289ee8"), Color("a64fc2"), Color("ef3f45")]
const NODE_NAMES := ["攻击 +5%", "攻速 +5%", "大小 +5%"]
const NODE_STATS := ["damage", "attack_speed", "size"]
const OVERFLOW_SKILL_COST := 500
const TREE_CENTER := Vector2(300, 125)
const NODE_RADII := [36.0, 61.0, 86.0, 104.0]
const SPECIAL_ICON_IDS := {
	"tree_laser_ramp": "laser_gun_damage_ramp",
	"tree_laser_reflect": "laser_gun_reflect",
	"tree_laser_stun": "laser_gun_stun",
	"tree_laser_auto_aim": "laser_gun_auto_aim",
	"tree_laser_kill_duration": "laser_gun_kill_duration",
}

class SkillTreeCanvas extends Control:
	func _draw() -> void:
		for branch in 5:
			var direction := Vector2.UP.rotated(branch * TAU / 5.0)
			draw_line(TREE_CENTER + direction * 21.0, TREE_CENTER + direction * float(NODE_RADII[3]), Color("59606e"), 3.0)

class SkillNodeButton extends Button:
	var tree: CanvasLayer
	var weapon_id := ""
	var skill_id := ""
	var slot := -1

	func setup(owner_tree: CanvasLayer, current_weapon: String, current_skill: String, current_slot: int) -> void:
		tree = owner_tree
		weapon_id = current_weapon
		skill_id = current_skill
		slot = current_slot

	func _get_drag_data(_position: Vector2) -> Variant:
		if skill_id.is_empty() or MetaProgression.get_weapon_skill_count(skill_id) <= 0:
			return null
		var preview := TextureRect.new()
		preview.texture = tree.call("get_icon", skill_id, false)
		preview.custom_minimum_size = Vector2(42, 42)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_drag_preview(preview)
		return {"weapon_id": weapon_id, "skill_id": skill_id, "slot": slot}

	func _can_drop_data(_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.get("weapon_id", "") == weapon_id and int(data.get("slot", -1)) != slot and (slot >= 0 or int(data.get("slot", -1)) >= 0)

	func _drop_data(_position: Vector2, data: Variant) -> void:
		var target_slot := slot if slot >= 0 else int(data.get("slot", -1))
		var replacement := str(data.get("skill_id", "")) if slot >= 0 else skill_id
		tree.call("swap_equipped_skill", target_slot, replacement)

@onready var currency_label: Label = %CurrencyLabel
@onready var weapon_tabs: HBoxContainer = %WeaponTabs
@onready var weapon_scroll: ScrollContainer = %WeaponScroll
@onready var previous_weapon_button: Button = %PreviousWeaponButton
@onready var next_weapon_button: Button = %NextWeaponButton
@onready var tree_container: Control = %TreeContainer
@onready var back_button: Button = %BackButton
@onready var health_info: Label = %HealthInfo
@onready var reset_button: Button = %ResetButton

var selected_weapon_id := "sword"
var weapon_tab_buttons: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	reset_button.pressed.connect(on_reset_pressed)
	previous_weapon_button.pressed.connect(scroll_weapon_tabs.bind(-1))
	next_weapon_button.pressed.connect(scroll_weapon_tabs.bind(1))
	weapon_scroll.gui_input.connect(on_weapon_scroll_gui_input)
	build_tabs()
	refresh_tree()
	center_selected_tab.call_deferred()


func build_tabs() -> void:
	for weapon_id: String in WEAPON_IDS:
		var tab := Button.new()
		tab.text = str(WEAPON_NAMES[weapon_id])
		tab.custom_minimum_size = Vector2(82, 27)
		tab.toggle_mode = true
		tab.button_pressed = weapon_id == selected_weapon_id
		tab.add_theme_font_size_override("font_size", 10)
		tab.pressed.connect(on_weapon_selected.bind(weapon_id))
		weapon_tabs.add_child(tab)
		weapon_tab_buttons[weapon_id] = tab


func refresh_tree() -> void:
	currency_label.text = "瓶子：%d" % int(MetaProgression.save_data["meta_upgrade_currency"])
	health_info.text = "每解锁一个专属技能\n所有怪物血量 +2%%\n\n当前总加成：+%.0f%%" % [(MetaProgression.get_enemy_health_multiplier() - 1.0) * 100.0]
	var has_unlock := false
	for node_id: String in get_selected_node_costs():
		if MetaProgression.get_weapon_skill_count(node_id) > 0:
			has_unlock = true
	reset_button.disabled = not has_unlock or int(MetaProgression.save_data["meta_upgrade_currency"]) < MetaProgression.WEAPON_RESET_COST
	for child: Node in tree_container.get_children():
		if child != health_info and child != reset_button:
			child.free()
	var canvas := SkillTreeCanvas.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tree_container.add_child(canvas)
	add_center_weapon(canvas)
	var skills: Array = WEAPON_SKILLS[selected_weapon_id] as Array
	var equipped_skills := get_equipped_skills(selected_weapon_id)
	for branch in 5:
		add_branch(canvas, branch, equipped_skills)
	add_overflow_panel(canvas, skills, equipped_skills)


func add_center_weapon(canvas: Control) -> void:
	var center := PanelContainer.new()
	center.position = TREE_CENTER - Vector2(25, 25)
	center.size = Vector2(50, 50)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("232633")
	frame.border_color = Color("f4f0d8")
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(25)
	center.add_theme_stylebox_override("panel", frame)
	canvas.add_child(center)
	var icon := TextureRect.new()
	icon.texture = get_icon(selected_weapon_id, true)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)


func add_branch(canvas: Control, branch: int, skills: Array) -> void:
	var direction := Vector2.UP.rotated(branch * TAU / 5.0)
	for step in 4:
		var skill: Dictionary = skills[branch] as Dictionary if branch < skills.size() else {}
		var node_id := get_node_id(branch, step, skill)
		var available := !node_id.is_empty()
		var unlocked := available and MetaProgression.get_weapon_skill_count(node_id) > 0
		var previous_unlocked := step == 0 or MetaProgression.get_weapon_skill_count(get_node_id(branch, step - 1, skill)) > 0
		var button := make_node_button(step, skill, available, unlocked)
		var diameter := 32.0 if step < 3 else 38.0
		button.position = TREE_CENTER + direction * float(NODE_RADII[step]) - Vector2.ONE * diameter * 0.5
		button.size = Vector2.ONE * diameter
		button.disabled = !available or (unlocked and step < 3) or !previous_unlocked or (not unlocked and int(MetaProgression.save_data["meta_upgrade_currency"]) < int(NODE_COSTS[step]))
		if step == 3 and unlocked:
			(button as SkillNodeButton).setup(self, selected_weapon_id, node_id, branch)
		if available and !unlocked:
			button.pressed.connect(on_node_purchased.bind(node_id, int(NODE_COSTS[step])))
		canvas.add_child(button)


func make_node_button(step: int, skill: Dictionary, available: bool, unlocked: bool) -> Button:
	var button: Button = SkillNodeButton.new() if step == 3 else Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	var color: Color = NODE_COLORS[step] if available else Color("d8d8d8")
	var style := StyleBoxFlat.new()
	style.bg_color = color if unlocked else color.darkened(0.38)
	style.border_color = Color.WHITE if unlocked else color.lightened(0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style)
	if step < 3:
		button.text = "+5%"
		button.tooltip_text = "%s · %d 瓶" % [NODE_NAMES[step], NODE_COSTS[step]]
	elif available:
		var icon := TextureRect.new()
		icon.position = Vector2(6, 6)
		icon.size = Vector2(26, 26)
		icon.texture = get_icon(str(skill["id"]), false)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		button.tooltip_text = "%s · %d 瓶\n%s" % [str(skill["title"]), NODE_COSTS[step], str(skill["description"])]
	else:
		button.tooltip_text = "暂无专属技能"
	return button


func add_overflow_panel(canvas: Control, all_skills: Array, equipped_skills: Array) -> void:
	if all_skills.size() <= 5:
		return
	var panel := PanelContainer.new()
	panel.position = Vector2(462, 8)
	panel.size = Vector2(132, 214)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.94)
	style.border_color = Color("59606e")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title := Label.new()
	title.text = "候选技能 · 解锁500瓶"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	for skill_value in all_skills:
		var skill := skill_value as Dictionary
		var skill_id := str(skill["id"])
		if equipped_skills.any(func(item: Dictionary): return str(item["id"]) == skill_id):
			continue
		var unlocked := MetaProgression.get_weapon_skill_count(skill_id) > 0
		var button := SkillNodeButton.new()
		button.custom_minimum_size = Vector2(54, 48)
		button.setup(self, selected_weapon_id, skill_id, -1)
		button.tooltip_text = "%s\n%s%s" % [str(skill["title"]), str(skill["description"]), "\n拖到技能树进行替换。" if unlocked else "\n点击解锁 · 500瓶"]
		var icon := TextureRect.new()
		icon.position = Vector2(6, 3)
		icon.size = Vector2(42, 42)
		icon.texture = get_icon(skill_id, false)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		if not unlocked:
			button.disabled = int(MetaProgression.save_data["meta_upgrade_currency"]) < OVERFLOW_SKILL_COST
			button.pressed.connect(on_overflow_skill_purchased.bind(skill_id))
		grid.add_child(button)


func get_equipped_skills(weapon_id: String) -> Array:
	var all_skills: Array = WEAPON_SKILLS[weapon_id]
	var ids: Array[String] = []
	for skill_value in all_skills:
		ids.append(str((skill_value as Dictionary)["id"]))
	var equipped_ids := MetaProgression.get_weapon_skill_loadout(weapon_id, ids)
	var result := []
	for skill_id in equipped_ids:
		for skill_value in all_skills:
			if str((skill_value as Dictionary)["id"]) == skill_id:
				result.append(skill_value)
				break
	return result


static func is_skill_equipped(skill_id: String) -> bool:
	for weapon_id: String in WEAPON_SKILLS:
		var skills: Array = WEAPON_SKILLS[weapon_id]
		var ids: Array[String] = []
		for skill_value in skills:
			ids.append(str((skill_value as Dictionary)["id"]))
		if skill_id in ids:
			return skill_id in MetaProgression.get_weapon_skill_loadout(weapon_id, ids)
	return false


func swap_equipped_skill(slot: int, new_skill_id: String) -> void:
	var ids: Array[String] = []
	for skill_value in (WEAPON_SKILLS[selected_weapon_id] as Array):
		ids.append(str((skill_value as Dictionary)["id"]))
	if MetaProgression.swap_weapon_skill(selected_weapon_id, slot, new_skill_id, ids):
		refresh_tree()


func on_overflow_skill_purchased(skill_id: String) -> void:
	MetaProgression.purchase_weapon_skill(skill_id, OVERFLOW_SKILL_COST)
	refresh_tree()


func get_node_id(branch: int, step: int, skill: Dictionary) -> String:
	if step < 3:
		return "tree_bonus_%s_%d_%s" % [selected_weapon_id, branch, NODE_STATS[step]]
	return str(skill.get("id", ""))


func get_icon(item_id: String, weapon: bool) -> Texture2D:
	var resource_id := item_id
	if !weapon:
		resource_id = str(SPECIAL_ICON_IDS.get(item_id, item_id.trim_prefix("tree_")))
	var upgrade := load("res://resources/upgrades/%s.tres" % resource_id) as AbilityUpgrade
	return AbilityUpgradeCard.get_upgrade_icon(upgrade) if upgrade != null else null


func on_weapon_selected(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	for tab_id: String in weapon_tab_buttons:
		(weapon_tab_buttons[tab_id] as Button).button_pressed = tab_id == selected_weapon_id
	refresh_tree()
	center_selected_tab.call_deferred()


func scroll_weapon_tabs(direction: int) -> void:
	weapon_scroll.scroll_horizontal += direction * 258


func center_selected_tab() -> void:
	var tab := weapon_tab_buttons.get(selected_weapon_id) as Button
	if tab != null:
		weapon_scroll.scroll_horizontal = maxi(0, int(tab.position.x + tab.size.x * 0.5 - weapon_scroll.size.x * 0.5))


func on_weapon_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_weapon_tabs(-1)
			weapon_scroll.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_weapon_tabs(1)
			weapon_scroll.accept_event()


func on_node_purchased(node_id: String, cost: int) -> void:
	MetaProgression.purchase_weapon_skill(node_id, cost)
	refresh_tree()


func on_back_pressed() -> void:
	ScreenTransition.transition_to_scene("res://scenes/ui/main_menu.tscn")


func get_selected_node_costs() -> Dictionary:
	var costs := {}
	var skills: Array = WEAPON_SKILLS[selected_weapon_id]
	for branch in 5:
		var skill: Dictionary = skills[branch] if branch < skills.size() else {}
		for step in 4:
			var node_id := get_node_id(branch, step, skill)
			if not node_id.is_empty():
				costs[node_id] = int(NODE_COSTS[step])
	for index in skills.size():
		var skill_id := str((skills[index] as Dictionary)["id"])
		costs[skill_id] = OVERFLOW_SKILL_COST if index >= 5 else int(NODE_COSTS[3])
	return costs


func on_reset_pressed() -> void:
	if MetaProgression.reset_weapon_skills(get_selected_node_costs()):
		MetaProgression.clear_weapon_skill_loadout(selected_weapon_id)
	refresh_tree()
