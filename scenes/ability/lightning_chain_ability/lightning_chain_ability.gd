extends Node2D
class_name LightningChainAbility

@export var source: Node2D
@export var target: Node2D
@export var damage := 4.0


func _ready() -> void:
	if !is_instance_valid(source) || !is_instance_valid(target):
		queue_free()
		return

	global_position = source.global_position
	var target_offset := target.global_position - global_position
	$Line2D.points = PackedVector2Array([Vector2.ZERO, target_offset])
	$Sprite2D.position = target_offset * 0.5
	var hurtbox := target.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox != null:
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		hurtbox.health_component.damage(critical_hit["damage"])
		GameEvents.heal_from_damage(critical_hit["damage"])
		hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
		hurtbox.hit.emit()

	await get_tree().create_timer(0.15).timeout
	queue_free()
