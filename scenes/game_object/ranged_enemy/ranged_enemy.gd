extends CharacterBody2D

const PREFERRED_DISTANCE := 165.0
const FIRE_INTERVAL := 2.4
const PROJECTILE_COUNT := 3

var projectile_scene := preload("res://scenes/game_object/arcane_projectile/arcane_projectile.tscn")

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_bar: ProgressBar = $HealthBar

var cooldown := 1.0


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
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
	if cooldown <= 0.0 and distance <= PREFERRED_DISTANCE + 45.0:
		fire(to_player.normalized())
		cooldown = FIRE_INTERVAL


func fire(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	for i in PROJECTILE_COUNT:
		var projectile := projectile_scene.instantiate() as Node2D
		projectile.set("direction", direction.rotated((i - 1) * 0.16))
		foreground.add_child(projectile)
		projectile.global_position = global_position


func update_health_bar() -> void:
	health_bar.value = health_component.get_health_percent()
