extends SceneTree

const ART = preload("res://scenes/environment/forge_art.gd")
const INK := Color("171416")
const IRON := Color("59504b")
const LIGHT := Color("8a7561")
const HEAT := Color("f68a30")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ART.ROOT)
	for actor: String in ART.ACTORS:
		var spec: Dictionary = ART.ACTORS[actor]
		for action: String in spec:
			if action == "size":
				continue
			var size: int = spec.size
			var count: int = spec[action]
			var sheet := Image.create(size * count, size, false, Image.FORMAT_RGBA8)
			for index in count:
				var frame := actor_frame(actor, action, index, count, size)
				sheet.blit_rect(frame, Rect2i(0, 0, size, size), Vector2i(index * size, 0))
			sheet.save_png(ART.ROOT + actor + "_" + action + ".png")
	make_tiles()
	for item: String in {"furnace": [96, 96, 4], "anvil": [32, 32, 1], "bench": [32, 32, 1], "ore": [32, 32, 3], "pipe": [16, 16, 4], "valve_idle": [32, 32, 2], "valve_active": [32, 32, 4], "valve_cool": [32, 32, 1], "cooling_pool": [64, 48, 1], "barrel": [24, 24, 1]}:
		var sizes: Dictionary = {"furnace": [96, 96, 4], "anvil": [32, 32, 1], "bench": [32, 32, 1], "ore": [32, 32, 3], "pipe": [16, 16, 4], "valve_idle": [32, 32, 2], "valve_active": [32, 32, 4], "valve_cool": [32, 32, 1], "cooling_pool": [64, 48, 1], "barrel": [24, 24, 1]}
		make_prop(item, sizes[item])
	for effect: String in {"eruption": [64, 96, 8], "flame": [128, 128, 8], "slag": [24, 24, 4], "fire": [64, 64, 6], "steam": [64, 64, 6], "ember": [32, 32, 4]}:
		var sizes: Dictionary = {"eruption": [64, 96, 8], "flame": [128, 128, 8], "slag": [24, 24, 4], "fire": [64, 64, 6], "steam": [64, 64, 6], "ember": [32, 32, 4]}
		make_effect(effect, sizes[effect])
	print("FORGE_PLACEHOLDER_SHEETS_GENERATED")
	quit()

func box(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect.intersection(Rect2i(0, 0, image.get_width(), image.get_height())), color)

func plate(image: Image, rect: Rect2i, color: Color) -> void:
	box(image, rect, INK)
	box(image, rect.grow(-2), color)
	box(image, Rect2i(rect.position + Vector2i(3, 3), Vector2i(maxi(rect.size.x - 6, 1), 2)), LIGHT)

func disc(image: Image, center: Vector2i, radius: Vector2i, color: Color) -> void:
	for y in range(center.y - radius.y, center.y + radius.y + 1):
		for x in range(center.x - radius.x, center.x + radius.x + 1):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height() and Vector2(float(x - center.x) / maxf(radius.x, 1), float(y - center.y) / maxf(radius.y, 1)).length_squared() <= 1.0:
				image.set_pixel(x, y, color)

