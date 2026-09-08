extends Node2D


func _ready() -> void:
	$Area2D.area_entered.connect(on_area_entered)


func on_area_entered(_other_area: Area2D) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return

	$Area2D.set_deferred("monitoring", false)
	health.heal(health.max_health * 0.1)
	queue_free()
