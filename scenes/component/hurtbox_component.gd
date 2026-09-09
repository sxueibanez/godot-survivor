extends Area2D
class_name HurtboxComponent

signal hit

@export var health_component: HealthComponent

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")


func _ready():
	area_entered.connect(on_area_entered)


func on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return

	if health_component == null:
		return

	var hitbox_component = other_area as HitboxComponent
	var critical_hit: Dictionary = GameEvents.get_critical_damage(hitbox_component.damage)
	health_component.damage(critical_hit["damage"])
	GameEvents.record_weapon_damage(hitbox_component.weapon_id, critical_hit["damage"])
	GameEvents.heal_from_damage(critical_hit["damage"])
	show_damage(critical_hit["damage"], critical_hit["critical"])
	
	hit.emit()


func show_damage(damage_amount: float, is_critical: bool = false) -> void:

	var floating_text = floating_text_scene.instantiate() as FloatingText
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)

	floating_text.global_position = global_position + (Vector2.UP * 16)
	
	# cut out for brevity
	var fmt_string := "%0.1f"
	if is_equal_approx(damage_amount, int(damage_amount)):
		fmt_string = "%0.0f"
	floating_text.start(fmt_string % damage_amount, is_critical)
