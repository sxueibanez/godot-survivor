extends Node2D
class_name AzureDragonAbility

enum State { IDLE, WINDUP, DASH }

const ORBIT_RADIUS := 52.0
const ORBIT_SPEED := 0.75
const FOLLOW_SPEED := 4.0
const WINDUP_DURATION := 0.4
const DASH_DURATION := 0.45
const DASH_DISTANCE := 220.0
const HIT_RADIUS := 12.0
const BASE_SPRITE_SCALE := 0.065
const IDLE_FRAME_DURATION := 0.18

@onready var dragon_sprite: Sprite2D = $DragonSprite

var player: Node2D
var state := State.IDLE
var damage := 20.0
var size_multiplier := 1.0
var orbit_angle := 0.0
var state_time := 0.0
var animation_time := 0.0
var dash_origin := Vector2.ZERO
var attack_direction := Vector2.RIGHT
var hit_enemies: Dictionary = {}
var ultimate_active := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		global_position = player.global_position + Vector2.RIGHT * ORBIT_RADIUS
	refresh_visual_size()


func configure(new_damage: float, new_size_multiplier: float) -> void:
	damage = new_damage
	size_multiplier = new_size_multiplier
	if is_node_ready():
		refresh_visual_size()


func _process(delta: float) -> void:
	if ultimate_active:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	match state:
		State.IDLE:
			process_idle(delta)
		State.WINDUP:
			process_windup(delta)
		State.DASH:
			process_dash(delta)


func process_idle(delta: float) -> void:
	orbit_angle += ORBIT_SPEED * delta
	animation_time += delta
	dragon_sprite.frame = floori(animation_time / IDLE_FRAME_DURATION) % 3
	rotation = 0.0
	var orbit_target := player.global_position + Vector2.RIGHT.rotated(orbit_angle) * ORBIT_RADIUS
	global_position = global_position.lerp(orbit_target, minf(FOLLOW_SPEED * delta, 1.0))


func start_attack(target_position: Vector2) -> bool:
	if state != State.IDLE or target_position.is_equal_approx(global_position):
		return false
	state = State.WINDUP
	state_time = 0.0
	dash_origin = global_position
	attack_direction = global_position.direction_to(target_position)
	rotation = attack_direction.angle()
	return true


func process_windup(delta: float) -> void:
	state_time += delta
	var progress := minf(state_time / WINDUP_DURATION, 1.0)
	dragon_sprite.frame = 3 + mini(floori(progress * 3.0), 2)
	global_position = dash_origin - attack_direction * 12.0 * progress
	if progress >= 1.0:
		state = State.DASH
		state_time = 0.0
		dash_origin = global_position
		hit_enemies.clear()


func process_dash(delta: float) -> void:
	state_time += delta
	var progress := minf(state_time / DASH_DURATION, 1.0)
	dragon_sprite.frame = 6 + mini(floori(progress * 3.0), 2)
	global_position = dash_origin + attack_direction * DASH_DISTANCE * ease(progress, 2.0)
	damage_enemies()
	if progress >= 1.0:
		state = State.IDLE
		state_time = 0.0
		animation_time = 0.0


func damage_enemies() -> void:
	var radius := HIT_RADIUS * size_multiplier
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var enemy_id := enemy.get_instance_id()
		if hit_enemies.has(enemy_id) or global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("azure_dragon", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
		hit_enemies[enemy_id] = true


func refresh_visual_size() -> void:
	dragon_sprite.scale = Vector2.ONE * BASE_SPRITE_SCALE * size_multiplier


func set_ultimate_active(active: bool) -> void:
	ultimate_active = active
	if active:
		state = State.IDLE
