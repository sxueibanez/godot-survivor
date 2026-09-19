extends "res://scenes/game_object/forge_enemy/forge_enemy.gd"

const CINDER = preload("res://scenes/game_object/forge_enemy/cinder.tscn")
const WORKER = preload("res://scenes/game_object/forge_enemy/worker.tscn")
var state := "intro"
var state_time := 0.0
var phase := 1
var overheat_immunity := 0.0
var attack_id := 0
var combo_count := 0
var combo_attack := false
var impact_radius := 54.0
var locked_target := Vector2.ZERO
var summons: Array[Node2D] = []
var last_skill := ""
var slag_targets: Array[Vector2] = []
var event_fired := false
var rift_index := 0
var dead := false
var rage_lines: Array[Line2D] = []
var dash_direction := Vector2.RIGHT
var dash_left := 0.0
var dash_hit := false
const DASH_WARNING := 0.45
const DASH_SPEED := 480.0
const DASH_MAX_DISTANCE := 280.0

func _ready() -> void:
	super._ready()
	collision_layer = 0 # Preparation has no unannounced contact damage.
	set_action("idle")
	for side in [-1, 1]:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(side * 20, -58), Vector2(side * 15, -43), Vector2(side * 22, -32), Vector2(side * 17, -18)])
		line.width = 1.5
		line.default_color = Color(1, 0.75, 0.1)
		line.visible = false
		$Visuals.add_child(line)
		rage_lines.append(line)
	var map := forge_map()
	if map != null:
		map.announce_boss()

func forge_map() -> Node2D:
	var map := get_tree().get_first_node_in_group("forge_map") as Node2D
	return map if map != null and map.active else null

func get_phase() -> int:
	var ratio := health_component.get_health_percent()
	return 1 if ratio > 0.65 else 2 if ratio >= 0.3 else 3

func begin_state(next: String, animation: String, duration: float = 0.0) -> void:
	state = next
	state_time = 0.0
	event_fired = false
	set_action(animation, duration)
	velocity = Vector2.ZERO
	velocity_component.velocity = Vector2.ZERO

