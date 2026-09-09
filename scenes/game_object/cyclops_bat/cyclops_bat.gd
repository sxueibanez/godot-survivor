extends CharacterBody2D


const PREFERRED_DISTANCE := 175.0
const FIRE_INTERVAL := 2.1

var laser_scene := preload("res://scenes/game_object/cyclops_laser/cyclops_laser.tscn")

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_bar: ProgressBar = $HealthBar

var cooldown := 0.8


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	velocity_component.accelerate_in_direction(to_player.normalized() if distance > PREFERRED_DISTANCE else -to_player.normalized() if distance < PREFERRED_DISTANCE - 30.0 else Vector2.ZERO)
	velocity_component.move(self)
	cooldown -= delta
	if cooldown <= 0.0 and distance <= PREFERRED_DISTANCE + 50.0:
		fire(to_player.normalized())
		cooldown = FIRE_INTERVAL


func fire(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var laser := laser_scene.instantiate() as Node2D
	laser.set("direction", direction)
	foreground.add_child(laser)
	laser.global_position = global_position + Vector2(0, -9)


func update_health_bar() -> void:
	health_bar.value = health_component.get_health_percent()
