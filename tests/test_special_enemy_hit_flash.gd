extends Node


func _ready() -> void:
	var enemy := Node2D.new()
	add_child(enemy)
	var health := HealthComponent.new()
	enemy.add_child(health)
	var sprite := AnimatedSprite2D.new()
	enemy.add_child(sprite)
	var flash := preload("res://scenes/component/hit_flash_component.gd").new()
	flash.health_component = health
	flash.sprite = sprite
	flash.hit_flash_material = ShaderMaterial.new()
	flash.hit_flash_material.shader = load("res://scenes/component/hit_flash_component.gdshader")
	enemy.add_child(flash)
	await get_tree().process_frame
	health.damage(1.0)
	assert(is_equal_approx((sprite.material as ShaderMaterial).get_shader_parameter("lerp_percent"), 1.0))
	get_tree().quit()