func _process(delta: float) -> void:
	if dead or health_component.current_health <= 0:
		return
	overheat_immunity = maxf(0, overheat_immunity - delta)
	state_time += delta
	update_animation(delta)
	for line: Line2D in rage_lines:
		line.visible = phase == 3 and state != "intro"
		line.modulate.a = 0.65 + sin(state_time * 12) * 0.2
	if get_phase() != phase and state != "overheat":
		phase = get_phase()
		cancel_attacks()
		begin_state("transition", "transition", 0.65)
		sprite.modulate = Color(1.2, 0.72, 0.4) if phase == 3 else Color(1.1, 0.9, 0.7)
		return
	match state:
		"intro", "transition":
			if state_time >= (2.0 if state == "intro" else 0.65):
				collision_layer = 8
				begin_state("idle", "walk")
				attack_cooldown = 0.8
		"overheat":
			if state_time >= 3.0:
				overheat_immunity = 8.0
				begin_state("recover", "close", 0.8)
		"idle":
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player == null:
				return
			velocity_component.max_speed = 52 if phase == 3 else 38
			move_toward_player(player)
			attack_cooldown -= delta
			if attack_cooldown <= 0:
				var distance := global_position.distance_to(player.global_position)
				if distance > 230.0:
					start_skill("dash")
					return
				# Dash already guarantees a follow-up punch, so favor the other attacks.
				var skills := ["summon", "summon", "flame", "flame"]
				if distance >= 95.0:
					skills.append("dash")
				if distance <= 120:
					skills.append("punch")
				if phase >= 2:
					skills.append_array(["slag", "slag", "slag"])
					if distance <= 120:
						skills.append("combo")
				if phase == 3:
					skills.append_array(["rifts", "rifts", "rifts"])
				start_skill(skills.pick_random())
		"dash_warning":
			if state_time >= DASH_WARNING:
				begin_state("dash", "walk")
		"dash":
			# One extra update makes the existing walk loop play at triple speed.
			update_animation(delta * 2.0)
			var previous := global_position
			velocity = dash_direction * DASH_SPEED
			move_and_slide()
			dash_left -= previous.distance_to(global_position)
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if not dash_hit and player != null and global_position.distance_to(player.global_position) <= 55.0:
				dash_hit = true
				var health := player.get_node_or_null("HealthComponent") as HealthComponent
				if health != null:
					health.damage(32.0, "熔炉暴君的熔火冲锋")
				var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
				if movement != null:
					movement.apply_knockback(dash_direction, 360.0, 0.25)
			if dash_left <= 0.0 or is_on_wall() or dash_hit:
				combo_attack = false
				combo_count = 1
				prepare_punch()
		"punch_charge":
			if state_time >= action_duration:
				begin_state("impact", "hammer", 0.3)
		"impact":
			# Zero-based frame 3 (fourth cell of six): landing event at t=0.15.
			if state_time >= 0.15 and not event_fired:
				event_fired = true
				land_punch()
				if state == "overheat":
					return
			if state_time >= 0.3:
				combo_count -= 1
				begin_state("combo_gap" if combo_count > 0 else "recover", "recover", 0.35 if combo_count > 0 else 1.15 if combo_attack else 0.8)
		"combo_gap":
			if state_time >= 0.35:
				prepare_punch()
		"flame_charge":
			if state_time >= 0.9:
				var flame := owned_effect("flame", global_position)
				flame.shape = "cone"
				flame.direction = facing
				flame.radius = 175
				flame.warning_time = 0
				flame.active_time = 1.5
				flame.player_damage = 14
				flame.damage_source = "熔炉暴君的炉口喷火"
				begin_state("flame_active", "flame")
		"flame_active":
			if state_time >= 1.5:
				begin_state("recover", "close", 0.8)
		"summon":
			if state_time >= 0.6 and not event_fired:
				event_fired = true
				spawn_batch(2)
			if state_time >= 1.05:
				spawn_batch(2)
				if phase >= 2:
					spawn_minion(WORKER)
				begin_state("recover", "close", 0.8)
		"slag":
			# Zero-based frame 4 (fifth cell of six): release event at t=0.6.
			if state_time >= 0.6 and not event_fired:
				event_fired = true
				for target in slag_targets:
					var slag := owned_effect("slag", global_position)
					slag.warning_time = 0.8
					slag.start_position = global_position
					slag.target_position = target
			if state_time >= 0.9:
				begin_state("recover", "recover", 0.8)
		"rifts":
			if state_time >= 0.8 + rift_index * 1.4 and rift_index < 3:
				activate_rift(rift_index)
				rift_index += 1
			if state_time >= 6.4:
				var map := forge_map()
				if map != null:
					map.scheduler_paused = false
				begin_state("recover", "recover", 0.8)
		"recover":
			if state_time >= action_duration:
				begin_state("idle", "walk")
				attack_cooldown = 0.65 if phase == 3 else 1.0 if phase == 2 else 1.4
				if last_skill == "summon":
					attack_cooldown *= GameEvents.curse_summon_cooldown_multiplier

func start_skill(skill: String) -> void:
	if dead or state != "idle":
		return
	attack_id += 1
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	last_skill = skill
	match skill:
		"dash":
			dash_direction = global_position.direction_to(player.global_position)
			if dash_direction == Vector2.ZERO:
				dash_direction = Vector2.RIGHT
			facing = dash_direction
			dash_left = minf(maxf(global_position.distance_to(player.global_position) - 45.0, 90.0), DASH_MAX_DISTANCE)
			dash_hit = false
			begin_state("dash_warning", "charge", DASH_WARNING)
			var warning := owned_effect("warning", global_position)
			warning.shape = "line"
			warning.line_end = dash_direction * dash_left
			warning.radius = 24.0
			warning.warning_time = DASH_WARNING
			warning.active_time = 0.01
		"punch", "combo":
			combo_attack = skill == "combo"
			combo_count = (3 if phase == 3 else 2) if skill == "combo" else 1
			prepare_punch()
		"flame":
			facing = global_position.direction_to(player.global_position)
			begin_state("flame_charge", "open", 0.9)
			var warning := owned_effect("warning", global_position)
			warning.shape = "cone"
			warning.direction = facing
			warning.radius = 175
			warning.warning_time = 0.9
			warning.active_time = 0.01
		"summon":
			begin_state("summon", "open", 1.05)
		"slag":
			slag_targets.clear()
			begin_state("slag", "throw", 0.9)
			for index in 3:
				var point := player.global_position + Vector2.RIGHT.rotated(index * TAU / 3 + randf()) * 85
				var map := forge_map()
				if map != null:
					point = map.safe_position(point)
				slag_targets.append(point)
				var warning := owned_effect("warning", point)
				warning.warning_time = 1.4
				warning.active_time = 0.01
				warning.radius = 32
		"rifts":
			begin_state("rifts", "transition", 0.8)
			rift_index = 0
			var map := forge_map()
			if map != null:
				map.scheduler_paused = true

