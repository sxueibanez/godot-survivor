extends Node

# 10px outside
const SPAWN_RADIUS = 375
const ENDLESS_ENEMY_HEALTH_MULTIPLIER := 0.5
const CINDER := preload("res://scenes/game_object/forge_enemy/cinder.tscn")
const GUARD := preload("res://scenes/game_object/forge_enemy/guard.tscn")
const WORKER := preload("res://scenes/game_object/forge_enemy/worker.tscn")
const EXPERIENCE_VIAL := preload("res://scenes/game_object/experience_vial/experience_vial.tscn")

@export var basic_enemy_scene: PackedScene
@export var wizard_enemy_scene: PackedScene
@export var exploder_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var cyclops_bat_scene: PackedScene
@export var iron_golem_scene: PackedScene
@export var stone_slime_scene: PackedScene
@export var frost_wisp_scene: PackedScene
@export var frost_boar_scene: PackedScene
@export var snowball_monster_scene: PackedScene
@export var arena_time_manager: ArenaTimeManager

@onready var timer = $Timer
@onready var elite_timer: Timer = $EliteTimer

var base_spawn_time = 0  # sec
var enemy_table = WeightedTable.new()
var level := 1
var spawning := true


func _ready():
	enemy_table.add_item(basic_enemy_scene, 10)
	base_spawn_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	elite_timer.timeout.connect(spawn_elite)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)


func get_spawn_position() -> Vector2:
	# Spawn outside of the view
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.ZERO
	var forge: Node = get_tree().get_first_node_in_group("forge_map")
	if forge != null and forge.active:
		return forge.get_spawn_position(player.global_position)

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


func get_boss_spawn_position() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.ZERO
	var forge: Node = get_tree().get_first_node_in_group("forge_map")
	if forge != null and forge.active:
		return forge.safe_position(forge.get_spawn_position(player.global_position, 180.0), 72.0)
	var shape := CircleShape2D.new()
	shape.radius = 40.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	var space := player.get_world_2d().direct_space_state
	var angle := randf() * TAU
	for distance: float in [180.0, 120.0, 80.0, 48.0]:
		for index in 32:
			var candidate := player.global_position + Vector2.RIGHT.rotated(angle + index * TAU / 32) * distance
			if not boss_position_has_floor(candidate):
				continue
			query.transform = Transform2D(0.0, candidate)
			var ray := PhysicsRayQueryParameters2D.create(player.global_position, candidate, 1)
			if space.intersect_shape(query, 1).is_empty() and space.intersect_ray(ray).is_empty():
				return candidate
	# Player position is an in-map fallback, never the unrelated world origin.
	return player.global_position


func boss_position_has_floor(point: Vector2) -> bool:
	var terrain := get_parent().get_node("TileMap") as TileMap
	for offset: Vector2 in [Vector2.ZERO, Vector2(-48, 0), Vector2(48, 0), Vector2(0, -88), Vector2(0, 40)]:
		if terrain.get_cell_source_id(0, terrain.local_to_map(terrain.to_local(point + offset))) == -1:
			return false
	return true


func on_timer_timeout():
	if not spawning:
		return
	timer.start()

	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var spawn_count := get_endless_spawn_count(arena_time_manager.arena_difficulty) if GameEvents.is_endless_mode() else GameEvents.get_campaign_spawn_count()
	for _index in spawn_count:
		if not GameEvents.can_spawn_enemy():
			break
		var enemy_scene = pick_enemy_scene()
		var enemy = enemy_scene.instantiate() as Node2D
		apply_difficulty(enemy)

		var entities_layer = get_tree().get_first_node_in_group("entities_layer")
		entities_layer.add_child(enemy)
		enemy.global_position = get_spawn_position()


func get_endless_spawn_count(difficulty: int) -> int:
	return 1 + floori(float(difficulty) / 12.0)


func pick_enemy_scene() -> PackedScene:
	var scene: PackedScene = enemy_table.pick_item()
	if level == 5:
		if scene == GUARD and get_tree().get_nodes_in_group("forge_guard").size() >= 2:
			return CINDER
		if scene == WORKER and get_tree().get_nodes_in_group("forge_worker").size() >= 3:
			return CINDER
	return scene


func get_endless_boss_health_multiplier(difficulty: int) -> float:
	return 0.25 + difficulty * 0.015


func spawn_test_enemies(count: int = 20) -> void:
	var entities_layer := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities_layer == null:
		return
	var enemy_scenes: Array[PackedScene] = [basic_enemy_scene, wizard_enemy_scene, exploder_enemy_scene, ranged_enemy_scene, cyclops_bat_scene, iron_golem_scene, stone_slime_scene, frost_wisp_scene, frost_boar_scene, snowball_monster_scene]
	if level == 5:
		enemy_scenes.assign([CINDER, WORKER, GUARD])
	for _index in count:
		if not GameEvents.can_spawn_enemy():
			break
		var enemy := enemy_scenes.pick_random().instantiate() as Node2D
		apply_difficulty(enemy)
		entities_layer.add_child(enemy)
		enemy.global_position = get_spawn_position()


