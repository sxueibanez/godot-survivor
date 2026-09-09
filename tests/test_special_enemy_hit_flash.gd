extends Node


func _ready() -> void:
	for scene: PackedScene in [preload("res://scenes/game_object/ranged_enemy/ranged_enemy.tscn"), preload("res://scenes/game_object/exploder_enemy/exploder_enemy.tscn")]:
		var enemy := scene.instantiate()
		add_child(enemy)
		await get_tree().process_frame
		(enemy.get_node("HealthComponent") as HealthComponent).damage(1.0)
		var material := (enemy.get_node("Visuals/Sprite2D") as Sprite2D).material as ShaderMaterial
		assert(is_equal_approx(material.get_shader_parameter("lerp_percent"), 1.0))
		enemy.queue_free()
	get_tree().quit()
