extends Node

const EFFECT = preload("res://scenes/environment/forge_effect.gd")
const ART = preload("res://scenes/environment/forge_art.gd")
const CINDER = preload("res://scenes/game_object/forge_enemy/cinder.tscn")
const GUARD = preload("res://scenes/game_object/forge_enemy/guard.tscn")
const WORKER = preload("res://scenes/game_object/forge_enemy/worker.tscn")
var main: Node
var map: Node2D
var player: Node2D
var health: HealthComponent

func add_enemy(scene: PackedScene, point: Vector2) -> Node2D:
	var enemy := scene.instantiate() as Node2D
	main.get_node("Entities").add_child(enemy)
	enemy.global_position = point
	enemy.set_process(false)
	return enemy

func clear_effects() -> void:
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		effect.queue_free()

func check_art() -> void:
	for actor: String in ART.ACTORS:
		var spec: Dictionary = ART.ACTORS[actor]
		for action: String in spec:
			if action == "size":
				continue
			for frame in int(spec[action]):
				var texture := ART.frame_texture(actor, action, frame)
				assert(texture.region.has_area())
				assert(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region))
				var feet := (texture.margin.position.y + texture.region.size.y) / texture.get_height()
				assert(absf(feet - 0.9) < 0.004, "Foot anchor shifted: %s %s" % [actor, action])
	for name: String in {"floor_tiles": [16, 16, 7], "walls": [16, 16, 12], "lava": [16, 16, 4], "lava_edges": [16, 16, 48], "cracks": [16, 16, 6], "furnace": [96, 96, 4], "bench": [32, 32, 1], "anvil": [32, 32, 1], "ore": [32, 32, 3], "pipe": [16, 16, 4], "valve_idle": [32, 32, 2], "valve_active": [32, 32, 4], "valve_cool": [32, 32, 1], "cooling_pool": [64, 48, 1], "barrel": [24, 24, 1], "eruption": [64, 96, 8], "flame": [128, 128, 8], "slag": [24, 24, 4], "fire": [64, 64, 6], "steam": [64, 64, 6], "ember": [32, 32, 4]}:
		assert(Image.load_from_file(ART.ROOT + name + ".png") != null)
	var floor := Image.load_from_file(ART.ROOT + "floor_tiles.png")
	for y in 16:
		for x in 112:
			assert(floor.get_pixel(x, y).a == 1)
	print("FORGE_ART_OK: actor frame counts, alpha, margins/all-action foot anchors; props/effects present, opaque floor")

func check_routes() -> void:
	# Four-neighbour flood fill with player-sized clearance; corners are blocked.
	var seen: Dictionary = {Vector2i(0, 0): true}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if not seen.has(next) and map.is_walkable(map.CENTER + Vector2(next) * 32, 12):
				seen[next] = true
				queue.append(next)
	# Separate left/right or top/bottom routes to every exterior work area.
	for cell: Vector2i in [Vector2i(-4, -13), Vector2i(4, -13), Vector2i(13, -4), Vector2i(13, 4), Vector2i(-4, 13), Vector2i(4, 13), Vector2i(-13, -4), Vector2i(-13, 4)]:
		assert(seen.has(cell), "Work zone exit unreachable: %s" % cell)
	for index in 200:
		var point: Vector2 = map.get_spawn_position(map.CENTER + Vector2(randf_range(-450, 450), randf_range(-450, 450)))
		assert(map.is_walkable(point, 24))
		for pool: Rect2 in map.pools:
			assert(not pool.has_point(point))
	assert(map.is_walkable(map.CENTER))
	assert(not map.is_walkable(Vector2(-220, 384)))
	print("FORGE_ROUTES_OK: eight exits reachable, 200 safe spawns, closed boundary")

