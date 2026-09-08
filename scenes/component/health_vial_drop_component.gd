extends Node
class_name HealthVialDropComponent

@export var health_component: HealthComponent
@export var vial_scene: PackedScene


func _ready() -> void:
	health_component.died.connect(on_died)


func on_died() -> void:
	if MetaProgression.get_upgrade_count("health_vial_drop") == 0 || randf() > MetaProgression.get_upgrade_count("health_vial_drop") * 0.05:
		return

	var vial := vial_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("entities_layer").add_child(vial)
	vial.global_position = (owner as Node2D).global_position
