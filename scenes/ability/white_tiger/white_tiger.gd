extends Node2D
class_name WhiteTigerAbility

const ORBIT_RADIUS := 62.0
const ORBIT_SPEED := 1.8
const FRAME_SIZE := Vector2(512, 341)
const FRAME_DURATION := 0.08
const BASE_VISUAL_SCALE := 0.075

@export var tornado_scene: PackedScene

var player: Node2D
var damage := 20.0
var size_multiplier := 1.0
var attack_interval_multiplier := 1.0
var orbit_angle := 0.0
var animation_time := 0.0
var ultimate_active := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	$AttackTimer.timeout.connect(release_tornado)
	refresh_stats()


func configure(weapon_damage: float, weapon_size: float = 1.0, attack_interval_multiplier: float = 1.0) -> void:
	damage = weapon_damage
	size_multiplier = weapon_size
	self.attack_interval_multiplier = attack_interval_multiplier
	if is_node_ready():
		refresh_stats()


func refresh_stats() -> void:
	$Sprite2D.scale = Vector2.ONE * BASE_VISUAL_SCALE * size_multiplier
	$AttackTimer.wait_time = maxf(0.1, 5.0 * attack_interval_multiplier)


func _process(delta: float) -> void:
	if ultimate_active or not is_instance_valid(player):
		return
	orbit_angle += ORBIT_SPEED * delta
	animation_time += delta
	var frame := floori(animation_time / FRAME_DURATION) % 9
	$Sprite2D.region_rect = Rect2(Vector2(frame % 3, floori(frame / 3.0)) * FRAME_SIZE, FRAME_SIZE)
	global_position = player.global_position + Vector2.RIGHT.rotated(orbit_angle) * ORBIT_RADIUS
	$Sprite2D.flip_h = cos(orbit_angle) < 0.0


func release_tornado() -> void:
	if ultimate_active or not is_instance_valid(player):
		return
	var target := AzureDragonController.find_nearest_enemy(get_tree().get_nodes_in_group("enemy"), player.global_position)
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if target == null or foreground == null:
		return
	var tornado := tornado_scene.instantiate() as SacredTornado
	tornado.configure(global_position, global_position.direction_to(target.global_position), damage, size_multiplier)
	foreground.add_child(tornado)


func set_ultimate_active(active: bool) -> void:
	ultimate_active = active
	$AttackTimer.paused = active
