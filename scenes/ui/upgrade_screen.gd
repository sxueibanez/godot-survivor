extends CanvasLayer

signal upgrade_selected(upgrade: AbilityUpgrade)
signal upgrade_disabled(upgrade: AbilityUpgrade)
signal closed_without_selection
signal health_reroll_requested
signal dangerous_investment_requested

@export var upgrade_card_scene: PackedScene
@onready var card_container: HBoxContainer = %CardContainer

var available_card_count := 0
var closing := false
var health_reroll_button: Button
var health_reroll_used := false
var allow_disable := true
var dangerous_investment_button: Button
var keyboard_index := -1


func _unhandled_input(event: InputEvent) -> void:
	if closing or not event.is_pressed() or event.is_echo():
		return
	var cards := card_container.get_children()
	if cards.is_empty():
		return
	if cards.any(func(card: Node): return (card as AbilityUpgradeCard).disabled):
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var step := -1 if event.is_action_pressed("ui_left") else 1
		var index := keyboard_index if keyboard_index >= 0 else (-1 if step > 0 else 0)
		for _attempt in cards.size():
			index = posmod(index + step, cards.size())
			if not (cards[index] as AbilityUpgradeCard).disabled:
				set_keyboard_selection(index)
				break
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and keyboard_index >= 0:
		var card := cards[keyboard_index] as AbilityUpgradeCard
		if not card.disabled:
			get_viewport().set_input_as_handled()
			card.select_card()


func set_keyboard_selection(index: int) -> void:
	keyboard_index = index
	for card_index in card_container.get_child_count():
		var hint := card_container.get_child(card_index).get_node("%KeyHint") as Label
		if card_index == keyboard_index:
			hint.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
			hint.add_theme_font_size_override("font_size", 20)
			card_container.get_child(card_index).get_node("%NameLabel").add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		else:
			hint.remove_theme_color_override("font_color")
			hint.add_theme_font_size_override("font_size", 16)
			card_container.get_child(card_index).get_node("%NameLabel").remove_theme_color_override("font_color")


func _ready():
	get_tree().paused = true


func _unhandled_key_input(event: InputEvent) -> void:
	if closing or not event.is_pressed() or event.is_echo():
		return
	var card_index := (event as InputEventKey).keycode - KEY_1
	var cards := card_container.get_children()
	if cards.any(func(card: Node): return (card as AbilityUpgradeCard).disabled):
		return
	if card_index < 0 or card_index >= cards.size():
		return
	if (cards[card_index] as AbilityUpgradeCard).disabled:
		return
	get_viewport().set_input_as_handled()
	(cards[card_index] as AbilityUpgradeCard).select_card()


func set_ability_upgrades(upgrades: Array[AbilityUpgrade]):
	keyboard_index = -1
	for card: Node in card_container.get_children():
		card_container.remove_child(card)
		card.queue_free()
	available_card_count = upgrades.size()
	var delay := 0.0
	for upgrade in upgrades:
		var card_instance = upgrade_card_scene.instantiate()
		card_container.add_child(card_instance)
		card_instance.get_node("%KeyHint").text = str(card_container.get_child_count())
		card_instance.set_ability_upgrade(upgrade)
		card_instance.get_node("%DisableButton").visible = allow_disable
		card_instance.play_in(delay)
		card_instance.selected.connect(on_upgrade_selected.bind(upgrade))
		card_instance.disabled_for_run.connect(on_upgrade_disabled.bind(upgrade, card_instance))
		delay += 0.06


func set_disable_allowed(value: bool) -> void:
	allow_disable = value
	for card: Node in card_container.get_children():
		card.get_node("%DisableButton").visible = value


func enable_dangerous_investment(can_afford: bool) -> void:
	dangerous_investment_button = Button.new()
	dangerous_investment_button.text = "危险投资：生命 -10%\n本次改为 4 选 1"
	dangerous_investment_button.tooltip_text = "使用后，下一次升级的属性效果提高 20%"
	dangerous_investment_button.disabled = not can_afford
	dangerous_investment_button.add_theme_font_size_override("font_size", 10)
	add_child(dangerous_investment_button)
	dangerous_investment_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	dangerous_investment_button.offset_left = -116.0
	dangerous_investment_button.offset_right = -8.0
	dangerous_investment_button.offset_top = -25.0
	dangerous_investment_button.offset_bottom = 25.0
	dangerous_investment_button.pressed.connect(func(): dangerous_investment_requested.emit())


func enable_health_reroll(fraction: float) -> void:
	health_reroll_button = Button.new()
	health_reroll_button.text = "刷新\n生命 -%.0f%%" % (fraction * 100.0)
	health_reroll_button.tooltip_text = "消耗当前生命刷新技能，每次升级限一次"
	health_reroll_button.add_theme_font_size_override("font_size", 10)
	add_child(health_reroll_button)
	health_reroll_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	health_reroll_button.offset_left = 8.0
	health_reroll_button.offset_right = 72.0
	health_reroll_button.offset_top = -22.0
	health_reroll_button.offset_bottom = 22.0
	health_reroll_button.pressed.connect(on_health_reroll_pressed)


func on_health_reroll_pressed() -> void:
	if closing or health_reroll_used:
		return
	health_reroll_requested.emit()


func on_upgrade_selected(upgrade: AbilityUpgrade):
	if closing:
		return
	closing = true
	upgrade_selected.emit(upgrade)
	close_screen()


func on_upgrade_disabled(upgrade: AbilityUpgrade, card: Control) -> void:
	upgrade_disabled.emit(upgrade)
	available_card_count -= 1
	var previously_selected: Node = card_container.get_child(keyboard_index) if keyboard_index >= 0 and keyboard_index < card_container.get_child_count() else null
	card_container.remove_child(card)
	card.queue_free()
	for index in card_container.get_child_count():
		card_container.get_child(index).get_node("%KeyHint").text = str(index + 1)
	if keyboard_index >= 0 and card_container.get_child_count() > 0:
		var selected_index := card_container.get_children().find(previously_selected)
		set_keyboard_selection(selected_index if selected_index >= 0 else mini(keyboard_index, card_container.get_child_count() - 1))
	if available_card_count <= 0:
		closing = true
		closed_without_selection.emit()
		close_screen()


func close_screen() -> void:
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	queue_free()
