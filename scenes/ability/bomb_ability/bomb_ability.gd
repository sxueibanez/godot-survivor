extends Node2D
class_name BombAbility

const FLIGHT_DURATION := 0.55
const EXPLOSION_DURATION := 0.48
const EXPLOSION_FRAMES := 16
const CHILD_COUNT := 5
const CHILD_MULTIPLIER := 0.3
const BURN_MULTIPLIER := 0.6
const BOUNCE_TARGET_RANGE := 140.0

@onready var bomb_sprite: Sprite2D = $BombSprite
@onready var explosion_sprite: Sprite2D = $ExplosionSprite
@onready var explosion_sound: AudioStreamPlayer2D = $ExplosionSound
@onready var launch_sound: AudioStreamPlayer2D = $LaunchSound

var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var damage := 15.0
var radius := 30.0
var bounce_remaining := 0
var burn_enabled := false
var cluster_enabled := false
var is_mini := false
var elapsed := 0.0
var exploding := false

var burn_scene := preload("res://scenes/ability/bomb_burn/bomb_burn.tscn")


func configure(from: Vector2, to: Vector2, new_damage: float, new_radius: float, bounces: int, burns: bool, clusters: bool, is_mini: bool = false) -> void:
	start_position = from
	target_position = to
	damage = new_damage
	radius = new_radius
	bounce_remaining = bounces
	burn_enabled = burns
	cluster_enabled = clusters
	self.is_mini = is_mini


func _ready() -> void:
	global_position = start_position
	bomb_sprite.scale = Vector2.ONE * (0.025 if is_mini else 0.04)
	explosion_sprite.scale = Vector2.ONE * radius / 150.0
	explosion_sprite.visible = false
	explosion_sound.volume_db = -12.0 if is_mini else -4.0
	launch_sound.volume_db = -14.0 if is_mini else -8.0
	launch_sound.play()


func _process(delta: float) -> void:
	elapsed += delta
	if exploding:
		explosion_sprite.frame = mini(floori(elapsed / EXPLOSION_DURATION * EXPLOSION_FRAMES), EXPLOSION_FRAMES - 1)
		if elapsed >= EXPLOSION_DURATION:
			queue_free()
		return
	var progress := minf(elapsed / FLIGHT_DURATION, 1.0)
	global_position = start_position.lerp(target_position, progress) + Vector2.UP * sin(progress * PI) * (20.0 if is_mini else 42.0)
	bomb_sprite.rotation += delta * 7.0
	if progress >= 1.0:
		explode()


func explode() -> void:
	if exploding:
		return
	exploding = true
	elapsed = 0.0
	bomb_sprite.visible = false
	explosion_sprite.visible = true
	explosion_sound.play()
	damage_enemies()
	if cluster_enabled:
		spawn_cluster_bombs()
	if bounce_remaining > 0:
		spawn_bounce()


func damage_enemies() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("bomb", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
		if burn_enabled:
			apply_burn(enemy)


func apply_burn(enemy: Node2D) -> void:
	var burn := enemy.get_node_or_null("BombBurn") as BombBurn
	if burn == null:
		burn = burn_scene.instantiate() as BombBurn
		burn.damage = get_burn_damage(damage)
		enemy.add_child(burn)
	else:
		burn.refresh(get_burn_damage(damage))


func spawn_bounce() -> void:
	spawn_bomb(global_position, find_bounce_target(), damage, radius, bounce_remaining - 1, burn_enabled, cluster_enabled)


func spawn_cluster_bombs() -> void:
	var phase := randf_range(0.0, TAU)
	for index in CHILD_COUNT:
		var destination := global_position + Vector2.RIGHT.rotated(phase + TAU * index / CHILD_COUNT) * 55.0
		spawn_bomb(global_position, destination, get_child_damage(damage), radius * CHILD_MULTIPLIER, 0, burn_enabled, false, true)


func spawn_bomb(from: Vector2, to: Vector2, new_damage: float, new_radius: float, bounces: int, burns: bool, clusters: bool, is_mini: bool = false) -> void:
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var bomb := load("res://scenes/ability/bomb_ability/bomb_ability.tscn").instantiate() as BombAbility
	bomb.configure(from, to, new_damage, new_radius, bounces, burns, clusters, is_mini)
	parent.add_child(bomb)


func find_bounce_target() -> Vector2:
	var closest: Node2D
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance > radius * radius and distance <= BOUNCE_TARGET_RANGE * BOUNCE_TARGET_RANGE and (closest == null or distance < global_position.distance_squared_to(closest.global_position)):
			closest = enemy
	return closest.global_position if closest != null else global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * 70.0


static func get_child_damage(weapon_damage: float) -> float:
	return weapon_damage * CHILD_MULTIPLIER


static func get_burn_damage(weapon_damage: float) -> float:
	return weapon_damage * BURN_MULTIPLIER
