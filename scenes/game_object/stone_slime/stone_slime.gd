extends CharacterBody2D


const FRAME_RATE := 8.0
const FRAME_COLUMNS := [0, 328, 631, 933, 1254]
const FRAME_ROWS := [320, 640, 960]
const WARNING_DURATION := 0.55
const AIM_RANGE := 220.0
const CHARGE_SPEED := 280.0
const MAX_CHARGE_DISTANCE := 280.0
const HIT_RADIUS := 30.0
const ENEMY_KNOCKBACK_SPEED := 330.0
const CHARGE_DAMAGE := 32.0
const CHARGE_COOLDOWN := 3.2

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var animation_time := 0.0
var cooldown := 1.0
var warning_time := 0.0
var charge_direction := Vector2.ZERO
var charge_distance := 0.0
var charging := false
var aiming := false
var knocked_enemies := {}
var normal_collision_mask := 0


class ChargeWarning extends Node2D:
	var direction: Vector2
	var distance: float
	var elapsed := 0.0

	func _init(new_direction: Vector2, new_distance: float) -> void:
		direction = new_direction
		distance = new_distance

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= WARNING_DURATION:
			queue_free()

	func _draw() -> void:
		var pulse := 0.45 + sin(elapsed * 24.0) * 0.2
		draw_line(Vector2.ZERO, direction * distance, Color(1.0, 0.08, 0.08, pulse), HIT_RADIUS * 1.5)
		draw_line(Vector2.ZERO, direction * distance, Color(1.0, 0.5, 0.35, 0.9), 2.0)
		draw_circle(direction * distance, HIT_RADIUS, Color(1.0, 0.08, 0.08, pulse * 0.45))


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)
	show_frame(0)


func _process(delta: float) -> void:
	if aiming:
		warning_time -= delta
		if warning_time <= 0.0:
			aiming = false
			charging = true
			normal_collision_mask = collision_mask
			collision_mask = 1
		return

	if charging:
		animate(delta, 3.0)
		var previous_position := global_position
		velocity = charge_direction * CHARGE_SPEED
		move_and_slide()
		charge_distance -= global_position.distance_to(previous_position)
		knockback_enemies()
		if hit_player() or charge_distance <= 0.0 or is_on_wall():
			finish_charge()
		return

	cooldown -= delta
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	animate(delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if cooldown <= 0.0 and player != null and global_position.distance_to(player.global_position) <= AIM_RANGE:
		start_aim(player)


func start_aim(player: Node2D) -> void:
	charge_direction = global_position.direction_to(player.global_position)
	if charge_direction == Vector2.ZERO:
		charge_direction = Vector2.RIGHT
	charge_distance = minf(global_position.distance_to(player.global_position) + 60.0, MAX_CHARGE_DISTANCE)
	knocked_enemies.clear()
	aiming = true
	warning_time = WARNING_DURATION
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity = Vector2.ZERO
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var warning := ChargeWarning.new(charge_direction, charge_distance)
		foreground.add_child(warning)
		warning.global_position = global_position


func hit_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or global_position.distance_to(player.global_position) > HIT_RADIUS:
		return false
	var player_health := player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health != null:
		player_health.damage(CHARGE_DAMAGE)
	var player_velocity := player.get_node_or_null("VelocityComponent") as VelocityComponent
	if player_velocity != null:
		player_velocity.apply_knockback(charge_direction, 280.0, 0.22)
	return true


func knockback_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or knocked_enemies.has(enemy) or not enemy is Node2D:
			continue
		if global_position.distance_to(enemy.global_position) > HIT_RADIUS:
			continue
		var enemy_velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
		if enemy_velocity != null:
			enemy_velocity.apply_knockback(charge_direction, ENEMY_KNOCKBACK_SPEED, 0.25)
			knocked_enemies[enemy] = true


func finish_charge() -> void:
	charging = false
	collision_mask = normal_collision_mask
	cooldown = CHARGE_COOLDOWN
	velocity = Vector2.ZERO
	velocity_component.velocity = Vector2.ZERO


func animate(delta: float, speed_multiplier: float = 1.0) -> void:
	animation_time += delta * speed_multiplier
	show_frame(int(animation_time * FRAME_RATE) % 8)


func show_frame(frame: int) -> void:
	var column := frame % 4
	var row := floori(frame / 4.0)
	sprite.region_rect = Rect2(FRAME_COLUMNS[column], FRAME_ROWS[row], FRAME_COLUMNS[column + 1] - FRAME_COLUMNS[column], FRAME_ROWS[row + 1] - FRAME_ROWS[row])


func update_health_bar() -> void:
	$HealthBar.value = health_component.get_health_percent()
