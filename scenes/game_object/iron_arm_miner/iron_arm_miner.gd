extends CharacterBody2D

const RUN_TEXTURE := preload("res://assets/enemies/iron_arm_miner_run.png")
const SLAM_TEXTURE := preload("res://assets/enemies/iron_arm_miner_slam.png")
const MELEE_TEXTURE := preload("res://assets/enemies/iron_arm_miner_melee.png")
const THROW_TEXTURE := preload("res://assets/enemies/iron_arm_miner_throw.png")
const DASH_TEXTURE := preload("res://assets/enemies/iron_arm_miner_dash.png")
const IRON_GOLEM_SCENE := preload("res://scenes/game_object/iron_golem/iron_golem.tscn")
const FRAME_RATE := 8.0
const RUN_X := [13, 324, 643, 946, 1286, 1598, 1905, 2220]
const RUN_WIDTHS := [303, 295, 283, 322, 306, 301, 314, 323]
const RUN_GROUND := [321, 321, 321, 321, 329, 329, 329, 329]
const SQUARE_COLUMNS := [0, 314, 627, 941, 1254]
const SQUARE_ROWS := [220, 640, 1060]
const SQUARE_GROUND := [610, 610, 610, 610, 1000, 1000, 1000, 1000]
const WIDE_COLUMNS := [0, 384, 768, 1152, 1536]
const SLAM_ROWS := [100, 620, 1024]
const SLAM_GROUND := [560, 560, 560, 560, 980, 980, 980, 980]
const DASH_ROWS := [100, 500, 900]
const DASH_GROUND := [430, 430, 430, 430, 850, 850, 850, 850]
const MELEE_RANGE := 92.0
const SLAM_RADIUS := 135.0
const DASH_SPEED := 520.0
const DASH_DURATION := 0.45
const DASH_HIT_RADIUS := 42.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var animation_time := 0.0
var ability_cooldown := 1.5
var summon_cooldown := 0.0
var busy := false


class WarningCircle extends Node2D:
	var radius: float
	var duration: float
	var elapsed := 0.0

	func _init(new_radius: float, new_duration: float) -> void:
		radius = new_radius
		duration = new_duration

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var progress := minf(elapsed / duration, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(0.55, 0.0, 0.0, 0.14))
		draw_circle(Vector2.ZERO, radius * progress, Color(1.0, 0.06, 0.03, 0.22))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.15, 0.08, 0.9), 2.5)


class DashWarning extends Node2D:
	var direction: Vector2
	var elapsed := 0.0

	func _init(new_direction: Vector2) -> void:
		direction = new_direction

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= 0.35:
			queue_free()

	func _draw() -> void:
		var alpha := 0.35 + sin(elapsed * 28.0) * 0.2
		draw_line(Vector2.ZERO, direction * DASH_SPEED * DASH_DURATION, Color(1.0, 0.08, 0.04, alpha), DASH_HIT_RADIUS * 1.4)
		draw_line(Vector2.ZERO, direction * DASH_SPEED * DASH_DURATION, Color(1.0, 0.65, 0.3, 0.9), 2.0)


class Shockwave extends Node2D:
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= 0.45:
			queue_free()

	func _draw() -> void:
		var progress := elapsed / 0.45
		var radius := lerpf(18.0, SLAM_RADIUS, progress)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.55, 0.18, 1.0 - progress), 7.0 - progress * 4.0)
		draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 40, Color(0.55, 0.28, 0.12, 0.8 - progress * 0.7), 3.0)
		for index in 12:
			var direction := Vector2.RIGHT.rotated(index * TAU / 12.0)
			draw_line(direction * radius * 0.72, direction * radius, Color(0.38, 0.2, 0.1, 1.0 - progress), 3.0)


class RockProjectile extends Node2D:
	const TEXTURE := preload("res://assets/enemies/stone_slime_walk.png")
	const COLUMNS := [0, 328, 631, 933, 1254]
	const ROWS := [320, 640, 960]

	var direction := Vector2.RIGHT
	var time_left := 4.0
	var animation_time := 0.0
	var sprite := Sprite2D.new()

	func _init() -> void:
		sprite.texture = TEXTURE
		sprite.region_enabled = true
		sprite.scale = Vector2(0.12, 0.12)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		show_frame(0)

	func _process(delta: float) -> void:
		global_position += direction * 240.0 * delta
		animation_time += delta
		show_frame(int(animation_time * 24.0) % 8)
		time_left -= delta
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and global_position.distance_to(player.global_position) <= 18.0:
			var health := player.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(48.0, "铁臂矿工的碎石")
			queue_free()
		elif time_left <= 0.0:
			queue_free()

	func show_frame(frame: int) -> void:
		var column := frame % 4
		var row := floori(frame / 4.0)
		sprite.region_rect = Rect2(COLUMNS[column], ROWS[row], COLUMNS[column + 1] - COLUMNS[column], ROWS[row + 1] - ROWS[row])


func _ready() -> void:
	show_run_frame(0)


