extends Node2D
class_name LightningCloudAbility

const DURATION := 5.0
const HOVER_HEIGHT := 64.0
const DAMAGE_MULTIPLIER := 1.5
const STRIKE_FLASH_DURATION := 0.12

@export var damage := 12.0

@onready var bolt: Line2D = $Bolt

var time_left := DURATION
var strike_flash_time_left := 0.0


func _ready() -> void:
	$Timer.timeout.connect(strike)


func _physics_process(delta: float) -> void:
	time_left -= delta
	strike_flash_time_left -= delta
	bolt.visible = strike_flash_time_left > 0
	if time_left <= 0:
		queue_free()


func strike() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return
	var target := enemies.pick_random() as Node2D
	var hurtbox := target.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null or hurtbox.health_component == null:
		return
	global_position = target.global_position + Vector2.UP * HOVER_HEIGHT
	bolt.points = PackedVector2Array([Vector2.ZERO, to_local(target.global_position)])
	strike_flash_time_left = STRIKE_FLASH_DURATION
	var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
	hurtbox.health_component.damage(critical_hit["damage"])
	GameEvents.record_weapon_damage("lightning_whip", critical_hit["damage"])
	GameEvents.heal_from_damage(critical_hit["damage"])
	hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
	hurtbox.hit.emit()
