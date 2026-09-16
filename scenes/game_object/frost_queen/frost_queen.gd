extends CharacterBody2D

const FRAME_COLUMNS := [0, 384, 768, 1152, 1536]
const FRAME_ROWS := [0, 512, 1024]
const FRAME_RATE := 9.0
const WALK_TEXTURE := preload("res://assets/enemies/frost_queen.png")
const CAST_TEXTURE := preload("res://assets/enemies/frost_queen_cast.png")
const BLIZZARD_TEXTURE := preload("res://assets/enemies/frost_queen_blizzard.png")
const TELEPORT_TEXTURE := preload("res://assets/enemies/frost_queen_teleport.png")
const WISP_SCENE := preload("res://scenes/game_object/frost_wisp/frost_wisp.tscn")

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var busy := false
var cooldown := 1.2
var animation_time := 0.0


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
		var pulse := 0.72 + sin(elapsed * 18.0) * 0.18
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.45, 0.88, 1.0, 0.35), 1.0)
		draw_arc(Vector2.ZERO, radius - 3.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 64, Color(1.0, 0.18, 0.12, pulse), 3.0)
		draw_arc(Vector2.ZERO, radius + 4.0, elapsed * 2.0, elapsed * 2.0 + PI, 32, Color(0.75, 0.96, 1.0, 0.7), 1.5)
		for index in 4:
			var angle := elapsed * 1.4 + index * PI * 0.5
			var center := Vector2.RIGHT.rotated(angle) * (radius + 8.0)
			var axis := Vector2.RIGHT.rotated(angle) * 5.0
			var cross := axis.rotated(PI * 0.5) * 0.65
			draw_line(center - axis, center + axis, Color(0.82, 0.97, 1.0, 0.9), 1.5)
			draw_line(center - cross, center + cross, Color(0.82, 0.97, 1.0, 0.9), 1.5)


class IceShard extends Node2D:
	var direction := Vector2.RIGHT
	var time_left := 3.0

	func _process(delta: float) -> void:
		global_position += direction * 265.0 * delta
		rotation = direction.angle()
		time_left -= delta
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and global_position.distance_squared_to(player.global_position) <= 13.0 * 13.0:
			var health := player.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(46.0, "冰霜女王的冰锥")
			var movement := player.get_node_or_null("VelocityComponent") as VelocityComponent
			if movement != null:
				movement.apply_slow(0.25, 0.8)
			queue_free()
		elif time_left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(-7, 0), Vector2(-18, 0), Color(0.2, 0.7, 1.0, 0.25), 5.0)
		draw_line(Vector2(-5, 0), Vector2(-15, 0), Color(0.75, 0.96, 1.0, 0.7), 1.5)
		var shard := PackedVector2Array([Vector2(13, 0), Vector2(-2, -5), Vector2(-10, 0), Vector2(-2, 5)])
		draw_colored_polygon(shard, Color(0.14, 0.62, 0.95, 0.95))
		draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(0.8, 0.97, 1.0), 1.25)
		draw_line(Vector2(8, 0), Vector2(-1, -2), Color.WHITE, 1.0)


class IceWall extends StaticBody2D:
	var time_left := 5.0

	func _init(angle: float) -> void:
		rotation = angle
		collision_layer = 1
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(92, 16)
		shape.shape = rectangle
		add_child(shape)

	func _process(delta: float) -> void:
		time_left -= delta
		modulate.a = minf(time_left, 1.0)
		if time_left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_ellipse_shadow()
		var wall := PackedVector2Array([
			Vector2(-46, 7), Vector2(-42, -4), Vector2(-33, -17), Vector2(-25, -6),
			Vector2(-16, -24), Vector2(-6, -8), Vector2(5, -29), Vector2(14, -9),
			Vector2(25, -21), Vector2(33, -6), Vector2(42, -15), Vector2(46, 7)
		])
		draw_colored_polygon(wall, Color(0.2, 0.7, 0.93, 0.92))
		draw_polyline(PackedVector2Array([wall[0], wall[1], wall[2], wall[3], wall[4], wall[5], wall[6], wall[7], wall[8], wall[9], wall[10], wall[11]]), Color(0.8, 0.97, 1.0), 1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(-33, -15), Vector2(-25, -6), Vector2(-16, -22), Vector2(-18, 4)]), Color(0.55, 0.9, 1.0, 0.7))
		draw_colored_polygon(PackedVector2Array([Vector2(5, -27), Vector2(14, -8), Vector2(7, 5), Vector2(-5, 4)]), Color(0.65, 0.94, 1.0, 0.78))
		draw_colored_polygon(PackedVector2Array([Vector2(25, -19), Vector2(33, -6), Vector2(40, 5), Vector2(20, 4)]), Color(0.38, 0.82, 1.0, 0.72))

	func draw_ellipse_shadow() -> void:
		draw_arc(Vector2(0, 7), 43.0, 0.08, PI - 0.08, 24, Color(0.06, 0.28, 0.48, 0.45), 5.0)


