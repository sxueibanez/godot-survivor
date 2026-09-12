extends CanvasLayer


const WEAPON_IDS: Array[String] = ["sword", "axe", "laser_gun", "lightning_whip", "bomb", "thunder_orb_book", "azure_dragon", "nine_treasure_pagoda"]
const WEAPON_NAMES: Dictionary = {
	"sword": "剑",
	"axe": "飞斧",
	"laser_gun": "激光枪",
	"lightning_whip": "闪电鞭",
	"bomb": "炸弹",
	"thunder_orb_book": "雷球书",
	"azure_dragon": "四圣兽",
	"nine_treasure_pagoda": "九宝琉璃塔",
}
const WEAPON_SKILLS: Dictionary = {
	"sword": [
		{"id": "tree_sword_chain", "title": "剑影追击", "description": "剑命中后有 30% 概率触发追击剑。", "requires": []},
		{"id": "tree_sword_rain", "title": "剑阵", "description": "场上同时有超过 5 柄剑时，在怪物最密集处释放持续剑阵。", "requires": ["tree_sword_chain"]},
		{"id": "tree_sword_rain_giant", "title": "巨型剑阵", "description": "同时存在 3 个剑阵时，在主角位置释放双倍剑阵。", "requires": ["tree_sword_rain"]},
		{"id": "tree_sword_barrage", "title": "剑雨", "description": "同一敌人受到 10 次剑伤害后，从主角当前位置连续发射 10 把剑。", "requires": ["tree_sword_rain"]},
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
	],
	"bomb": [
		{"id": "tree_bomb_bounce", "title": "跳弹", "description": "解锁局内跳弹升级；每级增加1次弹跳爆炸，最多3级。", "requires": []},
		{"id": "tree_bomb_burn", "title": "燃烧弹", "description": "解锁局内燃烧弹升级；命中后每秒造成60%武器伤害，持续5秒。", "requires": []},
		{"id": "tree_bomb_cluster", "title": "子母弹", "description": "解锁局内子母弹升级；每次主炸弹爆炸洒出5枚30%威力与范围的小炸弹。", "requires": []},
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
}
@onready var currency_label: Label = %CurrencyLabel
@onready var weapon_tabs: HBoxContainer = %WeaponTabs
@onready var tree_container: VBoxContainer = %TreeContainer
@onready var back_button: Button = %BackButton

var selected_weapon_id := "sword"


func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	build_tabs()
	refresh_tree()


func build_tabs() -> void:
	for weapon_id: String in WEAPON_IDS:
		var tab := Button.new()
		tab.text = str(WEAPON_NAMES[weapon_id])
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(on_weapon_selected.bind(weapon_id))
		weapon_tabs.add_child(tab)


func refresh_tree() -> void:
	currency_label.text = "瓶子：%d" % int(MetaProgression.save_data["meta_upgrade_currency"])
	for child: Node in tree_container.get_children():
		child.queue_free()
	var hint := Label.new()
	hint.text = "点亮后，专属技能才会在游戏内升级三选一中出现。增伤、攻速、大小为常驻属性。"
	tree_container.add_child(hint)
	var skills: Array = WEAPON_SKILLS[selected_weapon_id] as Array
	for skill_value: Variant in skills:
		var skill: Dictionary = skill_value as Dictionary
		add_skill_node(skill)


func add_skill_node(skill: Dictionary) -> void:
	var skill_id := str(skill["id"])
	var unlocked := MetaProgression.get_weapon_skill_count(skill_id) > 0
	var skill_cost := MetaProgression.get_next_weapon_skill_cost()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 58)
	var content := VBoxContainer.new()
	card.add_child(content)
	var title := Label.new()
	title.text = "● %s%s" % [str(skill["title"]), "（已点亮）" if unlocked else ""]
	content.add_child(title)
	var description := Label.new()
	description.text = str(skill["description"])
	content.add_child(description)
	var button := Button.new()
	button.text = "已点亮" if unlocked else "点亮（%d 瓶）" % skill_cost
	button.disabled = unlocked or !requirements_met(skill) or int(MetaProgression.save_data["meta_upgrade_currency"]) < skill_cost
	button.pressed.connect(on_skill_purchased.bind(skill_id))
	content.add_child(button)
	tree_container.add_child(card)


func requirements_met(skill: Dictionary) -> bool:
	var requirements: Array = skill.get("requires", []) as Array
	for required: Variant in requirements:
		if MetaProgression.get_weapon_skill_count(str(required)) == 0:
			return false
	return true


func on_weapon_selected(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	refresh_tree()


func on_skill_purchased(skill_id: String) -> void:
	MetaProgression.purchase_weapon_skill(skill_id)
	refresh_tree()


func on_back_pressed() -> void:
	ScreenTransition.transition_to_scene("res://scenes/ui/main_menu.tscn")