func _ready() -> void:
	check_art()
	GameEvents.game_mode = "boss_rush" # Fixed HP, no campaign/permanent multiplier.
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.boss_rush.set_process(false)
	main.set_process(false)
	for child: Node in main.get_children():
		if child.has_signal("character_selected"):
			child.queue_free()
	get_tree().paused = false
	main.show_map(5)
	main.current_map_id = 5
	map = main.forge_map
	map.set_process(false)
	map.scheduler_paused = true
	player = main.get_node("Entities/Player")
	player.set_process(false)
	player.get_node("CollisionArea2D").monitoring = false
	player.get_node("Abilities").process_mode = Node.PROCESS_MODE_DISABLED
	health = player.get_node("HealthComponent")
	health.max_health = 1000
	health.current_health = 1000
	health.shield = 0
	check_routes()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var probe := PhysicsPointQueryParameters2D.new()
	probe.collision_mask = 1
	probe.position = map.pools[0].get_center()
	assert(not map.get_world_2d().direct_space_state.intersect_point(probe).is_empty())
	probe.position = map.CENTER
	assert(map.get_world_2d().direct_space_state.intersect_point(probe).is_empty())
	player.global_position = map.valves[0].position
	map._process(0.59)
	assert(map.active_crack_count() == 0)
	map._process(0.02)
	assert(map.active_crack_count() == 1)
	assert(map.valves[0].cooldown == 10.0)
	assert(not map.activate_valve(0, 123))
	var crack: Node2D = map.cracks[0]
	crack.set_process(false)
	var before := health.current_health
	crack._process(1.19)
	assert(health.current_health == before)
	crack._process(0.02)
	assert(health.current_health == before - 6)
	assert(GameEvents.last_damage_source == "熔岩裂缝")
	crack._process(0.1)
	crack._process(0.3)
	assert(health.current_health == before - 6)
	crack._process(0.11)
	assert(health.current_health == before - 12)
	assert(map.trigger_crack(1))
	assert(not map.trigger_crack(2))
	player.global_position = map.CENTER
	map._process(9.9)
	assert(map.valves[0].cooldown > 0)
	map._process(0.11)
	assert(map.valves[0].cooldown == 0)
	clear_effects()
	await get_tree().process_frame
	assert(map.activate_valve(0, 123))
	map.valves[0].cooldown = 0
	clear_effects()
	await get_tree().process_frame
	assert(not map.activate_valve(0, 123))
	print("FORGE_ENVIRONMENT_OK: 0.6s valve, 1.2s warning, 0.5s damage, 10s cooldown, two-crack cap, duplicate attack")

	var guard := add_enemy(GUARD, map.CENTER + Vector2(100, 0))
	guard.facing = Vector2.RIGHT
	assert(is_equal_approx(guard.modify_incoming_damage(10, guard.global_position + Vector2.RIGHT, "direct", ""), 6))
	assert(guard.modify_incoming_damage(10, guard.global_position + Vector2.LEFT, "direct", "") == 10)
	assert(guard.modify_incoming_damage(10, guard.global_position + Vector2.RIGHT, "dot", "") == 10)
	assert(guard.modify_incoming_damage(10, guard.global_position + Vector2.RIGHT, "environment", "熔岩裂缝") == 10)
	player.global_position = guard.global_position + Vector2(60, 0)
	guard.attack_cooldown = 0
	guard._process(0.01)
	assert(guard.action == "charge")
	var locked: Vector2 = guard.facing
	player.global_position = guard.global_position + Vector2(-60, 0)
	guard._process(0.79)
	assert(guard.facing == locked)
	guard._process(0.02)
	assert(guard.action == "hammer")
	guard._process(0.18)
	assert(guard.hammer_hit)
	guard._process(0.18)
	assert(guard.action == "recover")
	guard._process(0.71)
	assert(guard.action == "walk")
	guard.queue_free()
	clear_effects()
	await get_tree().process_frame
	print("FORGE_GUARD_OK: frontal defence, DOT/environment bypass, locked warning, landing frame and recovery")

	player.global_position = map.CENTER
	var worker := add_enemy(WORKER, map.CENTER)
	worker.drop_barrel(1.2)
	worker.health_component.damage(100000)
	worker.on_died() # Simulate active and death callbacks reaching the same unit.
	var barrel: Node2D = worker.barrel
	barrel.set_process(false)
	assert(barrel.warning_time == 0.8)
	await get_tree().process_frame
	var count := 0
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "barrel" and not effect.is_queued_for_deletion():
			count += 1
	assert(count == 1)
	var neighbour := add_enemy(WORKER, map.CENTER + Vector2(15, 0))
	neighbour.health_component.current_health = 20
	before = health.current_health
	barrel._process(0.79)
	assert(health.current_health == before)
	barrel._process(0.02)
	assert(barrel.exploded and health.current_health == before - 28)
	barrel.detonate()
	assert(health.current_health == before - 28)
	assert(neighbour.health_component.current_health == 0)
	await get_tree().process_frame
	count = 0
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "barrel" and not effect.is_queued_for_deletion():
			count += 1
	assert(count == 2)
	for valve: Dictionary in map.valves:
		assert(valve.cooldown == 0)
	clear_effects()
	await get_tree().process_frame
	var active_worker := add_enemy(WORKER, map.CENTER + Vector2(30, 0))
	active_worker.health_component.max_health = 100
	active_worker.health_component.current_health = 100
	active_worker._process(0.01)
	assert(active_worker.barrel_dropped)
	active_worker.barrel.set_process(false)
	active_worker.barrel._process(1.19)
	assert(not active_worker.barrel.exploded)
	active_worker.barrel._process(0.02)
	active_worker._process(0.01)
	assert(active_worker.health_component.current_health == 0)
	await get_tree().process_frame
	clear_effects()
	await get_tree().process_frame
	print("FORGE_BARREL_OK: death/active paths exactly once, chain reaction, separate damage, no valve activation")

	main.boss_rush.spawning_boss = true
	var boss: Node2D = main.spawn_boss_for_map(5)
	main.boss_rush.spawning_boss = false
	boss.set_process(false)
	boss.health_component.max_health = 2000
	boss.health_component.current_health = 2000
	assert(boss.state == "intro" and map.introduction.visible)
	boss._process(1.99)
	assert(boss.state == "intro")
	boss._process(0.02)
	assert(boss.state == "idle")
	boss.health_component.current_health = 1280
	boss._process(0.01)
	assert(boss.phase == 2 and boss.state == "transition")
	boss.health_component.current_health = 580
	boss._process(0.01)
	assert(boss.phase == 3 and boss.state == "transition")
	boss._process(0.66)
	assert(boss.state == "idle")
	player.global_position = map.valves[1].position
	boss.start_skill("punch")
	var punch_point: Vector2 = boss.locked_target
	player.global_position += Vector2(100, 0)
	boss._process(0.86)
	assert(boss.state == "impact" and boss.locked_target == punch_point)
	boss._process(0.151)
	assert(boss.state == "overheat" and map.valves[1].cooldown == 10)
	assert(map.active_crack_count() == 1)
	clear_effects()
	await get_tree().process_frame
	boss._process(3.01)
	boss._process(8.01)
	assert(boss.state == "idle")
	boss.start_skill("flame")
	locked = boss.facing
	player.global_position += Vector2(80, 60)
	boss._process(0.91)
	assert(boss.state == "flame_active" and boss.facing == locked)
	var flame: Node2D
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "flame" and effect.owner_id == boss.get_instance_id():
			flame = effect
	assert(flame != null)
	flame.set_process(false)
	assert(boss.enter_overheat())
	assert(not boss.enter_overheat())
	assert(flame.is_queued_for_deletion())
	before = health.current_health
	flame._process(1.0)
	assert(health.current_health == before)
	assert(boss.modify_incoming_damage(100, player.global_position, "direct", "") == 125)
	assert(boss.modify_incoming_damage(100, map.CENTER, "environment", "熔岩裂缝") == 100)
	boss._process(3.01)
	assert(boss.overheat_immunity == 8 and boss.state == "recover")
	assert(not boss.enter_overheat())
	boss._process(8.01)
	assert(boss.state == "idle" and boss.overheat_immunity == 0)
	boss.start_skill("summon")
	assert(boss.enter_overheat())
	boss._process(1.2)
	assert(boss.summons.is_empty())
	boss._process(1.81)
	boss._process(0.81)
	assert(boss.state == "idle")
	boss.start_skill("summon")
	boss._process(0.61)
	assert(boss.summons.size() == 2)
	boss._process(0.45)
	assert(boss.summons.size() == 5)
	for summon: Node2D in boss.summons:
		summon.set_process(false)
		assert(map.is_walkable(summon.global_position))
	for index in 10:
		boss.spawn_minion(CINDER)
	assert(boss.summons.size() == 8)
	for summon: Node2D in boss.summons:
		summon.set_process(false)
	boss.cancel_attacks()
	boss.begin_state("idle", "walk")
	player.global_position = map.CENTER + Vector2(200, 0)
	boss.start_skill("combo")
	assert(boss.combo_count == 3 and boss.impact_radius == 54)
	for index in 3:
		var locked_point: Vector2 = boss.locked_target
		player.global_position += Vector2(0, 30)
		boss._process(0.86)
		assert(boss.state == "impact" and boss.locked_target == locked_point)
		boss._process(0.16)
		assert(boss.event_fired)
		boss._process(0.15)
		if index < 2:
			assert(boss.state == "combo_gap")
			boss._process(0.36)
			assert(boss.state == "punch_charge" and boss.locked_target == player.global_position)
		else:
			assert(boss.state == "recover" and boss.action_duration == 1.15)
	clear_effects()
	await get_tree().process_frame
	boss.begin_state("idle", "walk")
	boss.start_skill("slag")
	assert(boss.slag_targets.size() == 3)
	boss._process(0.59)
	var projectiles := 0
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "slag":
			projectiles += 1
	assert(projectiles == 0)
	boss._process(0.02)
	var slags: Array[Node] = []
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "slag":
			slags.append(effect)
			effect.set_process(false)
	assert(slags.size() == 3)
	for slag in slags:
		slag._process(0.79)
		assert(not slag.is_queued_for_deletion())
		slag._process(0.02)
		assert(slag.is_queued_for_deletion())
	var fires := 0
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "fire" and not effect.is_queued_for_deletion():
			fires += 1
	assert(fires == 3)
	for index in 10:
		var slag: Node2D = boss.owned_effect("slag", boss.global_position)
		slag.target_position = map.CENTER
		slag.spawn_fire()
		slag.queue_free()
	fires = 0
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind == "fire" and not effect.is_queued_for_deletion():
			fires += 1
	assert(fires == 6)
	clear_effects()
	await get_tree().process_frame
	var env := EFFECT.new()
	env.warning_time = 0
	env.radius = 40
	env.affect_enemies = true
	main.get_node("Foreground").add_child(env)
	env.global_position = boss.global_position
	env.set_process(false)
	var boss_before: float = boss.health_component.current_health
	env._process(0.01)
	assert(boss.health_component.current_health == boss_before - 8)
	env.queue_free()
	boss.cancel_attacks()
	boss.begin_state("idle", "walk")
	boss.start_skill("rifts")
	assert(map.scheduler_paused)
	boss._process(0.81)
	assert(map.active_crack_count() == 1)
	var boss_id: int = boss.get_instance_id()
	var owned_flame: Node2D = boss.owned_effect("flame", player.global_position)
	owned_flame.warning_time = 0
	owned_flame.set_process(false)
	boss.health_component.current_health = 0
	boss.on_died()
	before = health.current_health
	owned_flame._process(1)
	boss._process(100)
	boss.spawn_minion(CINDER)
	assert(health.current_health == before)
	assert(not map.scheduler_paused)
	for summon: Node2D in boss.summons:
		assert(summon.is_queued_for_deletion())
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.owner_id == boss_id or effect.get_meta("forge_owner_id", 0) == boss_id:
			assert(effect.is_queued_for_deletion())
	boss.queue_free()
	await get_tree().process_frame
	assert(map.active_crack_count() == 0)
	print("FORGE_BOSS_OK: intro, phases, locked flame, overheat x1.25, 3s/8s immunity, interruption, summon cap/cleanup, environment cap, safe death")

	main.show_map(1)
	assert(not map.active)
	for solid: StaticBody2D in map.solids:
		assert(solid.collision_layer == 0)
	assert(main.get_node("TileMap").is_layer_enabled(0))
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	GameEvents.game_mode = "campaign"
	main = preload("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	main.begin_level_5()
	assert(main.current_map_id == 5 and main.get_node("EnemyManager").level == 5)
	var spawner: Node = main.get_node("EnemyManager")
	assert(spawner.pick_enemy_scene() == CINDER)
	spawner.on_arena_difficulty_increased(6)
	spawner.on_arena_difficulty_increased(12)
	for index in 200:
		assert(spawner.pick_enemy_scene() in [CINDER, WORKER, GUARD])
	main.start_enemy_wave_for_map(1)
	assert(spawner.pick_enemy_scene() == spawner.basic_enemy_scene)
	main.begin_level_5()
	GameEvents.game_mode = "endless"
	spawner.start_endless()
	assert(spawner.level == 5 and spawner.pick_enemy_scene() == CINDER)
	assert(main.get_node("CheatUI/LevelSelect").item_count == 5)
	main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	print("FORGE_INTEGRATION_OK: fifth campaign/endless map, isolated enemy pool, old terrain restored, debug entry")
	get_tree().quit()
