extends Node2D
class_name VermilionBirdAbility

const ORBIT_RADIUS := 70.0
const ORBIT_SPEED := 1.2
const FIREBALL_COUNT := 3
const SPREAD_ANGLE := 10.0
const FRAME_DURATION := 0.09
const BASE_VISUAL_SCALE := 0.08

@export var fireball_scene: PackedScene

var player: Node2D
var damage := 20.0
var size_multiplier := 1.0
var attack_interval_multiplier := 1.0
var orbit_angle := PI
var animation_time := 0.0
var ultimate_active := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	$AttackTimer.timeout.connect(fire_fireballs)
	refresh_stats()


func configure(weapon_damage: float, weapon_size: float = 1.0, attack_interval_multiplier: float = 1.0) -> void:
	damage = weapon_damage
	size_multiplier = weapon_size
	self.attack_interval_multiplier = attack_interval_multiplier
	if is_node_ready():
		refresh_stats()


func refresh_stats() -> void:
	$Sprite2D.scale = Vector2.ONE * BASE_VISUAL_SCALE * size_multiplier
	$AttackTimer.wait_time = maxf(0.1, attack_interval_multiplier)


func _process(delta: float) -> void:
	if ultimate_active or not is_instance_valid(player):
		return
	orbit_angle += ORBIT_SPEED * delta
	animation_time += delta
	$Sprite2D.frame = floori(animation_time / FRAME_DURATION) % 9
	global_position = player.global_position + Vector2.RIGHT.rotated(orbit_angle) * ORBIT_RADIUS
	$Sprite2D.flip_h = cos(orbit_angle) < 0.0


func fire_fireballs() -> void:
	if ultimate_active or not is_instance_valid(player):
		return
	var target := AzureDragonController.find_nearest_enemy(get_tree().get_nodes_in_group("enemy"), player.global_position)
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if target == null or foreground == null:
		return
	var base_direction := global_position.direction_to(target.global_position)
	for index in FIREBALL_COUNT:
		var fireball := fireball_scene.instantiate() as VermilionFireball
		var offset := index - (FIREBALL_COUNT - 1) * 0.5
		fireball.configure(global_position, base_direction.rotated(deg_to_rad(offset * SPREAD_ANGLE)), damage, size_multiplier)
		foreground.add_child(fireball)


func set_ultimate_active(active: bool) -> void:
	ultimate_active = active
	$AttackTimer.paused = active
