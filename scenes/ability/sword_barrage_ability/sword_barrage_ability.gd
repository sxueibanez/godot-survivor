extends Node2D
class_name SwordBarrageAbility


const DURATION := 2.0
const DAMAGE_RADIUS := 28.0
const SWORD_COUNT := 10
const LAUNCH_INTERVAL := DURATION / SWORD_COUNT
const SWORD_SPEED := 300.0
const SWORD_LIFETIME := 1.2
const SWORD_HIT_RADIUS := 12.0
const SWORD_TEXTURE: Texture2D = preload("res://assets/abilities/sword_barrage.png")

var origin_position := Vector2.ZERO
var target_position := Vector2.ZERO
var damage := 7.5
var elapsed := 0.0
var launch_time_left := 0.0
var launched_count := 0
var active_swords: Array[Dictionary] = []


func _process(delta: float) -> void:
	elapsed += delta
	launch_time_left -= delta
	while launched_count < SWORD_COUNT and launch_time_left <= 0.0:
		launch_sword()
		launched_count += 1
		launch_time_left += LAUNCH_INTERVAL
	update_active_swords(delta)
	modulate.a = minf(elapsed * 3.0, 1.0) * clampf((DURATION + SWORD_LIFETIME - elapsed) / 0.3, 0.0, 1.0)
	queue_redraw()
	if launched_count >= SWORD_COUNT and active_swords.is_empty():
		queue_free()


func launch_sword() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var origin: Vector2 = player.global_position
	var direction: Vector2 = (target_position - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var sword: Sprite2D = Sprite2D.new()
	sword.texture = SWORD_TEXTURE
	sword.scale = Vector2.ONE * 0.035
	sword.z_index = 2
	add_child(sword)
	sword.global_position = origin
	sword.rotation = direction.angle() - PI * 0.5
	active_swords.append({"sprite": sword, "direction": direction, "time_left": SWORD_LIFETIME})


func update_active_swords(delta: float) -> void:
	for index: int in range(active_swords.size() - 1, -1, -1):
		var sword_data: Dictionary = active_swords[index]
		var sword: Sprite2D = sword_data["sprite"] as Sprite2D
		if sword == null:
			active_swords.remove_at(index)
			continue
		var direction: Vector2 = sword_data["direction"] as Vector2
		sword.global_position += direction * SWORD_SPEED * delta
		var time_left: float = float(sword_data["time_left"]) - delta
		if hit_first_enemy(sword) or time_left <= 0.0:
			sword.queue_free()
			active_swords.remove_at(index)
			continue
		sword_data["time_left"] = time_left
		active_swords[index] = sword_data


func hit_first_enemy(sword: Sprite2D) -> bool:
	for enemy_value: Variant in get_tree().get_nodes_in_group("enemy"):
		var enemy: Node2D = enemy_value as Node2D
		if enemy == null or sword.global_position.distance_squared_to(enemy.global_position) > SWORD_HIT_RADIUS * SWORD_HIT_RADIUS:
			continue
		var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount: float = float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("sword", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		return true
	return false


func _draw() -> void:
	var endpoint: Vector2 = target_position - global_position
	draw_arc(endpoint, DAMAGE_RADIUS, 0.0, TAU, 24, Color(0.2, 0.7, 1.0, 0.8), 1.5)
