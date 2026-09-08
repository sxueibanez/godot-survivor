extends CanvasLayer

signal character_selected(character: Resource)

var warrior: Resource = preload("res://resources/characters/warrior.tres")
var elf_ranger: Resource = preload("res://resources/characters/elf_ranger.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -180.0
	panel.offset_top = -105.0
	panel.offset_right = 180.0
	panel.offset_bottom = 105.0
	add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = "选择角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	add_character_button(content, warrior, "战士\n近战伤害 +15%")
	add_character_button(content, elf_ranger, "魔导师\n远程伤害 +15%")


func add_character_button(content: Container, character: Resource, label_text: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 66)
	button.text = label_text
	button.pressed.connect(select_character.bind(character))
	content.add_child(button)


func select_character(character: Resource) -> void:
	get_tree().paused = false
	character_selected.emit(character)
	queue_free()
