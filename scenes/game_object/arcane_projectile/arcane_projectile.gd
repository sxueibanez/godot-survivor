extends Node2D

const SPEED := 150.0
const DAMAGE := 30.0
const LIFETIME := 4.0

var direction := Vector2.RIGHT
var time_left := LIFETIME
var reflected := false


func _ready() -> void:
	rotation = direction.angle()
	$Sprite2D.rotation = -PI / 4.0


func _process(delta: float) -> void:
	global_position += direction * SPEED * delta
	time_left -= delta
	if reflected:
		check_enemy_hit()
		if time_left <= 0.0:
			queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) < 12.0:
		var health := player.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.damage(DAMAGE)
		queue_free()
	elif time_left <= 0.0:
		queue_free()


func reflect_to_enemy() -> void:
	if reflected:
		return
	reflected = true
	var closest_enemy: Node2D
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if closest_enemy == null or global_position.distance_squared_to(enemy.global_position) < global_position.distance_squared_to(closest_enemy.global_position):
			closest_enemy = enemy
	if closest_enemy != null:
		direction = (closest_enemy.global_position - global_position).normalized()
	else:
		direction = -direction
	rotation = direction.angle()
	$Sprite2D.rotation = -PI / 4.0
	modulate = Color(0.5, 1.0, 0.8)


func check_enemy_hit() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) >= 12.0 * 12.0:
			continue
		var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox != null and hurtbox.health_component != null:
			var critical_hit: Dictionary = GameEvents.get_critical_damage(DAMAGE)
			hurtbox.health_component.damage(critical_hit["damage"])
			GameEvents.record_weapon_damage("axe", critical_hit["damage"])
			GameEvents.heal_from_damage(critical_hit["damage"])
			hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
			hurtbox.hit.emit()
		queue_free()
		return
