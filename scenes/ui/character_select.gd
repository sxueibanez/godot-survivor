extends CanvasLayer

signal character_selected(character: Resource)

var warrior: Resource = preload("res://resources/characters/warrior.tres")
var elf_ranger: Resource = preload("res://resources/characters/elf_ranger.tres")
var blooddrinker: Resource = preload("res://resources/characters/blooddrinker.tres")
var new_characters: Array[Resource] = [
	preload("res://resources/characters/lone_gunner.tres"),
	preload("res://resources/characters/gambling_scholar.tres"),
	preload("res://resources/characters/ronin.tres"),
	preload("res://resources/characters/avenger.tres"),
	preload("res://resources/characters/one_armed.tres"),
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300.0
	panel.offset_top = -165.0
	panel.offset_right = 300.0
	panel.offset_bottom = 165.0
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var title := Label.new()
	title.text = "选择角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	add_character_button(content, warrior)
	add_character_button(content, elf_ranger)
	add_character_button(content, blooddrinker)
	for data: Resource in new_characters:
		add_character_button(content, data)


func add_character_button(content: Container, character: Resource) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 78)
	button.add_theme_font_size_override("font_size", 12)
	button.icon = character.get("sprite") as Texture2D
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 40)
	var melee_bonus := float(character.get("melee_damage_bonus"))
	var ranged_bonus := float(character.get("ranged_damage_bonus"))
	var lines: Array[String] = ["生命 %d · 移速 %d" % [int(character.get("max_health")), int(character.get("move_speed"))]]
	if melee_bonus > 0.0:
		lines.append("近战伤害 +%.0f%%" % (melee_bonus * 100.0))
	if ranged_bonus > 0.0:
		lines.append("远程伤害 +%.0f%%" % (ranged_bonus * 100.0))
	var passive_description := String(character.get("passive_description"))
	if !passive_description.is_empty():
		lines.append(passive_description)
	button.text = "%s\n%s" % [character.get("display_name"), "\n".join(lines)]
	button.pressed.connect(select_character.bind(character))
	content.add_child(button)


func select_character(character: Resource) -> void:
	get_tree().paused = false
	character_selected.emit(character)
	queue_free()
