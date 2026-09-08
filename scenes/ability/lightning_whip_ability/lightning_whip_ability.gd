extends Node2D
class_name LightningWhipAbility

const DURATION := 0.4
const RANGE := 50.0
const HALF_ANGLE := PI / 2.0

@export var damage := 8.0
@export var size_multiplier := 1.0
@export var chain_enabled := false
@export var chain_damage := 4.0

var direction := Vector2.RIGHT
var time_left := DURATION
var lightning_chain_scene := preload("res://scenes/ability/lightning_chain_ability/lightning_chain_ability.tscn")


func _ready() -> void:
	rotation = direction.angle()
	scale = Vector2.ONE * size_multiplier
	$Visuals.rotation = -HALF_ANGLE
	create_tween().tween_property($Visuals, "rotation", HALF_ANGLE, DURATION)
	strike()


func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0:
		queue_free()


func strike() -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length_squared() > RANGE * RANGE || abs(direction.angle_to(offset.normalized())) > HALF_ANGLE:
			continue

		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null || hurtbox.health_component == null:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(damage)
		hurtbox.health_component.damage(critical_hit["damage"])
		GameEvents.heal_from_damage(critical_hit["damage"])
		hurtbox.show_damage(critical_hit["damage"], critical_hit["critical"])
		hurtbox.hit.emit()
		var velocity := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
		if velocity != null:
			velocity.apply_slow(0.25, 3.0)
		if chain_enabled && randf() <= 0.5:
			spawn_chain(enemy)


func spawn_chain(source_enemy: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy != source_enemy && enemy.global_position.distance_squared_to(source_enemy.global_position) <= 100 * 100
	)
	if enemies.is_empty():
		return

	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(source_enemy.global_position) < b.global_position.distance_squared_to(source_enemy.global_position)
	)
	var chain := lightning_chain_scene.instantiate() as LightningChainAbility
	chain.source = source_enemy
	chain.target = enemies[0]
	chain.damage = chain_damage
	get_tree().get_first_node_in_group("foreground_layer").add_child(chain)