func prepare_punch() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	locked_target = player.global_position
	impact_radius = 70.0 if combo_attack and combo_count == 1 else 54.0
	var charge := 0.85 if phase == 3 else 1.0
	begin_state("punch_charge", "charge", charge)
	var warning := owned_effect("warning", locked_target)
	warning.radius = impact_radius
	warning.warning_time = charge + 0.15
	warning.active_time = 0.01

func land_punch() -> void:
	var impact := owned_effect("fire", locked_target)
	impact.warning_time = 0.0
	impact.active_time = 0.12
	impact.radius = impact_radius
	impact.damage_interval = 10
	impact.player_damage = 40
	impact.damage_source = "熔炉暴君的铸炉重拳"
	var wave := owned_effect("wave", locked_target)
	wave.warning_time = 0.0
	wave.active_time = 0.65
	wave.radius = 140
	wave.damage_interval = 10
	wave.player_damage = 14
	wave.damage_source = "熔炉暴君的冲击波"
	var map := forge_map()
	if map != null and map.slam_valves(locked_target, impact_radius, get_instance_id() * 10000 + attack_id):
		enter_overheat()

func enter_overheat() -> bool:
	if dead or state == "overheat" or overheat_immunity > 0:
		return false
	cancel_attacks()
	begin_state("overheat", "overheat")
	var steam := owned_effect("steam", global_position)
	steam.warning_time = 0
	steam.active_time = 3
	return true

func modify_incoming_damage(amount: float, origin: Vector2, damage_kind: String, source: String) -> float:
	return amount * 1.25 if state == "overheat" and source.is_empty() else amount

func owned_effect(effect_kind: String, point: Vector2) -> Node2D:
	var effect := EFFECT.new()
	effect.kind = effect_kind
	effect.owner_id = get_instance_id()
	effect.caster = self
	effect.require_caster = true
	add_effect(effect, point)
	return effect

func spawn_batch(count: int) -> void:
	for index in maxi(1, ceili(count * GameEvents.curse_summon_count_multiplier)):
		spawn_minion(CINDER)

func spawn_minion(scene: PackedScene) -> void:
	if dead or state == "overheat" or not GameEvents.can_spawn_enemy():
		return
	if scene == WORKER and get_tree().get_nodes_in_group("forge_worker").size() >= 3:
		return
	var alive := 0
	for summon in summons:
		if is_instance_valid(summon) and not summon.is_queued_for_deletion() and summon.health_component.current_health > 0:
			alive += 1
	if alive >= 8:
		return
	var summon := scene.instantiate() as Node2D
	summon.set_meta("forge_owner_id", get_instance_id())
	get_tree().get_first_node_in_group("entities_layer").add_child(summon)
	GameEvents.configure_summon(summon, self)
	var point := global_position + Vector2.RIGHT.rotated(randf() * TAU) * 75
	var map := forge_map()
	summon.global_position = map.safe_position(point) if map != null else point
	summons.append(summon)

func activate_rift(index: int) -> void:
	var map := forge_map()
	if map != null:
		if map.trigger_crack(index):
			map.cracks[index].set_meta("forge_owner_id", get_instance_id())
			map.cracks[index].caster = self
			map.cracks[index].require_caster = true
			map.cracks[index].player_damage = 12
			map.cracks[index].damage_source = "熔炉暴君的裂缝连喷"
	else:
		var crack := owned_effect("eruption", global_position + Vector2.RIGHT.rotated(index * TAU / 3) * 80)
		crack.shape = "line"
		crack.line_end = Vector2.RIGHT.rotated(index * TAU / 3) * 160
		crack.radius = 16
		crack.warning_time = 1.2
		crack.active_time = 1.5
		crack.player_damage = 12
		crack.damage_source = "熔炉暴君的裂缝连喷"

func cancel_attacks() -> void:
	attack_id += 1
	for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
		if effect.kind != "death" and (effect.owner_id == get_instance_id() or effect.get_meta("forge_owner_id", 0) == get_instance_id()):
			effect.queue_free()
	var map := forge_map()
	if map != null:
		map.scheduler_paused = false

func on_died() -> void:
	if dead:
		return
	dead = true
	cancel_attacks()
	for summon in summons:
		if is_instance_valid(summon):
			summon.queue_free()
	super.on_died()
