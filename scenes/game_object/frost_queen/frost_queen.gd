extends CharacterBody2D

const FRAME_COLUMNS := [0, 384, 768, 1152, 1536]
const FRAME_ROWS := [0, 512, 1024]
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
		draw_circle(Vector2.ZERO, radius, Color(0.25, 0.7, 1.0, 0.12))
		draw_circle(Vector2.ZERO, radius * progress, Color(0.7, 0.94, 1.0, 0.2))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.75, 0.95, 1.0, 0.9), 2.0)


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
		var shard := PackedVector2Array([Vector2(15, 0), Vector2(-7, -6), Vector2(-13, 0), Vector2(-7, 6)])
		draw_colored_polygon(shard, Color(0.3, 0.82, 1.0))
		draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color.WHITE, 1.5)


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
		draw_rect(Rect2(-46, -8, 92, 16), Color(0.2, 0.65, 0.9, 0.88))
		for x in range(-40, 41, 16):
			draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 7), Vector2(x, -12), Vector2(x + 7, 7)]), Color(0.65, 0.92, 1.0))


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
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.82, 0.97, 1.0, 0.95), 4.0)
		for index in 18:
			var angle := index * TAU / 18.0 + elapsed * 1.8
			var point := Vector2.RIGHT.rotated(angle) * (radius + 24.0 + sin(index * 2.0) * 18.0)
			draw_circle(point, 2.5, Color(0.7, 0.92, 1.0, 0.75))


func _ready() -> void:
	show_frame(0)


func _process(delta: float) -> void:
	animation_time += delta
	show_frame(int(animation_time * 8.0) % 8)
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
	finish_action()


func summon_wisps() -> void:
	var entities := get_tree().get_first_node_in_group("entities_layer") as Node2D
	if entities == null:
		return
	begin_action()
	for index in 4:
		var wisp := WISP_SCENE.instantiate() as Node2D
		entities.add_child(wisp)
		wisp.global_position = global_position + Vector2.RIGHT.rotated(index * TAU / 4.0) * 76.0
	finish_action()


func start_blizzard() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	begin_action()
	var storm := Blizzard.new()
	foreground.add_child(storm)
	storm.global_position = player.global_position
	finish_action()


func teleport_blast() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	begin_action()
	var target := player.global_position
	create_warning(target, 66.0, 0.55)
	await get_tree().create_timer(0.55).timeout
	global_position = target
	damage_player_in_radius(target, 66.0, 82.0)
	finish_action()


func begin_action() -> void:
	busy = true
	velocity_component.accelerate_in_direction(Vector2.ZERO)
	velocity = Vector2.ZERO


func finish_action() -> void:
	busy = false
	cooldown = 0.65 if get_phase() == 3 else 1.45


func spawn_shard(direction: Vector2) -> void:
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground != null:
		var shard := IceShard.new()
		shard.direction = direction
		foreground.add_child(shard)
		shard.global_position = global_position


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