func apply_difficulty(enemy: Node2D) -> void:
	var health = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null and GameEvents.is_endless_mode():
		var level_health_multiplier := 1.6 if level == 2 else 1.0
		var mode_health_multiplier := ENDLESS_ENEMY_HEALTH_MULTIPLIER if GameEvents.is_endless_mode() else 1.0
		health.max_health *= mode_health_multiplier * level_health_multiplier * (1.0 + arena_time_manager.arena_difficulty * 0.05)

	var velocity = enemy.get_node_or_null("VelocityComponent") as VelocityComponent
	if velocity != null:
		velocity.max_speed = roundi(velocity.max_speed * (1.0 + arena_time_manager.arena_difficulty * 0.015))


func spawn_elite() -> Node2D:
	if not spawning or GameEvents.game_mode not in ["campaign", "endless"] or not GameEvents.can_spawn_enemy():
		return null
	var entities := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities == null:
		return null
	var elite := pick_enemy_scene().instantiate() as Node2D
	apply_difficulty(elite)
	elite.add_to_group("elite")
	elite.set_meta("periodic_elite", true)
	elite.set_meta("damage_multiplier", 1.5)
	elite.set_meta("move_speed_multiplier", 0.7)
	if elite.has_method("configure_small"):
		elite.set("can_split", false)
	entities.add_child(elite)
	elite.set_meta("contact_damage", float(elite.get_meta("contact_damage", 10.0)) * 1.5)
	elite.global_position = get_spawn_position()
	elite.scale *= 1.5
	elite.modulate = Color(1.0, 0.72, 0.36)
	var health := elite.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.max_health *= 5.0
		health.current_health = health.max_health
		health.died.connect(drop_elite_experience.bind(elite), CONNECT_ONE_SHOT)
	var velocity := elite.get_node_or_null("VelocityComponent") as VelocityComponent
	if velocity != null:
		velocity.max_speed *= 0.7
	var drop := elite.get_node_or_null("VialDropComponent") as VialDropComponent
	if drop != null:
		drop.disabled = true
	return elite


func drop_elite_experience(elite: Node2D) -> void:
	var entities := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities == null or not is_instance_valid(elite):
		return
	var spawn_position := elite.global_position
	for index in randi_range(5, 10):
		var vial := EXPERIENCE_VIAL.instantiate() as Node2D
		entities.add_child(vial)
		vial.global_position = spawn_position + Vector2.RIGHT.rotated(index * 2.399963) * (8.0 + index * 2.0)


func restart_elite_timer() -> void:
	if GameEvents.game_mode in ["campaign", "endless"]:
		elite_timer.start(15.0 * GameEvents.curse_elite_interval_multiplier)


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
	if level == 5:
		if arena_difficulty == 6:
			enemy_table.add_item(WORKER, 3)
		if arena_difficulty == 12:
			enemy_table.add_item(GUARD, 2)
		return
	
	if arena_difficulty == 6 and not GameEvents.is_endless_mode():
		enemy_table.add_item(wizard_enemy_scene, 20)


func stop_spawning() -> void:
	spawning = false
	timer.stop()
	elite_timer.stop()


func resume_spawning() -> void:
	spawning = true
	timer.start()
	restart_elite_timer()


func start_endless() -> void:
	if level == 5:
		start_level_5()
		return
	spawning = true
	enemy_table = WeightedTable.new()
	var enemy_scenes: Array[PackedScene] = [basic_enemy_scene, wizard_enemy_scene, exploder_enemy_scene, ranged_enemy_scene, cyclops_bat_scene, iron_golem_scene, stone_slime_scene, frost_wisp_scene, frost_boar_scene, snowball_monster_scene]
	for enemy_scene: PackedScene in enemy_scenes:
		enemy_table.add_item(enemy_scene, 10)
	base_spawn_time = 0.7
	timer.wait_time = base_spawn_time
	timer.start()
	restart_elite_timer()


func start_level_1() -> void:
	level = 1
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(basic_enemy_scene, 10)
	base_spawn_time = 0.9
	timer.wait_time = base_spawn_time
	timer.start()
	restart_elite_timer()


func start_level_2() -> void:
	level = 2
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(basic_enemy_scene, 8)
	enemy_table.add_item(wizard_enemy_scene, 5)
	enemy_table.add_item(exploder_enemy_scene, 4)
	enemy_table.add_item(ranged_enemy_scene, 5)
	base_spawn_time = 0.9
	timer.wait_time = base_spawn_time
	timer.start()
	restart_elite_timer()


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
	base_spawn_time = 0.9
	timer.wait_time = base_spawn_time
	timer.start()
	restart_elite_timer()


func start_level_4() -> void:
	level = 4
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(cyclops_bat_scene, 3)
	enemy_table.add_item(iron_golem_scene, 3)
	enemy_table.add_item(stone_slime_scene, 3)
	enemy_table.add_item(frost_wisp_scene, 9)
	enemy_table.add_item(frost_boar_scene, 6)
	enemy_table.add_item(snowball_monster_scene, 7)
	base_spawn_time = 0.9
	timer.wait_time = base_spawn_time
	timer.start()
	restart_elite_timer()


func start_level_5() -> void:
	level = 5
	spawning = true
	enemy_table = WeightedTable.new()
	enemy_table.add_item(CINDER, 10)
	base_spawn_time = 0.9
	timer.wait_time = base_spawn_time
	timer.start()
	restart_elite_timer()
