extends Node2D
class_name CorrosivePuddle


const LIFETIME := 10.0
const DAMAGE := 20.0
const DAMAGE_INTERVAL := 0.5
const DAMAGE_RADIUS := 34.0
const VISUAL_SCALE := 0.05

@onready var sprite: Sprite2D = $Sprite2D

var active := false
var lifetime := LIFETIME
var damage := DAMAGE
var slow_percent := 0.0
var slow_duration := 0.0
var fade_duration := 1.0
var time_left := LIFETIME
var damage_time_left := 0.0
var elapsed := 0.0


func _ready() -> void:
	scale = Vector2.ZERO


func launch_to(destination: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", destination, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(activate)


func activate() -> void:
	active = true


func configure(new_lifetime: float, new_damage: float, new_slow_percent: float = 0.0, new_slow_duration: float = 0.0, new_fade_duration: float = 1.0) -> void:
	lifetime = new_lifetime
	time_left = lifetime
	damage = new_damage
	slow_percent = new_slow_percent
	slow_duration = new_slow_duration
	fade_duration = new_fade_duration


func _process(delta: float) -> void:
	if !active:
		return
	elapsed += delta
	time_left -= delta
	damage_time_left -= delta
	var pulse: float = 1.0 + sin(elapsed * 5.0) * 0.06
	sprite.scale = Vector2.ONE * VISUAL_SCALE * pulse
	sprite.rotation = sin(elapsed * 2.0) * 0.025
	if time_left <= fade_duration:
		modulate.a = clampf(time_left / fade_duration, 0.0, 1.0)
	if time_left <= 0.0:
		queue_free()
		return
	deal_damage()


func deal_damage() -> void:
	if damage_time_left > 0.0:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_squared_to(player.global_position) > DAMAGE_RADIUS * DAMAGE_RADIUS:
		return
	var player_health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health != null:
		player_health.damage(damage)
		var player_velocity: VelocityComponent = player.get_node_or_null("VelocityComponent") as VelocityComponent
		if player_velocity != null and slow_percent > 0.0:
			player_velocity.apply_slow(slow_percent, slow_duration)
		damage_time_left = DAMAGE_INTERVAL
