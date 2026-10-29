extends Node


func send_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event, true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var selection := preload("res://scenes/ui/character_select.tscn").instantiate()
	add_child(selection)
	var expected_character: Resource = selection.elf_ranger
	var chosen: Array[Resource] = []
	selection.character_selected.connect(func(character: Resource): chosen.append(character))
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := selection.get_child(0).get_child(0) as ScrollContainer
	var list := scroll.get_child(0) as VBoxContainer
	assert(get_viewport().gui_get_focus_owner() == list.get_child(1))
	assert(scroll.follow_focus)
	send_action("ui_down")
	await get_tree().process_frame
	assert(get_viewport().gui_get_focus_owner() == list.get_child(2))
	send_action("ui_accept")
	await get_tree().process_frame
	assert(chosen.size() == 1 and chosen[0] == expected_character)
	assert(not get_tree().paused)

	var screen := preload("res://scenes/ui/upgrade_screen.tscn").instantiate()
	add_child(screen)
	var selected_upgrades: Array[AbilityUpgrade] = []
	screen.upgrade_selected.connect(func(upgrade: AbilityUpgrade): selected_upgrades.append(upgrade))
	var upgrades: Array[AbilityUpgrade] = [
		load("res://resources/upgrades/sword_damage.tres"),
		load("res://resources/upgrades/sword_rate.tres"),
		load("res://resources/upgrades/critical_hit.tres"),
	]
	screen.set_ability_upgrades(upgrades)
	await get_tree().create_timer(0.3, true).timeout
	assert(get_tree().paused and screen.keyboard_index == -1)
	send_action("ui_right")
	assert(screen.keyboard_index == 0)
	send_action("ui_right")
	assert(screen.keyboard_index == 1)
	var selected: Node = screen.card_container.get_child(1)
	assert(selected.get_node("%KeyHint").get_theme_color("font_color") == Color(1.0, 0.82, 0.2))
	assert(selected.get_node("%NameLabel").get_theme_color("font_color") == Color(1.0, 0.85, 0.35))
	screen.on_upgrade_disabled(upgrades[0], screen.card_container.get_child(0))
	assert(screen.keyboard_index == 0 and screen.card_container.get_child(0) == selected)
	send_action("ui_left")
	assert(screen.keyboard_index == 1)
	var final_card := screen.card_container.get_child(1) as AbilityUpgradeCard
	send_action("ui_accept")
	assert(final_card.disabled)
	send_action("ui_right")
	assert(screen.keyboard_index == 1)
	await get_tree().create_timer(0.9, true).timeout
	assert(selected_upgrades.size() == 1 and selected_upgrades[0] == upgrades[2])
	assert(not get_tree().paused)
	print("KEYBOARD_SELECTION_OK")
	get_tree().quit()
