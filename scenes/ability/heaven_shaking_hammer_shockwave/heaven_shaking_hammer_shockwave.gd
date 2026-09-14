extends Node2D
class_name HeavenShakingHammerShockwave

const DURATION := 0.54
const FRAME_COUNT := 9

@onready var sprite: Sprite2D = $Sprite2D

var damage := 12.0
var radius := 38.5
var delay := 0.0
var elapsed := 0.0
var started := false


func configure(at: Vector2, new_damage: float, new_radius: float, start_delay: float) -> void:
	global_position = at
	damage = new_damage
	radius = new_radius
	delay = start_delay


func _ready() -> void:
	sprite.visible = delay <= 0.0
	sprite.scale = Vector2.ONE * radius / 180.0
	if delay <= 0.0:
		start_wave()


func _process(delta: float) -> void:
	elapsed += delta
	if not started:
		if elapsed < delay:
			return
		start_wave()
	var animation_time := elapsed - delay
	sprite.frame = mini(floori(animation_time / DURATION * FRAME_COUNT), FRAME_COUNT - 1)
	if animation_time >= DURATION:
		queue_free()


func start_wave() -> void:
	started = true
	sprite.visible = true
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_squared_to(enemy.global_position) > radius * radius:
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("heaven_shaking_hammer", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
