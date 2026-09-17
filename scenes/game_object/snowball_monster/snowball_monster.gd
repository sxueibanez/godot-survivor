extends CharacterBody2D

const FRAME_COLUMNS := [0, 444, 887, 1331, 1774]
const FRAME_ROWS := [0, 444, 887]

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var animation_time := 0.0
var growth := 0.0
var can_split := true


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	animation_time += delta
	growth = minf(growth + delta * 0.055, 0.45)
	$Visuals.scale = Vector2.ONE * (1.0 + growth)
	show_frame(int(animation_time * 10.0) % 8)
	if can_split and growth >= 0.2 and is_on_wall():
		split()


func split() -> void:
	if not GameEvents.can_spawn_enemy():
		return
	var entities := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities != null:
		for index in 3:
			if not GameEvents.can_spawn_enemy():
				break
			var child := duplicate() as CharacterBody2D
			entities.add_child(child)
			child.global_position = global_position + Vector2.RIGHT.rotated(index * TAU / 3.0) * 18.0
			child.call("configure_small")
	queue_free()


func configure_small() -> void:
	can_split = false
	growth = -0.35
	health_component.max_health *= 0.35
	health_component.current_health = health_component.max_health
	velocity_component.max_speed = 78


func show_frame(frame: int) -> void:
	var column := frame % 4
	var row := floori(frame / 4.0)
	sprite.region_rect = Rect2(FRAME_COLUMNS[column], FRAME_ROWS[row], FRAME_COLUMNS[column + 1] - FRAME_COLUMNS[column], FRAME_ROWS[row + 1] - FRAME_ROWS[row])


func update_health_bar() -> void:
	$HealthBar.value = health_component.get_health_percent()
