extends Node


func _ready() -> void:
	var hud := preload("res://scenes/ui/boss_health_bar.tscn").instantiate()
	add_child(hud)
	var boss := Node.new()
	boss.name = "FutureBoss"
	boss.add_to_group("boss")
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	boss.add_child(health)
	add_child(boss)
	await get_tree().process_frame
	assert((hud.get_node("MarginContainer") as Control).visible)
	assert((hud.get_node("MarginContainer/VBoxContainer/NameLabel") as Label).text == "FutureBoss")
	health.damage(25.0)
	assert((hud.get_node("MarginContainer/VBoxContainer/ProgressBar") as ProgressBar).value == 0.75)
	boss.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not (hud.get_node("MarginContainer") as Control).visible)
	get_tree().quit()