func actor_frame(actor: String, action: String, index: int, count: int, size: int) -> Image:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var swing := roundi(sin(float(index) / count * TAU) * 2.0)
	var heat := HEAT if action not in ["death", "recover"] else Color("a54a28")
	if actor == "cinder":
		for leg in [12, 21, 30]:
			plate(image, Rect2i(leg + swing, 34, 6, 10), IRON)
		disc(image, Vector2i(24, 29), Vector2i(18, 13), INK)
		disc(image, Vector2i(24, 27), Vector2i(15, 10), Color("342e31"))
		box(image, Rect2i(16, 24, 3, 9), heat)
		box(image, Rect2i(27, 21, 3, 13), heat)
		box(image, Rect2i(15, 24, 16, 3), heat)
		disc(image, Vector2i(14, 26), Vector2i(2, 2), Color("fff2b0"))
		disc(image, Vector2i(32, 26), Vector2i(2, 2), Color("fff2b0"))
	elif actor == "worker":
		plate(image, Rect2i(12, 8, 24, 28), Color("75432c"))
		box(image, Rect2i(15, 13, 18, 3), IRON)
		box(image, Rect2i(15, 26, 18, 3), IRON)
		box(image, Rect2i(26, 4, 3, 8), heat)
		plate(image, Rect2i(11, 23, 25, 15), Color("827349"))
		plate(image, Rect2i(15 + swing, 37, 8, 7), IRON)
		plate(image, Rect2i(27 - swing, 37, 8, 7), IRON)
		disc(image, Vector2i(23, 25), Vector2i(9, 7), INK)
		box(image, Rect2i(16, 23, 14, 4), Color("b5c3a1"))
	else:
		var lifted := action in ["charge", "throw", "transition"]
		var punched := action == "hammer" and index >= count / 2
		plate(image, Rect2i(11 + swing, 33, 11, 11), IRON)
		plate(image, Rect2i(27 - swing, 33, 11, 11), IRON)
		plate(image, Rect2i(10, 12, 29, 25), Color("655047"))
		plate(image, Rect2i(4, 9, 14, 12), IRON)
		plate(image, Rect2i(31, 9, 13, 12), IRON)
		plate(image, Rect2i(16, 16, 18, 16), INK)
		box(image, Rect2i(19, 19, 12, 10), heat)
		box(image, Rect2i(22, 21, 5, 6), Color("ffdf83"))
		if action not in ["open", "flame", "overheat"]:
			for x in [20, 25, 30]:
				box(image, Rect2i(x, 17, 2, 15), IRON)
		plate(image, Rect2i(1, 4 if lifted else 29 if punched else 19, 12, 13), IRON)
		plate(image, Rect2i(36, 4 if lifted else 29 if punched else 19, 11, 13), IRON)
		if actor == "guard":
			plate(image, Rect2i(0, 17, 13, 22), LIGHT)
			plate(image, Rect2i(36, 2 if lifted else 30 if punched else 11, 12, 9), IRON)
		else:
			plate(image, Rect2i(12, 2, 7, 13), IRON)
			plate(image, Rect2i(32, 2, 7, 13), IRON)
			if action == "overheat":
				disc(image, Vector2i(24 + swing, 9), Vector2i(8, 5), Color(0.7, 0.8, 0.8, 0.65))
	if action == "death":
		var fall := Image.create(48, 48, false, Image.FORMAT_RGBA8)
		var height := maxi(12, 44 - index * 30 / maxi(count - 1, 1))
		image.resize(48, height, Image.INTERPOLATE_NEAREST)
		fall.blit_rect(image, Rect2i(0, 0, 48, height), Vector2i(0, 44 - image.get_used_rect().end.y))
		image = fall
	# Keep silhouettes entirely inside every cell, including the raised fists.
	image.resize(38, 38, Image.INTERPOLATE_NEAREST)
	var padded := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	padded.blit_rect(image, Rect2i(0, 0, 38, 38), Vector2i(5, 6))
	padded.resize(size, size, Image.INTERPOLATE_NEAREST)
	return padded

func make_tiles() -> void:
	var floor := Image.create(16 * 7, 16, false, Image.FORMAT_RGBA8)
	for index in 7:
		var tile := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		tile.fill(Color("443c36") if index < 4 else Color("4b4d4b"))
		box(tile, Rect2i(0, 0, 16, 1), Color("29272a"))
		box(tile, Rect2i(0, 8, 16, 1), Color("343031"))
		box(tile, Rect2i(7 if index % 2 == 0 else 11, 0, 1, 8), Color("302d2d"))
		box(tile, Rect2i(4, 9, 1, 7), Color("302d2d"))
		if index == 5:
			for corner in [Vector2i(2, 2), Vector2i(13, 13)]:
				box(tile, Rect2i(corner, Vector2i(2, 2)), Color("626360"))
		elif index == 6:
			box(tile, Rect2i(4, 4, 6, 1), Color("60615c"))
			box(tile, Rect2i(9, 5, 1, 3), Color("60615c"))
		elif index > 0 and index < 4:
			box(tile, Rect2i(2 + index * 2, 4, 3, 1), Color("50463b"))
		floor.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(index * 16, 0))
	floor.save_png(ART.ROOT + "floor_tiles.png")
	for item in ["walls", "lava", "cracks"]:
		var count := 12 if item == "walls" else 4 if item == "lava" else 6
		var sheet := Image.create(16 * count, 16, false, Image.FORMAT_RGBA8)
		for index in count:
			var tile := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			if item == "walls":
				plate(tile, Rect2i(0, 0, 16, 16), Color("4c3430") if index >= 6 else IRON)
				box(tile, Rect2i(1, 7, 14, 2), INK)
				if index % 6 in [1, 2]:
					box(tile, Rect2i(8, 0 if index % 6 == 1 else 8, 8, 8), INK)
				elif index % 6 == 3:
					box(tile, Rect2i(0, 0, 16, 4), LIGHT)
				elif index % 6 == 4:
					box(tile, Rect2i(12, 0, 4, 16), LIGHT)
				elif index % 6 == 5:
					box(tile, Rect2i(0, 12, 16, 4), LIGHT)
			elif item == "lava":
				tile.fill(Color("a6371e"))
				for x in range(1, 16, 5):
					box(tile, Rect2i(x, 3 + (x + index * 3) % 10, 4, 2), HEAT)
			else:
				var color := INK if index < 3 else HEAT
				box(tile, Rect2i(7, 0, 3, 8 if index % 3 != 0 else 16), color)
				if index % 3 == 1:
					box(tile, Rect2i(7, 6, 9, 3), color)
			sheet.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(index * 16, 0))
		sheet.save_png(ART.ROOT + item + ".png")
	var lava := Image.load_from_file(ART.ROOT + "lava.png")
	var edges := Image.create(16 * 48, 16, false, Image.FORMAT_RGBA8)
	for shape in 12:
		for frame in 4:
			var tile := lava.get_region(Rect2i(frame * 16, 0, 16, 16))
			if shape in [0, 4, 5]:
				box(tile, Rect2i(0, 0, 16, 3), INK)
			if shape in [1, 5, 6]:
				box(tile, Rect2i(13, 0, 3, 16), INK)
			if shape in [2, 6, 7]:
				box(tile, Rect2i(0, 13, 16, 3), INK)
			if shape in [3, 7, 4]:
				box(tile, Rect2i(0, 0, 3, 16), INK)
			if shape >= 8:
				box(tile, Rect2i(0 if shape in [8, 11] else 13, 0 if shape < 10 else 13, 3, 3), INK)
			edges.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i((shape * 4 + frame) * 16, 0))
	edges.save_png(ART.ROOT + "lava_edges.png")

