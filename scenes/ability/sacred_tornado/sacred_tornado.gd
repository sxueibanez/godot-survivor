extends Node2D
class_name SacredTornado

const DURATION := 3.0
const SPEED := 35.0
const PULL_RADIUS := 140.0
const PULL_SPEED := 80.0
const FRAME_DURATION := 0.08
const BASE_VISUAL_SCALE := 0.17

var direction := Vector2.RIGHT
var damage := 6.0
var elapsed := 0.0
var size_multiplier := 1.0


func configure(start: Vector2, travel_direction: Vector2, weapon_damage: float, weapon_size: float = 1.0) -> void:
	global_position = start
	direction = travel_direction.normalized()
	damage = weapon_damage * 0.3
	size_multiplier = weapon_size


func _ready() -> void:
	$DamageTimer.timeout.connect(deal_damage)
	$Sprite2D.scale = Vector2.ONE * BASE_VISUAL_SCALE * size_multiplier


func _process(delta: float) -> void:
	elapsed += delta
	global_position += direction * SPEED * delta
	$Sprite2D.frame = floori(elapsed / FRAME_DURATION) % 9
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_in_group("boss") or global_position.distance_squared_to(enemy.global_position) > pow(PULL_RADIUS * size_multiplier, 2.0):
			continue
		enemy.global_position = enemy.global_position.move_toward(global_position, PULL_SPEED * delta)
	if elapsed >= DURATION:
		queue_free()


func deal_damage() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) > pow(PULL_RADIUS * size_multiplier, 2.0):
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("azure_dragon", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
