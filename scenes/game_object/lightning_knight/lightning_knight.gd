extends CharacterBody2D

const LIGHTNING_COOLDOWN := 10.0
const DASH_COOLDOWN := 7.0
const SWORD_COOLDOWN := 4.0
const WARNING_TIME := 0.3
const LIGHTNING_INTERVAL := 0.2
const LIGHTNING_COUNT := 5
const DASH_COUNT := 3
const DASH_SPEED := 520.0
const DASH_DAMAGE := 55.0
const SWORD_DAMAGE := 48.0
const DASH_HIT_RADIUS := 23.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite2D

var lightning_time_left := 2.0
var dash_time_left := 4.0
var sword_time_left := 1.0
var attacking := false
var attack_cancelled := false
var walk_time := 0.0


func _ready() -> void:
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


class WarningCircle extends Node2D:
	var radius: float
	var duration: float
	var elapsed := 0.0
	var color: Color

	func _init(new_radius: float, new_duration: float, new_color: Color) -> void:
		radius = new_radius
		duration = new_duration
		color = new_color

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.45 + sin(elapsed * 26.0) * 0.25
		draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.12 + pulse * 0.18))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.45 + pulse * 0.45), 2.0)


class DashWarning extends Node2D:
	var direction: Vector2
	var length: float
	var duration: float
	var elapsed := 0.0

	func _init(new_direction: Vector2, new_length: float, new_duration: float) -> void:
		direction = new_direction
		length = new_length
		duration = new_duration

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var side := direction.orthogonal()
		var alpha := 0.35 + sin(elapsed * 30.0) * 0.2
		draw_line(Vector2.ZERO, direction * length, Color(0.2, 0.9, 1.0, alpha), 5.0)
		for offset in [-11.0, 11.0]:
			draw_line(side * offset, direction * length + side * offset, Color(0.75, 0.95, 1.0, alpha * 0.8), 1.5)
		for distance in range(24, int(length), 28):
			draw_arc(direction * distance + side * sin(elapsed * 18.0 + distance) * 7.0, 7.0, 0.0, TAU, 10, Color(0.82, 0.96, 1.0, alpha), 1.2)


class LightningStrike extends Node2D:
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= 0.18:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var points := PackedVector2Array([Vector2(-6, -150), Vector2(8, -105), Vector2(-5, -66), Vector2(9, -27), Vector2(0, 0)])
		draw_polyline(points, Color(0.72, 0.95, 1.0, 1.0 - elapsed * 4.0), 5.0)
		draw_circle(Vector2.ZERO, 20.0 - elapsed * 60.0, Color(0.2, 0.75, 1.0, 0.4))


class ThrownGreatsword extends Node2D:
	const DAMAGE := 48.0
	var direction := Vector2.RIGHT
	var distance_left := 0.0
	var hit_player := false

	func launch(new_direction: Vector2, distance: float) -> void:
		direction = new_direction
		distance_left = distance
		rotation = direction.angle()

	func _process(delta: float) -> void:
		var step := minf(680.0 * delta, distance_left)
		global_position += direction * step
		distance_left -= step
		rotation += delta * 14.0
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if not hit_player and player != null and global_position.distance_squared_to(player.global_position) <= 18.0 * 18.0:
			hit_player = true
			var health := player.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(DAMAGE)
			var velocity_component := player.get_node_or_null("VelocityComponent") as VelocityComponent
			if velocity_component != null:
				velocity_component.apply_knockback(direction, 310.0, 0.22)
			queue_free()
		elif distance_left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var blade := PackedVector2Array([Vector2(-8, -29), Vector2(7, -29), Vector2(12, 19), Vector2(0, 34), Vector2(-12, 19)])
		draw_colored_polygon(blade, Color(0.1, 0.22, 0.35))
		draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[4], blade[0]]), Color(0.36, 0.92, 1.0), 2.4)
		draw_line(Vector2(-13, 16), Vector2(13, 16), Color(0.75, 0.9, 1.0), 3.0)
		draw_line(Vector2(0, -29), Vector2(0, 23), Color(0.3, 0.8, 1.0, 0.8), 1.4)


func _process(delta: float) -> void:
	if attacking:
		return
	lightning_time_left -= delta
	dash_time_left -= delta
	sword_time_left -= delta
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	animate_walk(delta)
	var available: Array[Callable] = []
	if lightning_time_left <= 0.0:
		available.append(cast_divine_punishment)
	if dash_time_left <= 0.0:
		available.append(dash)
	if sword_time_left <= 0.0:
		available.append(throw_greatsword)
	if not available.is_empty():
		available.pick_random().call()


func cast_divine_punishment() -> void:
	attacking = true
	attack_cancelled = false
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	sprite.pause()
	for bolt_index in LIGHTNING_COUNT:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			break
		var target := player.global_position
		create_warning(target, 22.0, WARNING_TIME, Color(0.3, 0.8, 1.0))
		await get_tree().create_timer(WARNING_TIME).timeout
		if is_attack_interrupted():
			break
		strike(target)
		if bolt_index < LIGHTNING_COUNT - 1:
			await get_tree().create_timer(LIGHTNING_INTERVAL).timeout
			if is_attack_interrupted():
				break
	lightning_time_left = LIGHTNING_COOLDOWN
	sprite.play()
	visuals.scale = Vector2.ONE
	attacking = false


