extends Node2D
class_name ThunderPlasma

const TICK_COUNT := 3
const FRAME_COUNT := 16
const FRAME_DURATION := 0.1

@onready var plasma_sprite: Sprite2D = $PlasmaSprite

var damage := 3.0
var radius := 55.0
var ticks_left := TICK_COUNT
var animation_time := 0.0


func configure(position: Vector2, tick_damage: float, new_radius: float) -> void:
	global_position = position
	damage = tick_damage
	radius = new_radius


func _ready() -> void:
	plasma_sprite.scale = Vector2.ONE * radius / 128.0
	$Timer.timeout.connect(tick)


func _process(delta: float) -> void:
	animation_time += delta
	plasma_sprite.frame = floori(animation_time / FRAME_DURATION) % FRAME_COUNT


func tick() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		hurtbox.health_component.damage(critical_hit["damage"])
		GameEvents.record_weapon_damage("thunder_orb_book", critical_hit["damage"])
		GameEvents.heal_from_damage(critical_hit["damage"])
		hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
		hurtbox.hit.emit()
	ticks_left -= 1
	if ticks_left <= 0:
		queue_free()
