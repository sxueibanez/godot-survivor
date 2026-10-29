extends CanvasLayer

const CHARACTERS: Array[Resource] = [
	preload("res://resources/characters/warrior.tres"),
	preload("res://resources/characters/elf_ranger.tres"),
	preload("res://resources/characters/blooddrinker.tres"),
	preload("res://resources/characters/lone_gunner.tres"),
	preload("res://resources/characters/gambling_scholar.tres"),
	preload("res://resources/characters/ronin.tres"),
	preload("res://resources/characters/avenger.tres"),
	preload("res://resources/characters/one_armed.tres"),
]
const SIGNATURES := {
	"warrior": "近身击杀：获得最大生命 0.2% 的护盾/级，持续 3 秒，上限 10%",
	"elf_ranger": "击杀 5 个敌人：下次攻击伤害 +10%/级",
	"blooddrinker": "生命不高于 50% 时击败精英或首领：恢复最大生命 1%/级",
	"lone_gunner": "击败精英或首领：危险加速冷却减少 0.5 秒/级",
	"gambling_scholar": "生命刷新消耗降低 1%/级，最低消耗当前生命 5%",
	"ronin": "冲刺后的强化期间，每次击杀使冲刺冷却减少 0.1 秒/级",
	"avenger": "狂怒期间击杀延长狂怒 0.1 秒/级，每次狂怒最多延长 3 秒",
	"one_armed": "每击杀 10 个敌人，4 秒内武器伤害额外 +5%/级",
}

var selected := 0
var currency_label: Label
var details: Label
var buttons: Dictionary = {}

func _ready() -> void:
	layer = 30
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = "角色培养 · 仅提升所选角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	currency_label = Label.new()
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(currency_label)
	var choices := OptionButton.new()
	for character: Resource in CHARACTERS:
		choices.add_item(character.display_name)
	choices.item_selected.connect(select_character)
	box.add_child(choices)
	details = Label.new()
	details.custom_minimum_size.x = 440
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(details)
	var button := Button.new()
	button.pressed.connect(buy.bind("signature"))
	box.add_child(button)
	buttons["signature"] = button
	var back := Button.new()
	back.text = "返回主菜单"
	back.pressed.connect(queue_free)
	box.add_child(back)
	refresh()
	choices.grab_focus.call_deferred()

func select_character(index: int) -> void:
	selected = index
	refresh()

func buy(stat: String) -> void:
	MetaProgression.purchase_character_upgrade(CHARACTERS[selected].id, stat)
	refresh()

func refresh() -> void:
	var character: Resource = CHARACTERS[selected]
	var currency := int(MetaProgression.save_data.get("meta_upgrade_currency", 0))
	currency_label.text = "永久升级瓶子：%d" % currency
	details.text = "%s · 专属永久强化\n%s" % [character.display_name, SIGNATURES[character.id]]
	var level := MetaProgression.get_character_upgrade(character.id, "signature")
	var cost := MetaProgression.character_upgrade_cost(character.id, "signature")
	var button: Button = buttons["signature"]
	button.text = "专属强化  %d / %d  ·  %s" % [level, MetaProgression.CHARACTER_UPGRADE_MAX, "已满级" if level >= MetaProgression.CHARACTER_UPGRADE_MAX else "下一级 %d 瓶" % cost]
	button.disabled = level >= MetaProgression.CHARACTER_UPGRADE_MAX or currency < cost