class IceBurstEffect extends Node2D:
	var max_radius: float
	var elapsed := 0.0

	func _init(new_radius: float) -> void:
		max_radius = new_radius

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= 0.48:
			queue_free()

	func _draw() -> void:
		var progress := minf(elapsed / 0.48, 1.0)
		var radius := lerpf(8.0, max_radius, 1.0 - pow(1.0 - progress, 3.0))
		var alpha := 1.0 - progress
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.58, 0.92, 1.0, alpha), 3.0)
		draw_arc(Vector2.ZERO, radius * 0.72, elapsed * 5.0, elapsed * 5.0 + PI * 1.4, 32, Color(1.0, 1.0, 1.0, alpha * 0.75), 1.5)
		for index in 12:
			var direction := Vector2.RIGHT.rotated(index * TAU / 12.0 + elapsed * 0.8)
			var center := direction * radius
			var side := direction.orthogonal() * 2.5
			var crystal := PackedVector2Array([center + direction * 7.0, center + side, center - direction * 5.0, center - side])
			draw_colored_polygon(crystal, Color(0.34, 0.82, 1.0, alpha))


class Blizzard extends Node2D:
	var elapsed := 0.0
	var damage_time := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		damage_time -= delta
		var radius := lerpf(145.0, 55.0, minf(elapsed / 4.0, 1.0))
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and damage_time <= 0.0 and global_position.distance_to(player.global_position) > radius:
			var health := player.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(18.0, "冰霜女王的暴风雪")
			damage_time = 0.45
		queue_redraw()
		if elapsed >= 4.0:
			queue_free()

	func _draw() -> void:
		var radius := lerpf(145.0, 55.0, minf(elapsed / 4.0, 1.0))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(0.86, 0.98, 1.0, 0.95), 2.5)
		draw_arc(Vector2.ZERO, radius + 5.0, elapsed * 1.6, elapsed * 1.6 + PI * 1.3, 48, Color(0.35, 0.8, 1.0, 0.65), 2.0)
		draw_arc(Vector2.ZERO, radius + 12.0, -elapsed * 1.1, -elapsed * 1.1 + PI, 40, Color(0.7, 0.94, 1.0, 0.38), 1.5)
		for index in 24:
			var angle := index * TAU / 24.0 + elapsed * (1.2 + float(index % 3) * 0.25)
			var point := Vector2.RIGHT.rotated(angle) * (radius + 18.0 + sin(index * 2.4) * 13.0)
			var arm := Vector2(3.5, 0).rotated(angle + index)
			draw_line(point - arm, point + arm, Color(0.78, 0.96, 1.0, 0.72), 1.2)
			draw_line(point - arm.rotated(PI * 0.5), point + arm.rotated(PI * 0.5), Color(0.78, 0.96, 1.0, 0.72), 1.2)


func _ready() -> void:
	show_frame(0)


func _process(delta: float) -> void:
	animation_time += delta
	show_frame(mini(int(animation_time * FRAME_RATE), 7) if busy else int(animation_time * FRAME_RATE) % 8)
	if busy:
		return
	var phase := get_phase()
	velocity_component.max_speed = 82 if phase == 3 else 46
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	cooldown -= delta
	if cooldown > 0.0:
		return
	var abilities: Array[Callable] = [ice_shard_fan, frost_burst]
	if phase >= 2:
		abilities.append(create_ice_walls)
		abilities.append(summon_wisps)
	if phase == 3:
		abilities.append(start_blizzard)
		abilities.append(teleport_blast)
	abilities.pick_random().call()


