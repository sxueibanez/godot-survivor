extends CanvasLayer


const WEAPON_IDS: Array[String] = ["sword", "axe", "laser_gun", "lightning_whip"]
const WEAPON_NAMES: Dictionary = {
	"sword": "剑",
	"axe": "飞斧",
	"laser_gun": "激光枪",
	"lightning_whip": "闪电鞭",
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
		{"id": "tree_laser_reflect", "title": "边界反射", "description": "射线碰到地图边缘后反射一次。", "requires": ["tree_laser_ramp"]},
		{"id": "tree_laser_stun", "title": "过载眩晕", "description": "1 秒内受到 5 次激光伤害的敌人眩晕。", "requires": ["tree_laser_ramp"]},
	],
	"lightning_whip": [
		{"id": "tree_lightning_chain", "title": "电弧连锁", "description": "闪电鞭命中后连锁附近敌人。", "requires": []},
	],
}
const SKILL_COST := 200

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
	button.text = "已点亮" if unlocked else "点亮（%d 瓶）" % SKILL_COST
	button.disabled = unlocked or !requirements_met(skill) or int(MetaProgression.save_data["meta_upgrade_currency"]) < SKILL_COST
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
	MetaProgression.purchase_weapon_skill(skill_id, SKILL_COST)
	refresh_tree()


func on_back_pressed() -> void:
	ScreenTransition.transition_to_scene("res://scenes/ui/main_menu.tscn")
