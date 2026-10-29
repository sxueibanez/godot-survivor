extends Node2D
class_name SwordAbility

const CHAIN_CHANCE := 0.3
const MAX_CHAIN_DEPTH := 2
const CHAIN_DAMAGE_MULTIPLIER := 0.25
const CHAIN_TARGET_RANGE := 100.0

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var launch_sound: AudioStreamPlayer2D = $LaunchSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

var damage := 5.0
var chain_enabled := false
var chain_depth := 0
var root_damage := 0.0
var sword_scene: PackedScene = preload("res://scenes/ability/sword_ability/sword_ability.tscn")


func _ready() -> void:
	if root_damage <= 0.0:
		root_damage = damage
	hitbox_component.damage = damage
	hitbox_component.weapon_id = "sword"
	hitbox_component.area_entered.connect(on_hitbox_area_entered)
	launch_sound.play()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var time: float = $AnimationPlayer.current_animation_position
	if time < 0.17 or time > 0.48:
		return
	var progress := (time - 0.17) / 0.31
	var alpha := sin(progress * PI)
	var radius := 18.0 + progress * 5.0
	draw_arc(Vector2(8, 0), radius, -1.15, 1.15, 24, Color(0.34, 0.75, 1.0, alpha * 0.5), 5.0, true)
	draw_arc(Vector2(8, 0), radius, -1.15, 1.15, 24, Color(0.9, 0.98, 1.0, alpha), 1.5, true)


func on_hitbox_area_entered(other_area: Area2D) -> void:
	var target: Node2D = other_area.get_parent() as Node2D
	if other_area is HurtboxComponent and target != null:
		hit_sound.play()
		GameEvents.sword_hit_target.emit(target)
	if not chain_enabled or chain_depth >= MAX_CHAIN_DEPTH or not other_area is HurtboxComponent or randf() > CHAIN_CHANCE:
		return
	var foreground: Node2D = get_tree().get_first_node_in_group("player_projectiles_layer") as Node2D
	if target == null or foreground == null:
		return
	var next_target := find_chain_target(target)
	if next_target == null:
		return
	var next_sword := sword_scene.instantiate() as SwordAbility
	next_sword.damage = root_damage * CHAIN_DAMAGE_MULTIPLIER
	next_sword.chain_enabled = true
	next_sword.chain_depth = chain_depth + 1
	next_sword.root_damage = root_damage
	next_sword.global_position = next_target.global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * 4.0
	next_sword.rotation = (next_target.global_position - next_sword.global_position).angle()
	if has_meta("attack_cooldown"):
		get_meta("attack_cooldown").track(next_sword)
	foreground.add_child.call_deferred(next_sword)


func find_chain_target(previous_target: Node2D) -> Node2D:
	if not is_instance_valid(previous_target):
		return null
	var closest: Node2D
	var closest_distance := CHAIN_TARGET_RANGE * CHAIN_TARGET_RANGE
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if enemy == previous_target or enemy.is_queued_for_deletion():
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
			continue
		var distance := previous_target.global_position.distance_squared_to(enemy.global_position)
		if distance <= closest_distance:
			closest = enemy
			closest_distance = distance
	if closest != null:
		return closest
	var previous_hurtbox := previous_target.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if not previous_target.is_queued_for_deletion() and previous_hurtbox != null and previous_hurtbox.health_component != null and previous_hurtbox.health_component.current_health > 0.0:
		return previous_target
	return null
