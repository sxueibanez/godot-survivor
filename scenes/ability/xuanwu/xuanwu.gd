extends Node2D
class_name XuanwuAbility

const FOLLOW_DISTANCE := 38.0
const FOLLOW_SPEED := 5.0
const SHIELD_PERCENT := 0.2
const REVIVE_HEALTH_PERCENT := 0.3
const INVULNERABLE_DURATION := 3.0
const FRAME_DURATION := 0.12

var player: Node2D
var health: HealthComponent
var last_move_direction := Vector2.DOWN
var animation_time := 0.0
var death_save_used := false
var ultimate_active := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	global_position = player.global_position + Vector2.DOWN * FOLLOW_DISTANCE
	health = player.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.health_changed.connect(on_player_health_changed)
		health.shield_changed.connect(on_shield_changed)
	$ShieldTimer.timeout.connect(generate_shield)


func _process(delta: float) -> void:
	if ultimate_active or not is_instance_valid(player):
		return
	animation_time += delta
	$Sprite2D.frame = floori(animation_time / FRAME_DURATION) % 9
	var velocity: Vector2 = player.get("velocity")
	if velocity.length_squared() > 1.0:
		last_move_direction = velocity.normalized()
	var target := player.global_position - last_move_direction * FOLLOW_DISTANCE
	global_position = global_position.lerp(target, minf(FOLLOW_SPEED * delta, 1.0))
	$Sprite2D.flip_h = last_move_direction.x < 0.0


func generate_shield() -> void:
	if health != null:
		health.set_shield(health.max_health * SHIELD_PERCENT)


func on_player_health_changed() -> void:
	if health == null or health.current_health > 0.0 or death_save_used:
		return
	death_save_used = true
	health.current_health = health.max_health * REVIVE_HEALTH_PERCENT
	health.set_invulnerable(INVULNERABLE_DURATION)
	health.health_changed.emit()


func on_shield_changed(current_shield: float) -> void:
	$Sprite2D.modulate = Color(0.55, 0.9, 1.0) if current_shield > 0.0 else Color.WHITE


func set_ultimate_active(active: bool) -> void:
	ultimate_active = active
