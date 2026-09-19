extends CharacterBody2D

const ART = preload("res://scenes/environment/forge_art.gd")
const EFFECT = preload("res://scenes/environment/forge_effect.gd")
const ACTOR_NAMES := ["cinder", "guard", "worker", "tyrant"]
const DISPLAY_NAMES := ["煤渣虫", "炉膛守卫", "运火工", "熔炉暴君"]
const DISPLAY_HEIGHTS := [22.0, 70.0, 30.0, 96.0]
const COLLISION_HEIGHTS := [22.0, 42.0, 30.0, 96.0]
const CONTACT_DAMAGE := [18.0, 24.0, 20.0, 30.0]
const CINDER_PREHEAT_RANGE := 95.0
const CINDER_EXPLOSION_RANGE := 38.0
@export_enum("煤渣虫", "炉膛守卫", "运火工", "熔炉暴君") var kind := 0
@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D
var facing := Vector2.DOWN
var action := "walk"
var action_time := 0.0
var action_duration := 0.0
var attack_cooldown := 1.0
var barrel: Node2D
var barrel_dropped := false
var last_thrown_barrel: Node2D
var throw_target := Vector2.ZERO
var hammer_hit := false
var cinder_fuse_left := -1.0
var cinder_fuse_total := 0.0
var cinder_exploded := false

func _enter_tree() -> void:
	set_meta("display_name", DISPLAY_NAMES[kind])
	set_meta("contact_damage", CONTACT_DAMAGE[kind])
	if kind == 1:
		add_to_group("forge_guard")
	elif kind == 2:
		add_to_group("forge_worker")

func _ready() -> void:
	if kind == 0 and GameEvents.game_mode in ["campaign", "boss_rush"]:
		# This used to be x0.75; x3.75 is exactly five times that live value.
		health_component.max_health *= 3.75
		health_component.current_health = health_component.max_health
	elif kind == 0:
		health_component.max_health *= 5.0
		health_component.current_health = health_component.max_health
	health_component.health_changed.connect(update_health_bar)
	health_component.died.connect(on_died, CONNECT_ONE_SHOT)
	var height: float = DISPLAY_HEIGHTS[kind]
	sprite.position = Vector2(0, -height / 2 + 8)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var hurt_shape := CircleShape2D.new()
	hurt_shape.radius = COLLISION_HEIGHTS[kind] * 0.38
	$HurtboxComponent/CollisionShape2D.shape = hurt_shape
	$HurtboxComponent/CollisionShape2D.position = Vector2(0, -COLLISION_HEIGHTS[kind] * 0.25)
	var body_shape := CircleShape2D.new()
	body_shape.radius = COLLISION_HEIGHTS[kind] * 0.2
	$CollisionShape2D.shape = body_shape
	$HealthBar.offset_top = -height - 6
	$HealthBar.offset_bottom = -height - 2
	update_animation(0)
	update_health_bar()

func set_action(next: String, duration: float = 0.0) -> void:
	if action != next or duration > 0:
		action = next
		action_time = 0.0
		action_duration = duration

func update_animation(delta: float) -> void:
	action_time += delta
	var actor: String = ACTOR_NAMES[kind]
	var count := ART.frame_count(actor, action)
	var frame := mini(int(action_time / action_duration * count), count - 1) if action_duration > 0 else int(action_time * 9) % count
	sprite.texture = ART.frame_texture(actor, action, frame)
	sprite.region_enabled = false
	sprite.scale = Vector2.ONE * DISPLAY_HEIGHTS[kind] / sprite.texture.get_width()
	sprite.flip_h = facing.x < 0