func get_phase() -> int:
	var percent := health_component.get_health_percent()
	return 1 if percent > 0.7 else 2 if percent >= 0.3 else 3


func ice_shard_fan() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	begin_action()
	create_warning(global_position, 46.0, 0.45)
	await get_tree().create_timer(0.45).timeout
	var base_direction := global_position.direction_to(player.global_position)
	for index in 7:
		spawn_shard(base_direction.rotated(-0.54 + index * 0.18))
	await get_tree().create_timer(0.35).timeout
	finish_action()


func frost_burst() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	begin_action()
	var target := player.global_position
	create_warning(target, 58.0, 0.7)
	await get_tree().create_timer(0.7).timeout
	damage_player_in_radius(target, 58.0, 68.0)
	spawn_ice_burst(target, 58.0)
	await get_tree().create_timer(0.2).timeout
	finish_action()


func create_ice_walls() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	begin_action()
	var angle := randf_range(0.0, TAU)
	for offset in [-72.0, 0.0, 72.0]:
		create_warning(player.global_position + Vector2.RIGHT.rotated(angle) * offset, 24.0, 0.55)
	await get_tree().create_timer(0.55).timeout
	for offset in [-72.0, 0.0, 72.0]:
		var wall := IceWall.new(angle + PI * 0.5)
		foreground.add_child(wall)
		wall.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * offset
	await get_tree().create_timer(0.3).timeout
	finish_action()


func summon_wisps() -> void:
	var entities := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities == null:
		return
	begin_action()
	await get_tree().create_timer(0.45).timeout
	for index in 4:
		var wisp := WISP_SCENE.instantiate() as Node2D
		entities.add_child(wisp)
		wisp.global_position = global_position + Vector2.RIGHT.rotated(index * TAU / 4.0) * 76.0
	spawn_ice_burst(global_position, 82.0)
	await get_tree().create_timer(0.4).timeout
	finish_action()


func start_blizzard() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	begin_action(BLIZZARD_TEXTURE)
	await get_tree().create_timer(0.55).timeout
	var storm := Blizzard.new()
	foreground.add_child(storm)
	storm.global_position = player.global_position
	await get_tree().create_timer(0.35).timeout
	finish_action()


func teleport_blast() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	begin_action(TELEPORT_TEXTURE)
	var target := player.global_position
	create_warning(target, 66.0, 0.55)
	await get_tree().create_timer(0.55).timeout
	global_position = target
	damage_player_in_radius(target, 66.0, 82.0)
	spawn_ice_burst(target, 66.0)
	await get_tree().create_timer(0.35).timeout
	finish_action()


func begin_action(texture: Texture2D = CAST_TEXTURE) -> void:
	busy = true
	animation_time = 0.0
	sprite.texture = texture
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity = Vector2.ZERO


func finish_action() -> void:
	busy = false
	animation_time = 0.0
	sprite.texture = WALK_TEXTURE
	cooldown = 0.65 if get_phase() == 3 else 1.45


func spawn_shard(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var shard := IceShard.new()
		shard.direction = direction
		foreground.add_child(shard)
		shard.global_position = global_position + direction * 30.0


func spawn_ice_burst(position: Vector2, radius: float) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var burst := IceBurstEffect.new(radius)
		foreground.add_child(burst)
		burst.global_position = position


func create_warning(position: Vector2, radius: float, duration: float) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var warning := WarningCircle.new(radius, duration)
		foreground.add_child(warning)
		warning.global_position = position


func damage_player_in_radius(position: Vector2, radius: float, damage: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.global_position.distance_squared_to(position) > radius * radius:
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.damage(damage, "冰霜女王")


func show_frame(frame: int) -> void:
	var column := frame % 4
	var row := floori(frame / 4.0)
	sprite.region_rect = Rect2(FRAME_COLUMNS[column], FRAME_ROWS[row], FRAME_COLUMNS[column + 1] - FRAME_COLUMNS[column], FRAME_ROWS[row + 1] - FRAME_ROWS[row])
	if velocity.x != 0.0:
		$Visuals.scale.x = absf($Visuals.scale.x) * sign(velocity.x)
