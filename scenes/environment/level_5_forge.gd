extends Node2D

const ART = preload("res://scenes/environment/forge_art.gd")
const EFFECT = preload("res://scenes/environment/forge_effect.gd")
const CENTER := Vector2(384, 384)
const BOUNDS := Rect2(-192, -192, 1152, 1152)
const VALVE_OFFSETS := [Vector2(-120, -95), Vector2(120, -95), Vector2(0, 125)]
const CRACK_ENDS := [Vector2(-210, -75), Vector2(210, -75), Vector2(110, 180)]

var active := false
var solids: Array[StaticBody2D] = []
var blocked: Array[Rect2] = []
var pools: Array[Rect2] = []
var props: Array[Dictionary] = []
var valves: Array[Dictionary] = []
var cracks: Array[Node2D] = []
var schedule_left := 8.0
var scheduler_paused := false
var elapsed := 0.0
var redraw_left := 0.0
var introduction_left := 0.0
var introduction: Label

func _ready() -> void:
	add_to_group("forge_map")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for wall: Rect2 in [Rect2(-208, -208, 1184, 16), Rect2(-208, 960, 1184, 16), Rect2(-208, -192, 16, 1152), Rect2(960, -192, 16, 1152)]:
		add_solid(wall)
	# Four corner pools keep the central square and wide ring/cross routes open.
	for offset: Vector2 in [Vector2(-420, -420), Vector2(240, -420), Vector2(-420, 240), Vector2(240, 240)]:
		var pool := Rect2(CENTER + offset, Vector2(180, 180))
		pools.append(pool)
		add_solid(pool)
	add_prop("furnace", CENTER + Vector2(0, -430), Vector2(128, 112), true)
	add_prop("bench", CENTER + Vector2(410, -25), Vector2(64, 48), true)
	add_prop("anvil", CENTER + Vector2(415, 65), Vector2(40, 36), true)
	add_prop("cooling_pool", CENTER + Vector2(-420, 0), Vector2(96, 64), true)
	for index in 3:
		add_prop("ore", CENTER + Vector2(-100 + index * 95, 440), Vector2(48, 40), true, index)
	for index in 3:
		valves.append({"position": CENTER + VALVE_OFFSETS[index], "charge": 0.0, "cooldown": 0.0, "last_attack": -1})
		cracks.append(null)
	activate(false)

func add_solid(rect: Rect2) -> void:
	blocked.append(rect)
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)
	solids.append(body)

func add_prop(kind: String, point: Vector2, size: Vector2, solid: bool, variant: int = 0) -> void:
	props.append({"kind": kind, "position": point, "size": size, "variant": variant})
	if solid:
		add_solid(Rect2(point - size * Vector2(0.4, 0.05), size * Vector2(0.8, 0.45)))

func activate(enabled: bool) -> void:
	var was_active := active
	active = enabled
	visible = enabled
	scheduler_paused = false
	schedule_left = 8.0
	for solid in solids:
		solid.collision_layer = 1 if enabled else 0
	for valve: Dictionary in valves:
		valve.charge = 0.0
		valve.cooldown = 0.0
		valve.last_attack = -1
	for crack in cracks:
		if is_instance_valid(crack):
			crack.queue_free()
	if was_active and not enabled:
		for effect: Node in get_tree().get_nodes_in_group("forge_effect"):
			if effect.kind != "death":
				effect.queue_free()
	if is_instance_valid(introduction):
		introduction.hide()
	queue_redraw()

func is_walkable(point: Vector2, clearance: float = 20.0) -> bool:
	if not BOUNDS.grow(-clearance).has_point(point):
		return false
	for rect in blocked:
		if rect.grow(clearance).has_point(point):
			return false
	return true

