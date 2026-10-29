extends CanvasLayer

@onready var health_label: Label = %HealthLabel
@onready var shield_label: Label = %ShieldLabel
var health_component: HealthComponent


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var current := player.get_node_or_null("HealthComponent") as HealthComponent if is_instance_valid(player) and not player.is_queued_for_deletion() else null
	if current == health_component and is_instance_valid(current):
		return
	if is_instance_valid(health_component):
		if health_component.health_changed.is_connected(update_display):
			health_component.health_changed.disconnect(update_display)
		if health_component.shield_changed.is_connected(on_shield_changed):
			health_component.shield_changed.disconnect(on_shield_changed)
	health_component = current
	if is_instance_valid(health_component):
		health_component.health_changed.connect(update_display)
		health_component.shield_changed.connect(on_shield_changed)
	update_display()


func update_display() -> void:
	visible = is_instance_valid(health_component)
	if not visible:
		return
	health_label.text = "生命 %s / %s" % [format_amount(health_component.current_health), format_amount(health_component.max_health)]
	var shield := health_component.get_total_shield()
	shield_label.visible = shield > 0.0
	shield_label.text = "护盾 %s" % format_amount(shield)


func on_shield_changed(_amount: float) -> void:
	update_display()


func format_amount(amount: float) -> String:
	return str(roundi(amount)) if is_equal_approx(amount, roundf(amount)) else "%.1f" % amount
