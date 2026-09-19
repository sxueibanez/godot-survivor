extends CharacterBody2D

const FRAME_COLUMNS := [0, 384, 768, 1152, 1536]
const FRAME_ROWS := [0, 512, 1024]
const PREFERRED_DISTANCE := 170.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var cooldown := 1.0
var animation_time := 0.0


class IceBolt extends Node2D:
	var direction := Vector2.RIGHT
	var time_left := 4.0

	func _process(delta: float) -> void:
		global_position += direction * 185.0 * delta
		time_left -= delta
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and global_position.distance_squared_to(player.global_position) <= 13.0 * 13.0:
			var health := player.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(30.0, "冰晶幽灵")
			var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
			if movement != null:
				movement.apply_slow(0.35, 1.2)
			queue_free()
		elif time_left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7.0, Color(0.25, 0.85, 1.0))
		draw_circle(Vector2.ZERO, 3.5, Color.WHITE)
		draw_line(Vector2(-7, 0), Vector2(-18, 0), Color(0.45, 0.9, 1.0, 0.55), 3.0)


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var offset := player.global_position - global_position
	var distance := offset.length()
	velocity_component.accelerate_in_direction(offset.normalized() if distance > PREFERRED_DISTANCE else -offset.normalized() if distance < 130.0 else Vector2.ZERO)
	velocity_component.move(self)
	cooldown -= delta
	animation_time += delta
	show_frame(int(animation_time * 8.0) % 8)
	if cooldown <= 0.0 and distance <= 240.0:
		fire(offset.normalized())
		cooldown = 2.1


func fire(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("enemy_projectiles_layer") as Node2D
	if foreground == null:
		return
	var bolt := IceBolt.new()
	bolt.direction = Vector2.RIGHT if direction == Vector2.ZERO else direction
	bolt.rotation = bolt.direction.angle()
	foreground.add_child(bolt)
	bolt.global_position = global_position


func show_frame(frame: int) -> void:
	var column := frame % 4
	var row := floori(frame / 4.0)
	sprite.region_rect = Rect2(FRAME_COLUMNS[column], FRAME_ROWS[row], FRAME_COLUMNS[column + 1] - FRAME_COLUMNS[column], FRAME_ROWS[row + 1] - FRAME_ROWS[row])


func update_health_bar() -> void:
	$HealthBar.value = health_component.get_health_percent()
