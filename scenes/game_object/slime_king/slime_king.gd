extends CharacterBody2D


const SLIME_SPRAY_COOLDOWN := 20.0
const MINION_COUNT := 10
const JUMP_COUNT := 3
const TELEPORT_WARNING_DURATION := 0.28
const TELEPORT_DAMAGE_RADIUS := 48.0
const TELEPORT_DAMAGE := 45.0
const JUMP_WARNING_DURATION := 0.6
const JUMP_DAMAGE_RADIUS := 50.0
const JUMP_DAMAGE := 60.0
const CORROSIVE_SPRAY_COOLDOWN := 5.0
const CORROSIVE_PUDDLE_COUNT := 3
const TRAIL_PUDDLE_LIFETIME := 3.8
const TRAIL_PUDDLE_DAMAGE := 4.0
const TRAIL_SLOW_PERCENT := 0.35
const TRAIL_SLOW_DURATION := 0.7
const TRAIL_INTERVAL := 0.35
const CHARGE_WARNING_DURATION := 0.65
const CHARGE_SPEED := 360.0
const CHARGE_MAX_DISTANCE := 220.0
const CHARGE_HIT_RADIUS := 24.0
const CHARGE_DAMAGE := 55.0
const CHARGE_KNOCKBACK_DISTANCE := 18.0
const CHARGE_KNOCKBACK_SPEED := 260.0
const CHARGE_TRAIL_INTERVAL := 0.08

var basic_enemy_scene: PackedScene = preload("res://scenes/game_object/basic_enemy/basic_enemy.tscn")
var corrosive_puddle_scene: PackedScene = preload("res://scenes/game_object/corrosive_puddle/corrosive_puddle.tscn")

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var visuals: Node2D = $Visuals

var slime_spray_time_left := 5.0
var ability_time_left := 8.0
var corrosive_spray_time_left := 3.0
var performing_ability := false
var movement_animation_time := 0.0
var trail_time_left := 0.0


class AttackTelegraph extends Node2D:
	var radius := 0.0
	var duration := 0.0
	var elapsed := 0.0

	func _init(attack_radius: float, attack_duration: float) -> void:
		radius = attack_radius
		duration = attack_duration

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var pulse: float = 0.45 + sin(elapsed * 18.0) * 0.2
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.08, 0.08, 0.14 + pulse * 0.2))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.18, 0.18, 0.55 + pulse * 0.35), 2.0)


class ChargeTelegraph extends Node2D:
	var direction := Vector2.ZERO
	var length := 0.0
	var duration := 0.0
	var elapsed := 0.0

	func _init(charge_direction: Vector2, charge_length: float, charge_duration: float) -> void:
		direction = charge_direction
		length = charge_length
		duration = charge_duration

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var pulse: float = 0.35 + sin(elapsed * 20.0) * 0.2
		var endpoint: Vector2 = direction * length
		draw_line(Vector2.ZERO, endpoint, Color(1.0, 0.08, 0.08, 0.3 + pulse * 0.3), 7.0)
		draw_circle(endpoint, CHARGE_HIT_RADIUS, Color(1.0, 0.12, 0.12, 0.16 + pulse * 0.18))


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
	if performing_ability:
		return

	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	animate_movement(delta)
	trail_time_left -= delta
	if trail_time_left <= 0.0:
		leave_trail_puddle()
		trail_time_left = TRAIL_INTERVAL
	slime_spray_time_left -= delta
	ability_time_left -= delta
	corrosive_spray_time_left -= delta

	if slime_spray_time_left <= 0.0:
		perform_slime_spray()
		slime_spray_time_left = SLIME_SPRAY_COOLDOWN
		ability_time_left = 4.0
	elif ability_time_left <= 0.0:
		match randi_range(0, 2):
			0:
				perform_teleport()
			1:
				perform_triple_jump()
			2:
				perform_charge()
	elif corrosive_spray_time_left <= 0.0:
		perform_corrosive_spray()
		corrosive_spray_time_left = CORROSIVE_SPRAY_COOLDOWN


func perform_slime_spray() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var entities: Node2D = get_tree().get_first_node_in_group("entities_layer") as Node2D
	if player == null or entities == null:
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	for index: int in MINION_COUNT:
		var spread_angle: float = deg_to_rad(-36.0 + index * 8.0)
		var spray_direction: Vector2 = direction.rotated(spread_angle)
		var minion: Node2D = basic_enemy_scene.instantiate() as Node2D
		entities.add_child(minion)
		minion.global_position = global_position + spray_direction * 36.0
		var minion_velocity: VelocityComponent = minion.get_node_or_null("VelocityComponent") as VelocityComponent
		if minion_velocity != null:
			minion_velocity.velocity = spray_direction * 180.0


func perform_corrosive_spray() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var foreground: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	for index: int in CORROSIVE_PUDDLE_COUNT:
		var spray_direction: Vector2 = direction.rotated(-0.24 + index * 0.24)
		var destination: Vector2 = global_position + spray_direction * (95.0 + index * 12.0)
		var puddle: CorrosivePuddle = corrosive_puddle_scene.instantiate() as CorrosivePuddle
		foreground.add_child(puddle)
		puddle.global_position = global_position
		puddle.launch_to(destination)


func leave_trail_puddle() -> void:
	var foreground: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var puddle: CorrosivePuddle = corrosive_puddle_scene.instantiate() as CorrosivePuddle
	puddle.configure(TRAIL_PUDDLE_LIFETIME, TRAIL_PUDDLE_DAMAGE, TRAIL_SLOW_PERCENT, TRAIL_SLOW_DURATION, 0.8)
	foreground.add_child(puddle)
	puddle.global_position = global_position
	puddle.scale = Vector2.ONE
	puddle.activate()


