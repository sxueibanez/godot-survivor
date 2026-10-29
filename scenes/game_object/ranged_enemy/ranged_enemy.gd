extends CharacterBody2D

const PREFERRED_DISTANCE := 165.0
const FIRE_INTERVAL := 2.4
const PROJECTILE_COUNT := 3
const AIM_DURATION := 0.6
const AIM_LENGTH := 205.0

var projectile_scene := preload("res://scenes/game_object/arcane_projectile/arcane_projectile.tscn")

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_bar: ProgressBar = $HealthBar

var cooldown := 1.0
var aim_time := 0.0
var aim_direction := Vector2.ZERO


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _draw() -> void:
	if aim_time <= 0.0:
		return
	var opacity := lerpf(0.25, 0.8, 1.0 - aim_time / AIM_DURATION)
	for i in PROJECTILE_COUNT:
		var direction := aim_direction.rotated((i - 1) * 0.16)
		draw_line(direction * 12.0, direction * AIM_LENGTH, Color(0.75, 0.45, 1.0, opacity), 1.5)


func _process(delta: float) -> void:
	if aim_time > 0.0:
		aim_time = maxf(aim_time - delta, 0.0)
		queue_redraw()
		if aim_time == 0.0:
			fire(aim_direction)
			cooldown = FIRE_INTERVAL
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance > PREFERRED_DISTANCE + 20.0:
		velocity_component.accelerate_in_direction(to_player.normalized())
	elif distance < PREFERRED_DISTANCE - 20.0:
		velocity_component.accelerate_in_direction(-to_player.normalized())
	else:
		velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity_component.move(self)

	cooldown -= delta
	if cooldown <= 0.0 and distance > 0.0 and distance <= PREFERRED_DISTANCE + 45.0:
		aim_direction = to_player.normalized()
		aim_time = AIM_DURATION
		velocity_component.velocity = Vector2.ZERO
		queue_redraw()


func fire(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("enemy_projectiles_layer") as Node2D
	if foreground == null:
		return
	for i in PROJECTILE_COUNT:
		var projectile := projectile_scene.instantiate() as Node2D
		projectile.set("direction", direction.rotated((i - 1) * 0.16))
		projectile.set("damage_multiplier", float(get_meta("damage_multiplier", 1.0)))
		foreground.add_child(projectile)
		projectile.global_position = global_position


func update_health_bar() -> void:
	health_bar.value = health_component.get_health_percent()
