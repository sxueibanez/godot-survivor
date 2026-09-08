extends Node

# 10px outside
const SPAWN_RADIUS = 375

@export var basic_enemy_scene: PackedScene
@export var wizard_enemy_scene: PackedScene
@export var exploder_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var arena_time_manager: ArenaTimeManager

@onready var timer = $Timer

var base_spawn_time = 0  # sec
var enemy_table = WeightedTable.new()
var level := 1
var spawning := true


func _ready():
	enemy_table.add_item(basic_enemy_scene, 10)
	base_spawn_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)


func get_spawn_position() -> Vector2:
	# Spawn outside of the view
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.ZERO

	var spawn_position: Vector2
	var random_direction := Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
		var additional_check_offset = random_direction * 20  # prevent stuck in a wall

		# raycast check
		var query_parameters = PhysicsRayQueryParameters2D.create(player.global_position, spawn_position + additional_check_offset, 1 << 0)
		var result = get_tree().root.world_2d.direct_space_state.intersect_ray(query_parameters)

		if result.is_empty():
			# no collision - OK
			return spawn_position

		random_direction = random_direction.rotated(deg_to_rad(90))

	return Vector2.ZERO


func on_timer_timeout():
	if not spawning:
		return
	timer.start()

	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var enemy_scene = enemy_table.pick_item()
	var enemy = enemy_scene.instantiate() as Node2D
	apply_difficulty(enemy)
	
	var entities_layer = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.add_child(enemy)
	enemy.global_position = get_spawn_position()


func apply_difficulty(enemy: Node2D) -> void:
	var health = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		var level_health_multiplier := 1.6 if level == 2 else 1.0
		health.max_health *= level_health_multiplier * (1.0 + arena_time_manager.arena_difficulty * 0.05)

	var velocity = enemy.get_node_or_null("VelocityComponent") as VelocityComponent
	if velocity != null:
		velocity.max_speed = roundi(velocity.max_speed * (1.0 + arena_time_manager.arena_difficulty * 0.015))


func on_arena_difficulty_increased(arena_difficulty: int):
	timer.wait_time = max(0.25, base_spawn_time / (1.0 + arena_difficulty * 0.025))
	
	if arena_difficulty == 6:
		enemy_table.add_item(wizard_enemy_scene, 20)


func stop_spawning() -> void:
	spawning = false
	timer.stop()


func start_level_2() -> void:
	level = 2
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(basic_enemy_scene, 8)
	enemy_table.add_item(wizard_enemy_scene, 5)
	enemy_table.add_item(exploder_enemy_scene, 4)
	enemy_table.add_item(ranged_enemy_scene, 5)
	base_spawn_time = 0.7
	timer.wait_time = base_spawn_time
	timer.start()
