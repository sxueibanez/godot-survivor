extends Node
class_name VelocityComponent

signal slow_changed(active: bool)

class StunIndicator extends Node2D:
	var time_left := 0.0
	var elapsed := 0.0

	func start(duration: float) -> void:
		time_left = maxf(time_left, duration)
		visible = true

	func _process(delta: float) -> void:
		if time_left <= 0.0:
			visible = false
			return
		time_left -= delta
		elapsed += delta
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var angle: float = elapsed * 8.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(angle) * 6.0, sin(angle) * 2.0), 2.0, Color(1.0, 0.9, 0.2))


@export var max_speed: int = 40
@export var acceleration: float = 5
 
var velocity := Vector2.ZERO
var slow_multiplier := 1.0
var slow_time_left := 0.0
var stun_time_left := 0.0
var knockback_time_left := 0.0
var knockback_velocity := Vector2.ZERO
var stun_indicator: StunIndicator


func _ready() -> void:
	var owner_node := owner as Node2D
	if owner_node == null:
		return
	stun_indicator = StunIndicator.new()
	stun_indicator.position = Vector2(0, -20)
	stun_indicator.z_index = 3
	stun_indicator.visible = false
	owner_node.add_child.call_deferred(stun_indicator)


func _process(delta: float) -> void:
	if stun_time_left > 0.0:
		stun_time_left -= delta
		velocity = Vector2.ZERO
		return

	if knockback_time_left > 0.0:
		knockback_time_left -= delta
		velocity = knockback_velocity
		return

	if slow_time_left <= 0:
		if slow_multiplier != 1.0:
			slow_multiplier = 1.0
			slow_changed.emit(false)
		return

	slow_time_left -= delta
	if slow_time_left <= 0:
		slow_multiplier = 1.0
		slow_changed.emit(false)


func apply_slow(slow_percent: float, duration: float) -> void:
	slow_multiplier = min(slow_multiplier, 1.0 - slow_percent)
	slow_time_left = max(slow_time_left, duration)
	slow_changed.emit(true)


func apply_stun(duration: float) -> void:
	stun_time_left = maxf(stun_time_left, duration)
	velocity = Vector2.ZERO
	if stun_indicator != null:
		stun_indicator.start(duration)


func apply_knockback(direction: Vector2, speed: float, duration: float) -> void:
	knockback_velocity = direction.normalized() * speed
	velocity = knockback_velocity
	knockback_time_left = maxf(knockback_time_left, duration)


func accelerate_to_player():
	var owner_node2d = owner as Node2D
	if owner_node2d == null:
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var direction = (player.global_position - owner_node2d.global_position).normalized()
	accelerate_in_direction(direction)


func accelerate_in_direction(direction: Vector2):
	if stun_time_left > 0.0 or knockback_time_left > 0.0:
		velocity = Vector2.ZERO
		return
	var desired_velocity = direction * max_speed * slow_multiplier
	velocity = velocity.lerp(desired_velocity, 1 - exp(-acceleration * get_process_delta_time()))


func move(character_body: CharacterBody2D):
	if stun_time_left > 0.0:
		character_body.velocity = Vector2.ZERO
		return
	character_body.velocity = velocity
	character_body.move_and_slide()

	velocity = character_body.velocity