func safe_position(point: Vector2, clearance: float = 20.0) -> Vector2:
	if is_walkable(point, clearance):
		return point
	for distance in range(32, 513, 32):
		for index in 24:
			var candidate := point + Vector2.RIGHT.rotated(index * TAU / 24) * distance
			if is_walkable(candidate, clearance):
				return candidate
	return CENTER

func get_spawn_position(point: Vector2, distance: float = 375.0) -> Vector2:
	var angle := randf() * TAU
	for index in 32:
		var candidate := point + Vector2.RIGHT.rotated(angle + index * TAU / 32) * distance
		if is_walkable(candidate, 24):
			return candidate
	return safe_position(point + Vector2(180, 0), 24)

func active_crack_count() -> int:
	var count := 0
	for crack in cracks:
		if is_instance_valid(crack) and not crack.is_queued_for_deletion():
			count += 1
	return count

func trigger_crack(index: int) -> bool:
	if not active or index < 0 or index >= cracks.size() or active_crack_count() >= 2:
		return false
	if is_instance_valid(cracks[index]) and not cracks[index].is_queued_for_deletion():
		return false
	var effect := EFFECT.new()
	effect.kind = "eruption"
	effect.shape = "line"
	effect.line_end = CRACK_ENDS[index]
	effect.radius = 16.0
	effect.warning_time = 1.2
	effect.active_time = 1.5
	effect.affect_enemies = true
	get_tree().get_first_node_in_group("ground_effects_layer").add_child(effect)
	effect.global_position = CENTER + VALVE_OFFSETS[index]
	cracks[index] = effect
	return true

func activate_valve(index: int, attack_id: int = -1) -> bool:
	var valve: Dictionary = valves[index]
	if valve.cooldown > 0 or (attack_id != -1 and valve.last_attack == attack_id):
		return false
	if not trigger_crack(index):
		return false
	valve.charge = 0.0
	valve.cooldown = 10.0
	valve.last_attack = attack_id
	return true

func slam_valves(point: Vector2, radius: float, attack_id: int) -> bool:
	var activated := false
	for index in valves.size():
		if point.distance_to(valves[index].position) <= radius + 12.0:
			activated = activate_valve(index, attack_id) or activated
	return activated

func announce_boss() -> void:
	if not is_instance_valid(introduction):
		introduction = Label.new()
		introduction.position = Vector2(12, 105)
		introduction.add_theme_font_size_override("font_size", 13)
		introduction.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
		get_parent().get_node("ArenaTimeUI").add_child(introduction)
	introduction.text = "熔炉暴君苏醒！中央广场的压力阀可让它过热"
	introduction.show()
	introduction_left = 4.0

func _process(delta: float) -> void:
	if not active:
		return
	# Older bosses can summon on this map too. Validate only each unit's entry,
	# never snap a charging/moving enemy around during the subsequent fight.
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_meta("forge_spawn_checked"):
			enemy.global_position = safe_position(enemy.global_position, 35 if enemy.is_in_group("boss") else 24)
			enemy.set_meta("forge_spawn_checked", true)
	elapsed += delta
	redraw_left -= delta
	if redraw_left <= 0:
		queue_redraw()
		redraw_left = 0.12
	if introduction_left > 0:
		introduction_left -= delta
		if introduction_left <= 0 and is_instance_valid(introduction):
			introduction.hide()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for index in valves.size():
		var valve: Dictionary = valves[index]
		valve.cooldown = maxf(0, valve.cooldown - delta)
		if valve.cooldown <= 0:
			if player != null and player.global_position.distance_to(valve.position) <= 30:
				valve.charge += delta
				if valve.charge >= 0.6:
					activate_valve(index)
			else:
				valve.charge = 0.0
	if not scheduler_paused:
		schedule_left -= delta
		if schedule_left <= 0:
			trigger_crack(randi_range(0, 2))
			schedule_left = 6.0

