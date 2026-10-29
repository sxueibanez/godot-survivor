extends Node


func _ready() -> void:
	var hud := preload("res://scenes/ui/boss_health_bar.tscn").instantiate()
	add_child(hud)
	var boss := Node2D.new()
	boss.name = "TestBoss"
	boss.add_to_group("boss")
	add_child(boss)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	boss.add_child(health)
	await get_tree().process_frame
	await get_tree().process_frame
	var fill := hud.get_node("%ProgressBar") as ProgressBar
	var delay := hud.get_node("%DamageBar") as ProgressBar
	var label := hud.get_node("%HealthPercent") as Label
	assert(fill.value == 1.0 and delay.value == 1.0 and label.text == "100%")
	health.current_health = health.max_health * 0.5
	health.health_changed.emit()
	assert(fill.value == 0.5 and delay.value == 1.0 and label.text == "50%")
	await get_tree().create_timer(0.1).timeout
	health.current_health = health.max_health * 0.3
	health.health_changed.emit()
	assert(fill.value == 0.3 and label.text == "30%")
	await get_tree().create_timer(0.7).timeout
	assert(is_equal_approx(delay.value, 0.3))
	health.current_health = health.max_health * 0.8
	health.health_changed.emit()
	assert(is_equal_approx(delay.value, 0.8) and label.text == "80%")
	boss.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not hud.get_node("MarginContainer").visible)
	print("BOSS_DAMAGE_FEEDBACK_OK")
	get_tree().quit()
