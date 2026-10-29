extends Node2D
class_name SwordRainAbility


const DURATION := 5.0
const DAMAGE_INTERVAL := 0.5
const DAMAGE_RADIUS := 46.0
const SWORD_VISUAL_SCALE := 0.045
const CIRCLE_VISUAL_SCALE := 0.07
const CIRCLE_START_TIME := 0.5

@onready var circle_sprite: Sprite2D = $CircleSprite
@onready var falling_swords: Array[Sprite2D] = [$FallingSwords/Sword1, $FallingSwords/Sword2, $FallingSwords/Sword3, $FallingSwords/Sword4, $FallingSwords/Sword5]

var damage := 4.0
var duration := DURATION
var radius_multiplier := 1.0
var elapsed := 0.0
var damage_time_left := 0.0
var range_ring: Line2D


func _ready() -> void:
	range_ring = Line2D.new()
	range_ring.name = "RangeRing"
	range_ring.top_level = true
	range_ring.z_as_relative = false
	range_ring.z_index = -1
	range_ring.closed = true
	range_ring.width = 1.5
	range_ring.default_color = Color(0.58, 0.85, 1.0, 0.7)
	for index in 48:
		range_ring.add_point(Vector2.RIGHT.rotated(TAU * index / 48.0) * get_damage_radius())
	add_child(range_ring)
	range_ring.global_position = global_position
	circle_sprite.visible = false
	circle_sprite.scale = Vector2.ONE * CIRCLE_VISUAL_SCALE * 0.3
	for sword: Sprite2D in falling_swords:
		sword.visible = false
		sword.scale = Vector2.ONE * SWORD_VISUAL_SCALE


func _process(delta: float) -> void:
	range_ring.global_position = global_position
	elapsed += delta
	damage_time_left -= delta
	if damage_time_left <= 0.0:
		deal_damage()
		damage_time_left = DAMAGE_INTERVAL
	animate_falling_swords()
	animate_circle()
	queue_redraw()
	modulate.a = minf(elapsed * 2.5, 1.0) * clampf((duration - elapsed) / 0.7, 0.0, 1.0)
	if elapsed >= duration:
		queue_free()


func _draw() -> void:
	for sword: Sprite2D in falling_swords:
		if not sword.visible:
			continue
		var point := sword.position
		draw_line(point + Vector2.UP * 15.0, point, Color(0.65, 0.88, 1.0, 0.45), 2.0, true)
		if point.y > -4.0:
			var alpha := clampf((point.y + 4.0) / 12.0, 0.0, 1.0)
			draw_arc(Vector2(point.x, 8.0), 4.0 + alpha * 6.0, PI, TAU, 12, Color(0.8, 0.96, 1.0, 1.0 - alpha), 1.5, true)


func get_damage_radius() -> float:
	return DAMAGE_RADIUS * radius_multiplier


func animate_falling_swords() -> void:
	for index: int in falling_swords.size():
		var start_time: float = index * 0.07
		var fall_duration: float = 0.45 + index * 0.09
		var fall_time: float = maxf(elapsed - start_time, 0.0)
		var progress: float = fmod(fall_time, fall_duration) / fall_duration
		var sword: Sprite2D = falling_swords[index]
		sword.visible = elapsed >= start_time
		sword.position.y = lerpf(-72.0, 8.0, progress)
		sword.scale = Vector2.ONE * SWORD_VISUAL_SCALE * (0.82 + progress * 0.18)


func animate_circle() -> void:
	var growth: float = clampf((elapsed - CIRCLE_START_TIME) / 0.4, 0.0, 1.0)
	circle_sprite.visible = growth > 0.0
	var pulse: float = sin(maxf(elapsed - CIRCLE_START_TIME, 0.0) * TAU * 1.5) * 0.05
	circle_sprite.scale = Vector2.ONE * CIRCLE_VISUAL_SCALE * (0.3 + growth * 0.75 + pulse)


func deal_damage() -> void:
	for enemy_value: Variant in get_tree().get_nodes_in_group("enemy"):
		var enemy: Node2D = enemy_value as Node2D
		var effective_radius := get_damage_radius()
		if enemy == null or global_position.distance_squared_to(enemy.global_position) > effective_radius * effective_radius:
			continue
		var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		var damage_amount: float = float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount, "", global_position, "direct", "sword")
		GameEvents.record_weapon_damage("sword", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
