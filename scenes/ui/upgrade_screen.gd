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


func _ready():
	get_tree().paused = true


func _unhandled_key_input(event: InputEvent) -> void:
	if closing or not event.is_pressed() or event.is_echo():
		return
	var card_index := (event as InputEventKey).keycode - KEY_1
	var cards := card_container.get_children()
	if card_index < 0 or card_index >= cards.size():
		return
	if (cards[card_index] as AbilityUpgradeCard).disabled:
		return
	get_viewport().set_input_as_handled()
	(cards[card_index] as AbilityUpgradeCard).select_card()


func set_ability_upgrades(upgrades: Array[AbilityUpgrade]):
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
	card_container.remove_child(card)
	card.queue_free()
	for index in card_container.get_child_count():
		card_container.get_child(index).get_node("%KeyHint").text = str(index + 1)
	if available_card_count <= 0:
		closing = true
		closed_without_selection.emit()
		close_screen()


func close_screen() -> void:
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	queue_free()
