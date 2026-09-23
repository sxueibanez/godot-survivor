extends Node2D
class_name SwordGreatswordSweep

const DAMAGE_MULTIPLIER := 3.5
const SPEED := 420.0
const FRAME_COUNT := 6
const FRAME_TIME := 0.08
const BASE_SCALE := 0.24
const HIT_HALF_SIZE := Vector2(55.0, 22.0)

@onready var sprite: Sprite2D = $Sprite2D
@onready var launch_sound: AudioStreamPlayer2D = $LaunchSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

var start_position := Vector2.ZERO
var end_x := 0.0
var damage := 17.5
var size_multiplier := 1.0
var elapsed := 0.0
var hit_enemy_ids: Dictionary = {}


func configure(from: Vector2, to_x: float, weapon_damage: float, new_size_multiplier: float) -> void:
	start_position = from
	end_x = to_x
	damage = get_damage(weapon_damage)
	size_multiplier = new_size_multiplier


func _ready() -> void:
	global_position = start_position
	sprite.scale = Vector2.ONE * BASE_SCALE * size_multiplier
	launch_sound.play()


func _process(delta: float) -> void:
	elapsed += delta
	sprite.frame = floori(elapsed / FRAME_TIME) % FRAME_COUNT
	global_position.x -= SPEED * delta
	damage_new_enemies()
	if global_position.x <= end_x:
		queue_free()


func damage_new_enemies() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var enemy_id := enemy.get_instance_id()
		if hit_enemy_ids.has(enemy_id):
			continue
		var local_position := to_local(enemy.global_position)
		if absf(local_position.x) > HIT_HALF_SIZE.x * size_multiplier or absf(local_position.y) > HIT_HALF_SIZE.y * size_multiplier:
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		hit_enemy_ids[enemy_id] = true
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount, "", global_position, "direct", "sword")
		GameEvents.record_weapon_damage("sword", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
		if not hit_sound.playing:
			hit_sound.play()


static func get_damage(weapon_damage: float) -> float:
	return weapon_damage * DAMAGE_MULTIPLIER
