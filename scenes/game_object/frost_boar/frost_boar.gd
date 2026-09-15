extends CharacterBody2D

const FRAME_COLUMNS := [0, 444, 887, 1331, 1774]
const FRAME_ROWS := [0, 444, 887]
const WARNING_DURATION := 0.55
const CHARGE_SPEED := 340.0
const CHARGE_DISTANCE := 290.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var cooldown := 1.4
var warning_time := 0.0
var charging := false
var charge_direction := Vector2.RIGHT
var distance_left := 0.0
var hit_player := false
var trail_time := 0.0
var animation_time := 0.0
var normal_mask := 0


class ChargeWarning extends Node2D:
	var direction: Vector2
	var elapsed := 0.0

	func _init(new_direction: Vector2) -> void:
		direction = new_direction

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= WARNING_DURATION:
			queue_free()

	func _draw() -> void:
		var alpha := 0.35 + sin(elapsed * 26.0) * 0.18
		draw_line(Vector2.ZERO, direction * CHARGE_DISTANCE, Color(0.45, 0.9, 1.0, alpha), 34.0)
		draw_line(Vector2.ZERO, direction * CHARGE_DISTANCE, Color.WHITE, 2.0)


class IceTrail extends Node2D:
	var time_left := 3.0

	func _process(delta: float) -> void:
		time_left -= delta
		modulate.a = minf(time_left, 1.0)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and global_position.distance_squared_to(player.global_position) <= 25.0 * 25.0:
			var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
			if movement != null:
				movement.apply_slippery(0.2)
		if time_left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 25.0, Color(0.35, 0.82, 1.0, 0.2))
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 18, Color(0.75, 0.95, 1.0, 0.55), 1.5)


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
	animation_time += delta * (3.0 if charging else 1.0)
	show_frame(int(animation_time * 8.0) % 8)
	if warning_time > 0.0:
		warning_time -= delta
		if warning_time <= 0.0:
			charging = true
			normal_mask = collision_mask
			collision_mask = 1
		return
	if charging:
		charge(delta)
		return
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	cooldown -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if cooldown <= 0.0 and player != null and global_position.distance_to(player.global_position) <= 260.0:
		start_charge(player)


func start_charge(player: Node2D) -> void:
	charge_direction = global_position.direction_to(player.global_position)
	if charge_direction == Vector2.ZERO:
		charge_direction = Vector2.RIGHT
	distance_left = CHARGE_DISTANCE
	hit_player = false
	warning_time = WARNING_DURATION
	velocity = Vector2.ZERO
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var warning := ChargeWarning.new(charge_direction)
		foreground.add_child(warning)
		warning.global_position = global_position


func charge(delta: float) -> void:
	var previous := global_position
	velocity = charge_direction * CHARGE_SPEED
	move_and_slide()
	distance_left -= previous.distance_to(global_position)
	trail_time -= delta
	if trail_time <= 0.0:
		spawn_ice_trail()
		trail_time = 0.09
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not hit_player and player != null and global_position.distance_squared_to(player.global_position) <= 30.0 * 30.0:
		hit_player = true
		var health := player.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.damage(42.0, "霜甲野猪")
		var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
		if movement != null:
			movement.apply_knockback(charge_direction, 320.0, 0.25)
	if distance_left <= 0.0 or is_on_wall():
		charging = false
		collision_mask = normal_mask
		velocity = Vector2.ZERO
		cooldown = 3.4


func spawn_ice_trail() -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var patch := IceTrail.new()
		foreground.add_child(patch)
		patch.global_position = global_position


func show_frame(frame: int) -> void:
	var column := frame % 4
	var row := floori(frame / 4.0)
	sprite.region_rect = Rect2(FRAME_COLUMNS[column], FRAME_ROWS[row], FRAME_COLUMNS[column + 1] - FRAME_COLUMNS[column], FRAME_ROWS[row + 1] - FRAME_ROWS[row])
	if velocity.x != 0.0:
		$Visuals.scale.x = absf($Visuals.scale.x) * sign(velocity.x)


func update_health_bar() -> void:
	$HealthBar.value = health_component.get_health_percent()
