extends Node2D
class_name SwordAbility

const CHAIN_CHANCE := 0.3
const MAX_CHAIN_DEPTH := 2
const CHAIN_DAMAGE_MULTIPLIER := 0.25

@onready var hitbox_component: HitboxComponent = $HitboxComponent

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


func on_hitbox_area_entered(other_area: Area2D) -> void:
	var target: Node2D = other_area.get_parent() as Node2D
	if other_area is HurtboxComponent and target != null:
		GameEvents.sword_hit_target.emit(target)
	if not chain_enabled or chain_depth >= MAX_CHAIN_DEPTH or not other_area is HurtboxComponent or randf() > CHAIN_CHANCE:
		return
	var foreground: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if target == null or foreground == null:
		return
	var next_sword := sword_scene.instantiate() as SwordAbility
	next_sword.damage = root_damage * CHAIN_DAMAGE_MULTIPLIER
	next_sword.chain_enabled = true
	next_sword.chain_depth = chain_depth + 1
	next_sword.root_damage = root_damage
	next_sword.global_position = target.global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * 4.0
	next_sword.rotation = (target.global_position - next_sword.global_position).angle()
	foreground.add_child.call_deferred(next_sword)
