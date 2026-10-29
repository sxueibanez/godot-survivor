extends CharacterBody2D


const PREFERRED_DISTANCE := 175.0
const FIRE_INTERVAL := 2.1
const AIM_DURATION := 0.6
const AIM_LOCK_TIME := 0.2
const AIM_LENGTH := 240.0
const LASER_ORIGIN := Vector2(0, -9)

var laser_scene := preload("res://scenes/game_object/cyclops_laser/cyclops_laser.tscn")

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_bar: ProgressBar = $HealthBar

var cooldown := 0.8
var aim_time := 0.0
var aim_direction := Vector2.ZERO


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _draw() -> void:
	if aim_time <= 0.0:
		return
	var progress := 1.0 - aim_time / AIM_DURATION
	var color := Color(1.0, 0.16, 0.2, lerpf(0.35, 0.9, progress))
	draw_line(LASER_ORIGIN, LASER_ORIGIN + aim_direction * AIM_LENGTH, color, 1.5)
	draw_circle(LASER_ORIGIN, lerpf(2.0, 5.0, progress), color)


func _process(delta: float) -> void:
	if health_component.current_health <= 0.0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		if aim_time > 0.0:
			aim_time = 0.0
			queue_redraw()
		return
	if aim_time > 0.0:
		if aim_time > AIM_LOCK_TIME:
			var target_direction := (player.global_position - (global_position + LASER_ORIGIN)).normalized()
			if target_direction != Vector2.ZERO:
				aim_direction = target_direction
		aim_time = maxf(aim_time - delta, 0.0)
		queue_redraw()
		if aim_time == 0.0:
			fire(aim_direction)
			cooldown = FIRE_INTERVAL
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	velocity_component.accelerate_in_direction(to_player.normalized() if distance > PREFERRED_DISTANCE else -to_player.normalized() if distance < PREFERRED_DISTANCE - 30.0 else Vector2.ZERO)
	velocity_component.move(self)
	cooldown -= delta
	if cooldown <= 0.0 and distance > 0.0 and distance <= PREFERRED_DISTANCE + 50.0:
		aim_direction = (player.global_position - (global_position + LASER_ORIGIN)).normalized()
		if aim_direction == Vector2.ZERO:
			return
		aim_time = AIM_DURATION
		velocity = Vector2.ZERO
		velocity_component.velocity = Vector2.ZERO
		queue_redraw()


func fire(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("enemy_projectiles_layer") as Node2D
	if foreground == null:
		return
	var laser := laser_scene.instantiate() as Node2D
	laser.set("direction", direction)
	laser.set("damage_multiplier", float(get_meta("damage_multiplier", 1.0)))
	foreground.add_child(laser)
	laser.global_position = global_position + LASER_ORIGIN


func update_health_bar() -> void:
	health_bar.value = health_component.get_health_percent()
