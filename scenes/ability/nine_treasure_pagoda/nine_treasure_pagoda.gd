extends Node2D
class_name NineTreasurePagodaAbility

const FRAME_SIZE := Vector2(458, 381)
const FRAME_DURATION := 0.11
const FOLLOW_DISTANCE := 34.0
const FOLLOW_SPEED := 10.0
const BASE_VISUAL_SCALE := 0.085
const WHITE_LIGHT_COOLDOWN := 5.0
const WHITE_LIGHT_RADIUS := 90.0
const STUN_DURATION := 1.0

class WhiteLightPulse extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, WHITE_LIGHT_RADIUS, Color(1.0, 1.0, 1.0, 0.12))
		draw_arc(Vector2.ZERO, WHITE_LIGHT_RADIUS, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.8), 3.0)

@onready var sprite: Sprite2D = $Sprite2D

var player: CharacterBody2D
var last_direction := Vector2.DOWN
var animation_time := 0.0
var size_multiplier := 1.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player != null:
		global_position = player.global_position - last_direction * FOLLOW_DISTANCE
	$WhiteLightTimer.timeout.connect(emit_white_light)
	refresh_size()
	$LaunchSound.play()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	var movement: Vector2 = player.velocity
	if movement.length_squared() > 1.0:
		last_direction = movement.normalized()
	var target_position := player.global_position - last_direction * FOLLOW_DISTANCE + Vector2(0, -4)
	global_position = global_position.lerp(target_position, 1.0 - exp(-FOLLOW_SPEED * delta))
	animation_time += delta
	var frame := floori(animation_time / FRAME_DURATION) % 9
	sprite.region_rect = Rect2(Vector2(frame % 3, floori(frame / 3.0)) * FRAME_SIZE, FRAME_SIZE)


func set_size_multiplier(value: float) -> void:
	size_multiplier = value
	if is_node_ready():
		refresh_size()


func refresh_size() -> void:
	sprite.scale = Vector2.ONE * BASE_VISUAL_SCALE * size_multiplier


func emit_white_light() -> void:
	var radius := WHITE_LIGHT_RADIUS * size_multiplier
	var hit_any_enemy := false
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		var velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
		if velocity != null:
			velocity.apply_stun(STUN_DURATION)
			hit_any_enemy = true
	if hit_any_enemy:
		$HitSound.play()
	var pulse := WhiteLightPulse.new()
	pulse.z_index = -1
	pulse.global_position = global_position
	pulse.scale = Vector2.ONE * 0.15 * size_multiplier
	get_parent().add_child(pulse)
	var tween := pulse.create_tween().set_parallel()
	tween.tween_property(pulse, "scale", Vector2.ONE * size_multiplier, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(pulse.queue_free)
