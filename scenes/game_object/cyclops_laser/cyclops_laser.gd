extends Node2D


const SPEED := 230.0
const DAMAGE := 20.0

var direction := Vector2.RIGHT
var time_left := 3.0


func _ready() -> void:
	rotation = direction.angle()


func _process(delta: float) -> void:
	global_position += direction * SPEED * delta
	time_left -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_squared_to(player.global_position) < 12.0 * 12.0:
		var health := player.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.damage(DAMAGE)
		queue_free()
	elif time_left <= 0.0:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-15, 0), Vector2(6, 0), Color("ff344a"), 4.0)
	draw_circle(Vector2(6, 0), 5.0, Color("ff8790"))
	draw_circle(Vector2(6, 0), 2.0, Color.WHITE)