func move_toward_player(player: Node2D) -> void:
	facing = global_position.direction_to(player.global_position)
	var direction := facing
	# Local steering is enough for this map's wide two-exit routes; reuse movement.
	var best_score := -INF
	for angle: float in [0.0, 0.65, -0.65, 1.3, -1.3, 1.9, -1.9]:
		var candidate := facing.rotated(angle)
		var query := PhysicsRayQueryParameters2D.create(global_position, global_position + candidate * 48.0, 1)
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty() and candidate.dot(facing) > best_score:
			direction = candidate
			best_score = candidate.dot(facing)
	velocity_component.accelerate_in_direction(direction)
	velocity_component.move(self)

func _process(delta: float) -> void:
	if health_component.current_health <= 0:
		return
	update_animation(delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	attack_cooldown -= delta
	if kind == 0:
		var distance := global_position.distance_to(player.global_position)
		if cinder_fuse_left < 0.0 and distance <= CINDER_PREHEAT_RANGE:
			velocity_component.max_speed = 120.0
			cinder_fuse_total = clampf((distance - 18.0) / velocity_component.max_speed, 0.65, 1.6)
			cinder_fuse_left = cinder_fuse_total
		if cinder_fuse_left >= 0.0:
			cinder_fuse_left -= delta
			sprite.modulate = Color(1.35, 0.55 + 0.35 * absf(sin(cinder_fuse_left * 16.0)), 0.3)
			if cinder_fuse_left <= 0.0:
				explode_cinder()
				return
		move_toward_player(player)
		queue_redraw()
		return
	if kind == 1 and action == "charge":
		if action_time >= 0.8:
			set_action("hammer", 0.35)
			hammer_hit = false
		return
	if kind == 1 and action in ["hammer", "recover"]:
		if action == "hammer" and action_time >= 0.175 and not hammer_hit:
			hammer_hit = true
			var strike := EFFECT.new()
			strike.shape = "cone"
			strike.kind = "flame"
			strike.direction = facing
			strike.radius = 70
			strike.warning_time = 0.0
			strike.active_time = 0.15
			strike.player_damage = 24
			strike.damage_interval = 10
			strike.damage_source = "炉膛守卫的锻造锤"
			strike.owner_id = get_instance_id()
			strike.caster = self
			strike.require_caster = true
			add_effect(strike, global_position)
		if action_time >= action_duration:
			if action == "hammer":
				set_action("recover", 0.7)
			else:
				set_action("walk")
				attack_cooldown = 1.0
		return
	if kind == 2 and action == "ignite":
		if action_time >= action_duration:
			throw_barrel(throw_target)
			set_action("shake", 0.35)
		return
	if kind == 2 and action == "shake":
		if action_time >= action_duration:
			set_action("walk")
			attack_cooldown = 3.2
		return
	if kind == 1 and attack_cooldown <= 0 and global_position.distance_to(player.global_position) <= 74:
		facing = global_position.direction_to(player.global_position)
		velocity = Vector2.ZERO
		velocity_component.velocity = Vector2.ZERO
		set_action("charge", 0.8)
		var warning := EFFECT.new()
		warning.kind = "warning"
		warning.shape = "cone"
		warning.direction = facing
		warning.radius = 70
		warning.warning_time = 0.8
		warning.active_time = 0.19
		warning.owner_id = get_instance_id()
		warning.caster = self
		warning.require_caster = true
		add_effect(warning, global_position)
	elif kind == 2 and attack_cooldown <= 0 and global_position.distance_to(player.global_position) <= 220:
		facing = global_position.direction_to(player.global_position)
		velocity = Vector2.ZERO
		velocity_component.velocity = Vector2.ZERO
		throw_target = player.global_position
		var map := get_tree().get_first_node_in_group("forge_map") as Node2D
		if map != null and map.active:
			throw_target = map.safe_position(throw_target, 12.0)
		set_action("ignite", 0.4)
	else:
		move_toward_player(player)
	queue_redraw()

func modify_incoming_damage(amount: float, origin: Vector2, damage_kind: String, source: String) -> float:
	if kind != 1 or damage_kind != "direct":
		return amount
	if not origin.is_finite():
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and source.is_empty():
			origin = player.global_position
	if origin.is_finite() and global_position.direction_to(origin).dot(facing) >= 0.5:
		return amount * 0.6
	return amount

func drop_barrel(delay: float) -> void:
	if barrel_dropped:
		if is_instance_valid(barrel) and not barrel.exploded:
			barrel.warning_time = minf(barrel.warning_time, barrel.elapsed + delay)
		return
	barrel_dropped = true
	barrel = EFFECT.new()
	barrel.kind = "barrel"
	barrel.radius = 58
	barrel.warning_time = delay
	barrel.active_time = 0.35
	barrel.player_damage = 28
	barrel.enemy_damage = 45
	barrel.affect_enemies = true
	add_effect(barrel, global_position)

func throw_barrel(target: Vector2) -> void:
	last_thrown_barrel = EFFECT.new()
	last_thrown_barrel.kind = "barrel"
	last_thrown_barrel.radius = 58
	last_thrown_barrel.warning_time = 1.0
	last_thrown_barrel.active_time = 0.35
	last_thrown_barrel.player_damage = 28
	last_thrown_barrel.enemy_damage = 45
	last_thrown_barrel.affect_enemies = true
	last_thrown_barrel.owner_id = get_instance_id()
	last_thrown_barrel.flight_time = 0.65
	last_thrown_barrel.start_position = global_position
	last_thrown_barrel.target_position = target
	add_effect(last_thrown_barrel, global_position)

func explode_cinder() -> void:
	if cinder_exploded:
		return
	cinder_exploded = true
	var explosion := EFFECT.new()
	explosion.kind = "fire"
	explosion.radius = CINDER_EXPLOSION_RANGE
	explosion.warning_time = 0.0
	explosion.active_time = 0.22
	explosion.damage_interval = 10.0
	explosion.player_damage = 22.0
	explosion.damage_source = "煤渣虫自爆"
	explosion.owner_id = get_instance_id()
	add_effect(explosion, global_position)
	health_component.damage(health_component.max_health * 100.0, "煤渣虫自爆", global_position, "environment")

func add_effect(effect: Node2D, point: Vector2) -> void:
	if has_meta("forge_owner_id"):
		effect.set_meta("forge_owner_id", get_meta("forge_owner_id"))
	var layer_name := "combat_effects_layer" if effect.kind in ["death", "steam"] else "enemy_projectiles_layer"
	get_tree().get_first_node_in_group(layer_name).add_child(effect)
	effect.global_position = point

func on_died() -> void:
	if kind == 2:
		drop_barrel(0.8)
	elif kind == 0:
		var count := 0
		for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
			if effect.kind == "ember" and not effect.is_queued_for_deletion():
				count += 1
		if count < 8:
			var ember := EFFECT.new()
			ember.kind = "ember"
			ember.radius = 15
			ember.warning_time = 0.3
			ember.active_time = 1.0
			ember.player_damage = 6
			ember.damage_source = "煤渣虫的余烬"
			add_effect(ember, global_position)
	var death := EFFECT.new()
	death.kind = "death"
	death.warning_time = 0
	death.active_time = 1.0 if kind == 3 else 0.5
	death.death_actor = ACTOR_NAMES[kind]
	add_effect(death, global_position)

func update_health_bar() -> void:
	$HealthBar.value = health_component.get_health_percent()

func _draw() -> void:
	if kind == 1:
		draw_arc(Vector2.ZERO, 18, facing.angle() - 0.5, facing.angle() + 0.5, 12, Color(1, 0.8, 0.4), 3)
	elif kind == 0 and cinder_fuse_left >= 0.0:
		var progress := clampf(1.0 - cinder_fuse_left / cinder_fuse_total, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 13.0, Color(1.0, 0.08, 0.02, 0.10 + progress * 0.18))
		draw_arc(Vector2.ZERO, 14.0, -PI / 2, -PI / 2 + TAU * progress, 28, Color(1.0, 0.2, 0.05), 2.5)
