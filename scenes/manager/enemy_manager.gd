extends Node

# 10px outside
const SPAWN_RADIUS = 375
const ENDLESS_ENEMY_HEALTH_MULTIPLIER := 0.5

@export var basic_enemy_scene: PackedScene
@export var wizard_enemy_scene: PackedScene
@export var exploder_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var cyclops_bat_scene: PackedScene
@export var iron_golem_scene: PackedScene
@export var stone_slime_scene: PackedScene
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

	var spawn_count := get_endless_spawn_count(arena_time_manager.arena_difficulty) if GameEvents.is_endless_mode() else 1
	for _index in spawn_count:
		var enemy_scene = enemy_table.pick_item()
		var enemy = enemy_scene.instantiate() as Node2D
		apply_difficulty(enemy)

		var entities_layer = get_tree().get_first_node_in_group("entities_layer")
		entities_layer.add_child(enemy)
		enemy.global_position = get_spawn_position()


func get_endless_spawn_count(difficulty: int) -> int:
	return 1 + floori(float(difficulty) / 12.0)


func get_endless_boss_health_multiplier(difficulty: int) -> float:
	return 0.25 + difficulty * 0.015


func spawn_test_enemies(count: int = 20) -> void:
	var entities_layer := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities_layer == null:
		return
	var enemy_scenes: Array[PackedScene] = [basic_enemy_scene, wizard_enemy_scene, exploder_enemy_scene, ranged_enemy_scene, cyclops_bat_scene, iron_golem_scene, stone_slime_scene]
	for _index in count:
		var enemy := enemy_scenes.pick_random().instantiate() as Node2D
		apply_difficulty(enemy)
		entities_layer.add_child(enemy)
		enemy.global_position = get_spawn_position()


func apply_difficulty(enemy: Node2D) -> void:
	var health = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		var level_health_multiplier := 1.6 if level == 2 else 1.0
		var mode_health_multiplier := ENDLESS_ENEMY_HEALTH_MULTIPLIER if GameEvents.is_endless_mode() else 1.0
		health.max_health *= mode_health_multiplier * level_health_multiplier * (1.0 + arena_time_manager.arena_difficulty * 0.05)

	var velocity = enemy.get_node_or_null("VelocityComponent") as VelocityComponent
	if velocity != null:
		velocity.max_speed = roundi(velocity.max_speed * (1.0 + arena_time_manager.arena_difficulty * 0.015))


func apply_endless_boss_difficulty(boss: Node2D) -> void:
	var difficulty: int = arena_time_manager.arena_difficulty
	var health := boss.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.max_health *= get_endless_boss_health_multiplier(difficulty)
	var velocity := boss.get_node_or_null("VelocityComponent") as VelocityComponent
	if velocity != null:
		velocity.max_speed = roundi(velocity.max_speed * (1.0 + difficulty * 0.01))


func on_arena_difficulty_increased(arena_difficulty: int):
	timer.wait_time = max(0.25, base_spawn_time / (1.0 + arena_difficulty * 0.025))
	
	if arena_difficulty == 6 and not GameEvents.is_endless_mode():
		enemy_table.add_item(wizard_enemy_scene, 20)


func stop_spawning() -> void:
	spawning = false
	timer.stop()


func resume_spawning() -> void:
	spawning = true
	timer.start()


func start_endless() -> void:
	spawning = true
	enemy_table = WeightedTable.new()
	var enemy_scenes: Array[PackedScene] = [basic_enemy_scene, wizard_enemy_scene, exploder_enemy_scene, ranged_enemy_scene, cyclops_bat_scene, iron_golem_scene, stone_slime_scene]
	for enemy_scene: PackedScene in enemy_scenes:
		enemy_table.add_item(enemy_scene, 10)
	base_spawn_time = 0.7
	timer.wait_time = base_spawn_time
	timer.start()


func start_level_1() -> void:
	level = 1
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(basic_enemy_scene, 10)
	timer.wait_time = base_spawn_time
	timer.start()


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


func start_level_3() -> void:
	level = 3
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(basic_enemy_scene, 6)
	enemy_table.add_item(wizard_enemy_scene, 5)
	enemy_table.add_item(exploder_enemy_scene, 5)
	enemy_table.add_item(ranged_enemy_scene, 5)
	enemy_table.add_item(cyclops_bat_scene, 12)
	enemy_table.add_item(iron_golem_scene, 4)
	enemy_table.add_item(stone_slime_scene, 6)
	base_spawn_time = 0.65
	timer.wait_time = base_spawn_time
	timer.start()
