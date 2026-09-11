extends Node2D
class_name BombBurn

const TICK_COUNT := 5
const FRAME_COUNT := 8
const FRAME_DURATION := 0.1

@onready var flame: Sprite2D = $Flame

var damage := 0.0
var ticks_left := TICK_COUNT
var animation_time := 0.0
var weapon_id := "bomb"


func _ready() -> void:
	$Timer.timeout.connect(tick)


func _process(delta: float) -> void:
	animation_time += delta
	flame.frame = floori(animation_time / FRAME_DURATION) % FRAME_COUNT


func refresh(new_damage: float) -> void:
	damage = maxf(damage, new_damage)
	ticks_left = TICK_COUNT
	$Timer.start()


func tick() -> void:
	var enemy := get_parent() as Node2D
	var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
		queue_free()
		return
	var damage_amount: float = damage * GameEvents.player_damage_multiplier
	hurtbox.health_component.damage(damage_amount)
	GameEvents.record_weapon_damage(weapon_id, damage_amount)
	GameEvents.heal_from_damage(damage_amount)
	hurtbox.show_damage(damage_amount)
	hurtbox.hit.emit()
	ticks_left -= 1
	if ticks_left <= 0:
		queue_free()