func dash() -> void:
	attacking = true
	attack_cancelled = false
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	var previous_collision_mask := collision_mask
	collision_mask = 1 # Dash through enemies; terrain remains the only stopping point.
	for _dash_index in DASH_COUNT:
		if is_attack_interrupted():
			break
		var hit_player := false
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			break
		var direction := (player.global_position - global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var facing: float = 1.0 if direction.x >= 0.0 else -1.0
		var distance := global_position.distance_to(player.global_position) * 2.0
		create_dash_warning(direction, distance)
		var windup := create_tween()
		windup.tween_property(visuals, "scale", Vector2(0.78 * facing, 1.18), WARNING_TIME)
		await get_tree().create_timer(WARNING_TIME).timeout
		if is_attack_interrupted():
			break
		visuals.scale = Vector2(1.18 * facing, 0.82)
		var travelled := 0.0
		while travelled < distance:
			await get_tree().process_frame
			if is_attack_interrupted():
				break
			var step := minf(DASH_SPEED * get_process_delta_time(), distance - travelled)
			velocity = direction * DASH_SPEED
			move_and_slide()
			if is_on_wall():
				break
			travelled += step
			animate_walk(get_process_delta_time(), 3.5)
			hit_player = knockback_dash_targets(direction, hit_player)
	collision_mask = previous_collision_mask
	velocity = Vector2.ZERO
	velocity_component.velocity = Vector2.ZERO
	visuals.scale = Vector2(sign(visuals.scale.x), 1.0)
	dash_time_left = DASH_COOLDOWN
	attacking = false


func throw_greatsword() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	attacking = true
	attack_cancelled = false
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	var direction := (player.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	create_dash_warning(direction, global_position.distance_to(player.global_position))
	var windup := create_tween()
	windup.tween_property(visuals, "rotation", -0.14, WARNING_TIME)
	await get_tree().create_timer(WARNING_TIME).timeout
	if is_attack_interrupted():
		visuals.rotation = 0.0
		attacking = false
		return
	visuals.rotation = 0.0
	var sword := ThrownGreatsword.new()
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		foreground.add_child(sword)
		sword.global_position = global_position + direction * 32.0
		sword.launch(direction, 360.0)
	sword_time_left = SWORD_COOLDOWN
	attacking = false


func strike(position: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var lightning := LightningStrike.new()
		foreground.add_child(lightning)
		lightning.global_position = position
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.global_position.distance_squared_to(position) > 24.0 * 24.0:
		return
	var player_health := player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health != null:
		player_health.damage(player_health.max_health * 0.1)
	if randf() < 0.5:
		var player_velocity := player.get_node_or_null("VelocityComponent") as VelocityComponent
		if player_velocity != null:
			player_velocity.apply_stun(0.5)


func knockback_dash_targets(direction: Vector2, hit_player: bool) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not enemy is Node2D:
			continue
		var enemy_body := enemy as Node2D
		if global_position.distance_squared_to(enemy_body.global_position) > DASH_HIT_RADIUS * DASH_HIT_RADIUS:
			continue
		var enemy_velocity := enemy_body.get_node_or_null("VelocityComponent") as VelocityComponent
		if enemy_velocity != null:
			enemy_velocity.apply_knockback(direction, 330.0, 0.18)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not hit_player and player != null and global_position.distance_squared_to(player.global_position) <= DASH_HIT_RADIUS * DASH_HIT_RADIUS:
		var player_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if player_health != null:
			player_health.damage(DASH_DAMAGE)
		var player_velocity := player.get_node_or_null("VelocityComponent") as VelocityComponent
		if player_velocity != null:
			player_velocity.apply_knockback(direction, 390.0, 0.28)
		return true
	return hit_player


func create_warning(position: Vector2, radius: float, duration: float, color: Color) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var warning := WarningCircle.new(radius, duration, color)
	foreground.add_child(warning)
	warning.global_position = position


func create_dash_warning(direction: Vector2, length: float) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var warning := DashWarning.new(direction, length, WARNING_TIME)
	foreground.add_child(warning)
	warning.global_position = global_position


func is_attack_interrupted() -> bool:
	return attack_cancelled or get_tree().paused


func on_ability_upgrade_added(_upgrade: AbilityUpgrade, _current_upgrades: Dictionary) -> void:
	attack_cancelled = attacking


func animate_walk(delta: float, speed_multiplier: float = 1.0) -> void:
	walk_time += delta * speed_multiplier
	sprite.speed_scale = speed_multiplier
	visuals.position.y = sin(walk_time * 2.0) * 0.8
	if velocity.x != 0.0:
		visuals.scale.x = absf(visuals.scale.x) * sign(velocity.x)
