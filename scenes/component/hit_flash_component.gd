extends Node

@export var health_component: HealthComponent
@export var sprite: CanvasItem
@export var hit_flash_material: ShaderMaterial

var hit_flash_tween: Tween


func _ready():
	health_component.damage_taken.connect(on_damage_taken)
	sprite.material = hit_flash_material.duplicate()


func on_damage_taken(amount: float):
	if amount <= 0.0:
		return
	if hit_flash_tween != null && hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	
	(sprite.material as ShaderMaterial).set_shader_parameter("lerp_percent", 1.0)
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(sprite.material, "shader_parameter/lerp_percent", 0.0, 0.25)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)