func perform_teleport() -> void:
	performing_ability = true
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var windup_tween: Tween = create_tween()
		windup_tween.tween_property(visuals, "scale", Vector2(1.18, 0.82), 0.16)
		await windup_tween.finished
		var destination: Vector2 = player.global_position
		create_telegraph(destination, TELEPORT_DAMAGE_RADIUS, TELEPORT_WARNING_DURATION)
		var vanish_tween: Tween = create_tween()
		vanish_tween.set_parallel(true)
		vanish_tween.tween_property(visuals, "modulate:a", 0.12, TELEPORT_WARNING_DURATION)
		vanish_tween.tween_property(visuals, "scale", Vector2(0.55, 1.35), TELEPORT_WARNING_DURATION)
		await vanish_tween.finished
		global_position = destination
		visuals.modulate.a = 1.0
		visuals.scale = Vector2(1.35, 0.68)
		deal_area_damage(destination, TELEPORT_DAMAGE_RADIUS, TELEPORT_DAMAGE)
		var impact_tween: Tween = create_tween()
		impact_tween.tween_property(visuals, "scale", Vector2.ONE, 0.14)
		await impact_tween.finished
	ability_time_left = 6.0
	performing_ability = false


func perform_triple_jump() -> void:
	performing_ability = true
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	for _jump_index: int in JUMP_COUNT:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			break
		var destination: Vector2 = player.global_position
		create_telegraph(destination, JUMP_DAMAGE_RADIUS, JUMP_WARNING_DURATION)
		var windup_tween: Tween = create_tween()
		windup_tween.tween_property(visuals, "scale", Vector2(1.22, 0.76), 0.14)
		await get_tree().create_timer(JUMP_WARNING_DURATION).timeout
		var tween: Tween = create_tween()
		tween.tween_property(self, "global_position", destination, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished
		visuals.scale = Vector2(1.4, 0.64)
		deal_area_damage(destination, JUMP_DAMAGE_RADIUS, JUMP_DAMAGE)
		var impact_tween: Tween = create_tween()
		impact_tween.tween_property(visuals, "scale", Vector2.ONE, 0.14)
		await impact_tween.finished
		await get_tree().create_timer(0.08).timeout
	ability_time_left = 6.0
	performing_ability = false


func perform_charge() -> void:
	performing_ability = true
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var distance: float = minf(global_position.distance_to(player.global_position) + 28.0, CHARGE_MAX_DISTANCE)
		create_charge_telegraph(global_position, direction, distance, CHARGE_WARNING_DURATION)
		var windup_tween: Tween = create_tween()
		windup_tween.tween_property(visuals, "scale", Vector2(0.72, 1.28), 0.18)
		await get_tree().create_timer(CHARGE_WARNING_DURATION).timeout
		visuals.scale = Vector2(1.4, 0.7)
		var charge_time := 0.0
		var charge_duration: float = distance / CHARGE_SPEED
		var charge_trail_time := 0.0
		while charge_time < charge_duration:
			await get_tree().process_frame
			var frame_delta: float = get_process_delta_time()
			charge_time += frame_delta
			velocity = direction * CHARGE_SPEED
			move_and_slide()
			charge_trail_time -= frame_delta
			if charge_trail_time <= 0.0:
				leave_trail_puddle()
				charge_trail_time = CHARGE_TRAIL_INTERVAL
			if player.global_position.distance_squared_to(global_position) <= CHARGE_HIT_RADIUS * CHARGE_HIT_RADIUS:
				damage_and_knockback_player(player, direction)
				break
		velocity = Vector2.ZERO
		velocity_component.velocity = Vector2.ZERO
		visuals.scale = Vector2(1.45, 0.65)
		var impact_tween: Tween = create_tween()
		impact_tween.tween_property(visuals, "scale", Vector2.ONE, 0.16)
		await impact_tween.finished
	ability_time_left = 6.0
	performing_ability = false


func create_telegraph(destination: Vector2, radius: float, duration: float) -> void:
	var foreground: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var telegraph: AttackTelegraph = AttackTelegraph.new(radius, duration)
	foreground.add_child(telegraph)
	telegraph.global_position = destination


func create_charge_telegraph(start: Vector2, direction: Vector2, length: float, duration: float) -> void:
	var foreground: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var telegraph: ChargeTelegraph = ChargeTelegraph.new(direction, length, duration)
	foreground.add_child(telegraph)
	telegraph.global_position = start


func deal_area_damage(center: Vector2, radius: float, damage: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.global_position.distance_to(center) > radius:
		return
	var player_health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health != null:
		player_health.damage(damage)


func damage_and_knockback_player(player: Node2D, direction: Vector2) -> void:
	var player_health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health != null:
		player_health.damage(CHARGE_DAMAGE)
	var player_velocity: VelocityComponent = player.get_node_or_null("VelocityComponent") as VelocityComponent
	if player_velocity != null:
		player_velocity.velocity = direction * CHARGE_KNOCKBACK_SPEED
	player.global_position += direction * CHARGE_KNOCKBACK_DISTANCE


func animate_movement(delta: float) -> void:
	var speed: float = velocity_component.velocity.length()
	if speed < 1.0:
		visuals.position = visuals.position.lerp(Vector2.ZERO, minf(delta * 10.0, 1.0))
		visuals.scale = visuals.scale.lerp(Vector2.ONE, minf(delta * 10.0, 1.0))
		return
	movement_animation_time += delta * (8.0 + speed * 0.06)
	var bounce: float = sin(movement_animation_time)
	visuals.position.y = -absf(bounce) * 3.0
	visuals.scale = Vector2(1.0 + bounce * 0.08, 1.0 - bounce * 0.08)


func update_health_bar() -> void:
	health_bar.value = health_component.get_health_percent()
