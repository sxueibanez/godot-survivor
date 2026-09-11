extends Node2D
class_name VermilionFireball

const SPEED := 220.0
const LIFETIME := 2.0
const HIT_RADIUS := 10.0
const FRAME_SIZE := Vector2(512, 341)
const FRAME_DURATION := 0.07
const BASE_VISUAL_SCALE := 0.045

var burn_scene := preload("res://scenes/ability/bomb_burn/bomb_burn.tscn")
var direction := Vector2.RIGHT
var damage := 5.0
var burn_damage := 2.0
var elapsed := 0.0
var size_multiplier := 1.0


func configure(start: Vector2, travel_direction: Vector2, weapon_damage: float, weapon_size: float = 1.0) -> void:
	global_position = start
	direction = travel_direction.normalized()
	damage = weapon_damage * 0.25
	burn_damage = weapon_damage * 0.1
	size_multiplier = weapon_size
	rotation = direction.angle()


func _ready() -> void:
	$Sprite2D.scale = Vector2.ONE * BASE_VISUAL_SCALE * size_multiplier


func _process(delta: float) -> void:
	elapsed += delta
	global_position += direction * SPEED * delta
	var frame := floori(elapsed / FRAME_DURATION) % 9
	$Sprite2D.region_rect = Rect2(Vector2(frame % 3, floori(frame / 3.0)) * FRAME_SIZE, FRAME_SIZE)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) <= pow(HIT_RADIUS * size_multiplier, 2.0) and hit_enemy(enemy):
			queue_free()
			return
	if elapsed >= LIFETIME:
		queue_free()


func hit_enemy(enemy: Node2D) -> bool:
	var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
		return false
	var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
	var damage_amount := float(critical_hit["damage"])
	hurtbox.health_component.damage(damage_amount)
	GameEvents.record_weapon_damage("azure_dragon", damage_amount)
	GameEvents.heal_from_damage(damage_amount)
	hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
	hurtbox.hit.emit()
	var burn := enemy.get_node_or_null("AzureDragonBurn") as BombBurn
	if burn == null:
		burn = burn_scene.instantiate() as BombBurn
		burn.name = "AzureDragonBurn"
		burn.weapon_id = "azure_dragon"
		burn.damage = burn_damage
		enemy.add_child(burn)
	else:
		burn.refresh(burn_damage)
	return true
