extends CanvasLayer

signal upgrade_selected(upgrade: AbilityUpgrade)
signal upgrade_disabled(upgrade: AbilityUpgrade)
signal closed_without_selection
signal health_reroll_requested

@export var upgrade_card_scene: PackedScene
@onready var card_container: HBoxContainer = %CardContainer

var available_card_count := 0
var closing := false
var health_reroll_button: Button
var health_reroll_used := false


func _ready():
	get_tree().paused = true


func _unhandled_key_input(event: InputEvent) -> void:
	if closing or not event.is_pressed() or event.is_echo():
		return
	var card_index := (event as InputEventKey).keycode - KEY_1
	var cards := card_container.get_children()
	if card_index < 0 or card_index >= mini(3, cards.size()):
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
		card_instance.set_ability_upgrade(upgrade)
		card_instance.play_in(delay)
		card_instance.selected.connect(on_upgrade_selected.bind(upgrade))
		card_instance.disabled_for_run.connect(on_upgrade_disabled.bind(upgrade, card_instance))
		delay += 0.06


func enable_health_reroll(fraction: float) -> void:
	health_reroll_button = Button.new()
	health_reroll_button.text = "赌命刷新：消耗当前生命 %.0f%%（本次升级限一次）" % (fraction * 100.0)
	add_child(health_reroll_button)
	health_reroll_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	health_reroll_button.offset_left = -240.0
	health_reroll_button.offset_right = 240.0
	health_reroll_button.offset_top = -50.0
	health_reroll_button.offset_bottom = -10.0
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
	card.queue_free()
	if available_card_count <= 0:
		closing = true
		closed_without_selection.emit()
		close_screen()


func close_screen() -> void:
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	queue_free()