func _process(delta: float) -> void:
	if busy:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var phase := get_phase()
	velocity_component.max_speed = 105 if phase == 3 else 46
	var distance := global_position.distance_to(player.global_position)
	if distance > MELEE_RANGE * 0.75:
		velocity_component.accelerate_to_player()
	else:
		velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity_component.move(self)
	animation_time += delta
	show_run_frame(int(animation_time * FRAME_RATE) % 8)
	if velocity.x != 0.0:
		visuals.scale.x = -absf(visuals.scale.x) * sign(velocity.x)
	ability_cooldown -= delta
	summon_cooldown -= delta
	if ability_cooldown > 0.0:
		return
	if phase == 1 and distance > SLAM_RADIUS:
		return
	var abilities: Array[Callable] = [ground_slam]
	if distance <= MELEE_RANGE:
		abilities.append(melee_attack)
	if phase >= 2:
		abilities.append(throw_rocks)
		if summon_cooldown <= 0.0:
			abilities.append(summon_golems)
	abilities.append(dash_attack)
	abilities.pick_random().call()


func get_phase() -> int:
	var health_percent := health_component.get_health_percent()
	return 1 if health_percent > 0.7 else 2 if health_percent >= 0.3 else 3


func ground_slam() -> void:
	begin_action()
	var repetitions := 3 if get_phase() == 3 else 1
	var duration := 0.55 if get_phase() == 3 else 0.9
	for index in repetitions:
		create_warning_circle(global_position, SLAM_RADIUS, duration)
		await play_sheet(SLAM_TEXTURE, duration, WIDE_COLUMNS, SLAM_ROWS, SLAM_GROUND)
		spawn_shockwave()
		damage_player_in_radius(global_position, SLAM_RADIUS, 72.0)
		if index < repetitions - 1:
			await get_tree().create_timer(0.15).timeout
	finish_action()


func melee_attack() -> void:
	begin_action()
	create_warning_circle(global_position, MELEE_RANGE, 0.7)
	await play_sheet(MELEE_TEXTURE, 0.7, SQUARE_COLUMNS, SQUARE_ROWS, SQUARE_GROUND)
	damage_player_in_radius(global_position, MELEE_RANGE, 58.0)
	finish_action()


func throw_rocks() -> void:
	begin_action()
	for index in 4:
		await play_sheet(THROW_TEXTURE, 0.34, SQUARE_COLUMNS, SQUARE_ROWS, SQUARE_GROUND)
		spawn_rock()
		if index < 3:
			await get_tree().create_timer(0.12).timeout
	finish_action()


func summon_golems() -> void:
	begin_action()
	var entities := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities != null:
		for index in 5:
			var golem := IRON_GOLEM_SCENE.instantiate() as Node2D
			entities.add_child(golem)
			golem.global_position = global_position + Vector2.RIGHT.rotated(index * TAU / 5.0) * 78.0
	summon_cooldown = 14.0
	finish_action()


func dash_attack() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	begin_action()
	var direction := global_position.direction_to(player.global_position)
	create_dash_warning(direction)
	await get_tree().create_timer(0.35).timeout
	var previous_mask := collision_mask
	collision_mask = 1
	var elapsed := 0.0
	var hit := false
	while elapsed < DASH_DURATION:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		elapsed += delta
		show_sheet(DASH_TEXTURE, mini(int(elapsed / DASH_DURATION * 8.0), 7), WIDE_COLUMNS, DASH_ROWS, DASH_GROUND)
		velocity = direction * DASH_SPEED
		move_and_slide()
		if not hit and player.global_position.distance_to(global_position) <= DASH_HIT_RADIUS:
			damage_player_in_radius(global_position, DASH_HIT_RADIUS, 85.0)
			hit = true
		if is_on_wall():
			break
	collision_mask = previous_mask
	finish_action()


func begin_action() -> void:
	busy = true
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity = Vector2.ZERO


func finish_action() -> void:
	busy = false
	velocity = Vector2.ZERO
	velocity_component.velocity = Vector2.ZERO
	ability_cooldown = 0.7 if get_phase() == 3 else 1.6
	animation_time = 0.0


func play_sheet(texture: Texture2D, duration: float, columns: Array, rows: Array, ground: Array) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		show_sheet(texture, mini(int(elapsed / duration * 8.0), 7), columns, rows, ground)


func show_run_frame(frame: int) -> void:
	var rect := Rect2(RUN_X[frame], 0, RUN_WIDTHS[frame], 345)
	sprite.texture = RUN_TEXTURE
	sprite.region_rect = rect
	sprite.position.y = -6.0 + (rect.get_center().y - RUN_GROUND[frame]) * sprite.scale.y


func show_sheet(texture: Texture2D, frame: int, columns: Array, rows: Array, ground: Array) -> void:
	var column := frame % 4
	var row := floori(frame / 4.0)
	var rect := Rect2(columns[column], rows[row], columns[column + 1] - columns[column], rows[row + 1] - rows[row])
	sprite.texture = texture
	sprite.region_rect = rect
	sprite.position.y = -6.0 + (rect.get_center().y - ground[frame]) * sprite.scale.y


func create_warning_circle(center: Vector2, radius: float, duration: float) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var warning := WarningCircle.new(radius, duration)
		foreground.add_child(warning)
		warning.global_position = center


func create_dash_warning(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var warning := DashWarning.new(direction)
		foreground.add_child(warning)
		warning.global_position = global_position


func spawn_shockwave() -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var shockwave := Shockwave.new()
		foreground.add_child(shockwave)
		shockwave.global_position = global_position


func spawn_rock() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player != null and foreground != null:
		var rock := RockProjectile.new()
		rock.direction = global_position.direction_to(player.global_position)
		foreground.add_child(rock)
		rock.global_position = global_position


func damage_player_in_radius(center: Vector2, radius: float, damage: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.global_position.distance_to(center) > radius:
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.damage(damage, "铁臂矿工")
