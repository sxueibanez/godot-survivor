extends CanvasLayer

signal character_selected(character: Resource)

var warrior: Resource = preload("res://resources/characters/warrior.tres")
var elf_ranger: Resource = preload("res://resources/characters/elf_ranger.tres")
var blooddrinker: Resource = preload("res://resources/characters/blooddrinker.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -180.0
	panel.offset_top = -150.0
	panel.offset_right = 180.0
	panel.offset_bottom = 150.0
	add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = "选择角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	add_character_button(content, warrior)
	add_character_button(content, elf_ranger)
	add_character_button(content, blooddrinker)


func add_character_button(content: Container, character: Resource) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 78)
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
