extends Node2D

var nearby_area: Area2D
var collecting := false

func _ready() -> void:
	$Area2D.area_entered.connect(on_area_entered)
	$Area2D.area_exited.connect(on_area_exited)
	set_process(false)
	var bob := create_tween().set_loops()
	bob.tween_property($Sprite2D, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property($Sprite2D, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 11.0, Color(0.2, 0.95, 0.5, 0.12))
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 24, Color(0.3, 1.0, 0.6, 0.55), 1.0)


func on_area_entered(other_area: Area2D) -> void:
	if not other_area.get_parent().is_in_group("player"):
		return
	nearby_area = other_area
	set_process(true)
	try_collect()


func on_area_exited(other_area: Area2D) -> void:
	if other_area == nearby_area:
		nearby_area = null
		set_process(false)


func _process(_delta: float) -> void:
	try_collect()


func try_collect() -> void:
	if collecting or not is_instance_valid(nearby_area):
		return
	var player := nearby_area.get_parent() as Node2D
	if player == null:
		return

	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health == null or health.current_health <= 0.0 or health.current_health >= health.max_health or GameEvents.curse_no_normal_healing:
		return

	collecting = true
	$Area2D.set_deferred("monitoring", false)
	var missing_health := maxf(health.max_health - health.current_health, 0.0)
	health.heal(health.max_health * 0.1 + missing_health * 0.1)
	queue_free()