func make_prop(item: String, sizes: Array) -> void:
	var sheet := Image.create(sizes[0] * sizes[2], sizes[1], false, Image.FORMAT_RGBA8)
	for index in sizes[2]:
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		if item.begins_with("valve"):
			plate(image, Rect2i(7, 16, 18, 13), IRON)
			disc(image, Vector2i(16, 12), Vector2i(11, 11), INK)
			disc(image, Vector2i(16, 12), Vector2i(9, 9), Color("6e9898") if item == "valve_cool" else HEAT)
			if item == "valve_active":
				box(image, Rect2i(12 + index * 2, 4, 2, 3), Color("ffeda6"))
			elif item == "valve_idle":
				box(image, Rect2i(14, 4 + index, 3, 2), LIGHT)
			disc(image, Vector2i(16, 12), Vector2i(6, 6), INK)
			box(image, Rect2i(14, 3, 3, 19), LIGHT)
			box(image, Rect2i(7, 10, 18, 3), LIGHT)
		elif item == "cooling_pool":
			plate(image, Rect2i(1, 7, 30, 24), IRON)
			box(image, Rect2i(4, 10, 24, 16), Color("41676b"))
		elif item == "ore":
			for rock in 5:
				disc(image, Vector2i(7 + rock * 4, 20 + (rock + index) % 3 * 2), Vector2i(6, 6), INK)
				disc(image, Vector2i(7 + rock * 4, 18 + (rock + index) % 3 * 2), Vector2i(4, 4), IRON)
		elif item == "pipe":
			plate(image, Rect2i(10, 0, 12, 32), IRON)
			box(image, Rect2i(8, 5, 16, 4), LIGHT)
		elif item in ["anvil", "bench"]:
			plate(image, Rect2i(5, 23, 23, 7), IRON)
			plate(image, Rect2i(10, 12, 12, 13), IRON)
			plate(image, Rect2i(1, 5, 30, 10), LIGHT)
		else:
			plate(image, Rect2i(4, 3, 24, 27), Color("594139"))
			plate(image, Rect2i(9, 11, 14, 16), INK)
			box(image, Rect2i(11, 14, 10, 10), HEAT)
			box(image, Rect2i(14, 15 + index % 3, 4, 6), Color("ffd676"))
		image.resize(sizes[0], sizes[1], Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(image, Rect2i(0, 0, sizes[0], sizes[1]), Vector2i(index * sizes[0], 0))
	sheet.save_png(ART.ROOT + item + ".png")

func make_effect(item: String, sizes: Array) -> void:
	var sheet := Image.create(sizes[0] * sizes[2], sizes[1], false, Image.FORMAT_RGBA8)
	for index in sizes[2]:
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for spark in 9:
			var center := Vector2i(4 + (spark * 7 + index * 3) % 24, 27 - (spark * 3 + index * 2) % 23)
			disc(image, center, Vector2i(3, 5 if item == "eruption" else 3), Color(0.65, 0.75, 0.75, 0.4) if item == "steam" else HEAT)
		image.resize(sizes[0], sizes[1], Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(image, Rect2i(0, 0, sizes[0], sizes[1]), Vector2i(index * sizes[0], 0))
	sheet.save_png(ART.ROOT + item + ".png")
