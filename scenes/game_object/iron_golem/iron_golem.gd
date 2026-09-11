extends CharacterBody2D


const ATTACK_RANGE := 62.0
const ATTACK_DAMAGE := 38.0
const WINDUP_DURATION := 0.8
const ATTACK_COOLDOWN := 2.8
const FRAME_RATE := 10.0
const RUN_FRAME_EDGES := [0, 254, 502, 771, 1040, 1305, 1581, 1851, 2170]
const RUN_FRAME_ANCHORS := [131, 402, 661, 928, 1200, 1472, 1742, 2023]
const ATTACK_FRAME_EDGES := [0, 235, 454, 693, 960, 1259, 1493, 1698, 1923, 2172]
const ATTACK_FRAME_ANCHORS := [122, 360, 600, 870, 1155, 1373, 1595, 1800, 2055]

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var run_texture := preload("res://assets/enemies/iron_golem_run.png")
var attack_texture := preload("res://assets/enemies/iron_golem_attack.png")
var animation_time := 0.0
var attack_time := 0.0
var cooldown := 0.0
var attacking := false
var attack_center := Vector2.ZERO


class GroundWarning extends Node2D:
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= WINDUP_DURATION:
			queue_free()

	func _draw() -> void:
		var progress := minf(elapsed / WINDUP_DURATION, 1.0)
		draw_circle(Vector2.ZERO, ATTACK_RANGE, Color(0.55, 0.0, 0.0, 0.16))
		draw_circle(Vector2.ZERO, ATTACK_RANGE * progress, Color(1.0, 0.05, 0.05, 0.34))
		draw_arc(Vector2.ZERO, ATTACK_RANGE, 0.0, TAU, 40, Color(1.0, 0.1, 0.1, 0.9), 2.0)


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)
	show_frame(run_texture, 0, RUN_FRAME_EDGES, RUN_FRAME_ANCHORS)


func _process(delta: float) -> void:
	if attacking:
		attack_time += delta
		show_frame(attack_texture, mini(int(attack_time / WINDUP_DURATION * ATTACK_FRAME_ANCHORS.size()), ATTACK_FRAME_ANCHORS.size() - 1), ATTACK_FRAME_EDGES, ATTACK_FRAME_ANCHORS)
		if attack_time >= WINDUP_DURATION:
			slam()
		return

	cooldown -= delta
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	animation_time += delta
	show_frame(run_texture, int(animation_time * FRAME_RATE) % RUN_FRAME_ANCHORS.size(), RUN_FRAME_EDGES, RUN_FRAME_ANCHORS)
	if velocity.x != 0.0:
		visuals.scale.x = -absf(visuals.scale.x) * sign(velocity.x)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if cooldown <= 0.0 and player != null and global_position.distance_to(player.global_position) <= ATTACK_RANGE:
		start_attack()


func start_attack() -> void:
	attacking = true
	attack_time = 0.0
	attack_center = global_position
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity = Vector2.ZERO
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var warning := GroundWarning.new()
		foreground.add_child(warning)
		warning.global_position = attack_center


func slam() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.global_position.distance_to(attack_center) <= ATTACK_RANGE:
		var player_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if player_health != null:
			player_health.damage(ATTACK_DAMAGE, "铁魔像")
	attacking = false
	cooldown = ATTACK_COOLDOWN
	animation_time = 0.0


func show_frame(texture: Texture2D, frame: int, edges: Array, anchors: Array) -> void:
	sprite.texture = texture
	var frame_width: int = edges[frame + 1] - edges[frame]
	sprite.region_rect = Rect2(edges[frame], 0.0, frame_width, texture.get_height())
	sprite.position.x = (edges[frame] + frame_width * 0.5 - anchors[frame]) * sprite.scale.x


func update_health_bar() -> void:
	$HealthBar.value = health_component.get_health_percent()