func _draw() -> void:
	var floor := ART.texture("floor_tiles")
	for y in range(-192, 960, 16):
		for x in range(-192, 960, 16):
			var point := Vector2(x, y)
			var metal := absf(point.x - CENTER.x) < 192 and absf(point.y - CENTER.y) < 192
			var variant := 4 + posmod(x / 16 + y / 16, 3) if metal else posmod(x / 16 * 7 + y / 16 * 13, 4)
			draw_texture_rect_region(floor, Rect2(point, Vector2(16, 16)), Rect2(variant * 16, 0, 16, 16))
	for pool in pools:
		draw_rect(pool.grow(4), Color("251c1b"))
		for y in range(int(pool.position.y), int(pool.end.y), 16):
			for x in range(int(pool.position.x), int(pool.end.x), 16):
				var edge := -1
				var top := y == int(pool.position.y)
				var bottom := y + 16 >= pool.end.y
				var left := x == int(pool.position.x)
				var right := x + 16 >= pool.end.x
				if top:
					edge = 4 if left else 5 if right else 0
				elif bottom:
					edge = 7 if left else 6 if right else 2
				elif left or right:
					edge = 3 if left else 1
				var texture := ART.texture("lava_edges") if edge >= 0 else ART.texture("lava")
				var frame := (edge * 4 if edge >= 0 else 0) + int(elapsed * 6) % 4
				draw_texture_rect_region(texture, Rect2(x, y, minf(16, pool.end.x - x), minf(16, pool.end.y - y)), Rect2(frame * 16, 0, 16, 16))
	for rect in blocked.slice(0, 4):
		draw_rect(rect, Color("48312d"))
		for x in range(int(rect.position.x), int(rect.end.x), 16):
			draw_texture_rect_region(ART.texture("walls"), Rect2(x, rect.position.y, 16, rect.size.y), Rect2(0, 0, 16, 16))
	# Reuse the original 16px track, tinted to match iron.
	var track: Texture2D = load("res://assets/environment/tilemap_packed.png")
	for x in range(144, 720, 24):
		draw_texture_rect_region(track, Rect2(x, 792, 16, 16), Rect2(48, 48, 16, 16), Color("90806e"))
	for index in valves.size():
		var point: Vector2 = valves[index].position
		draw_line(point, point + CRACK_ENDS[index], Color("20191a"), 9)
		draw_line(point, point + CRACK_ENDS[index], Color("725035"), 2)
		var valve: Dictionary = valves[index]
		var name := "valve_cool" if valve.cooldown > 0 else "valve_active" if valve.charge > 0 else "valve_idle"
		var frame := 0 if name == "valve_cool" else int(elapsed * 8) % (4 if name == "valve_active" else 2)
		draw_texture_rect_region(ART.texture(name), Rect2(point - Vector2(16, 24), Vector2(32, 32)), Rect2(frame * 32, 0, 32, 32))
		var progress: float = 1.0 - valve.cooldown / 10.0 if valve.cooldown > 0 else clampf(valve.charge / 0.6, 0, 1)
		draw_arc(point, 23, -PI / 2, -PI / 2 + TAU * progress, 32, Color(0.4, 0.8, 0.85) if valve.cooldown > 0 else Color(1, 0.75, 0.2), 2)
	for prop: Dictionary in props:
		var size: Vector2 = prop.size
		var cell := Vector2(96, 96) if prop.kind == "furnace" else Vector2(64, 48) if prop.kind == "cooling_pool" else Vector2(32, 32)
		var frame: int = int(elapsed * 6) % 4 if prop.kind == "furnace" else prop.variant
		draw_texture_rect_region(ART.texture(prop.kind), Rect2(prop.position - Vector2(size.x / 2, size.y * 0.8), size), Rect2(frame * cell.x, 0, cell.x, cell.y))
	# West-side pipe segments are decoration, not extra obstacles.
	for y in range(224, 544, 16):
		draw_texture_rect_region(ART.texture("pipe"), Rect2(-100, y, 16, 16), Rect2(0, 0, 16, 16))
