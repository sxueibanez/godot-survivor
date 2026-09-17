extends RefCounted

# Environment placeholders remain; actors use the generated transparent atlases.
const ROOT := "res://assets/forge/placeholders/"
const SPRITE_ROOT := "res://assets/forge/sprites/"
const FIRE_ROWS := {"fire": 0, "flame": 1, "eruption": 2, "ember": 3}
const SPRITE_SHEETS := {
	"cinder-v2": [4, 2, "cinder", {"walk": [0, 1, 2, 3], "death": [4, 5, 6, 7]}],
	"guard-v2": [6, 6, "guard", {
		"idle": [0, 1, 2, 2], "walk": [6, 7, 8, 9, 10, 11],
		"charge": [12, 13, 14, 15], "hammer": [18, 19, 20, 21, 22, 23],
		"recover": [24, 25, 26], "death": [30, 31, 32, 33, 34, 35]}],
	"worker-v2": [6, 4, "worker", {
		"walk": [0, 1, 2, 3, 4, 5], "ignite": [6, 7, 8, 9],
		"shake": [12, 13, 14, 15], "death": [18, 19, 20, 21]}],
	"tyrant-locomotion-v2": [4, 4, "tyrant", {
		"idle": [0, 1, 2, 3, 4, 5], "walk": [8, 9, 10, 11, 12, 13, 14, 15]}],
	"tyrant-punch-v2": [6, 3, "tyrant", {
		"charge": [0, 1, 2, 3, 4, 5], "hammer": [6, 7, 8, 9, 10, 11], "recover": [12, 13, 14, 15]}],
	"tyrant-furnace-v2": [6, 4, "tyrant", {
		"open": [0, 1, 2, 3, 4], "flame": [6, 7, 8, 9, 10, 11],
		"close": [12, 13, 14, 15], "throw": [18, 19, 20, 21, 22, 23]}],
	"tyrant-states-v2": [6, 4, "tyrant", {
		"overheat": [0, 1, 2, 3, 4, 5], "transition": [6, 7, 8, 9, 10, 11],
		"death": [12, 13, 14, 15, 16, 17, 18, 19, 20, 21]}],
}
const ACTORS := {
	"cinder": {"size": 32, "walk": 4, "death": 4},
	"guard": {"size": 64, "idle": 4, "walk": 6, "charge": 4, "hammer": 6, "recover": 3, "death": 6},
	"worker": {"size": 48, "walk": 6, "ignite": 4, "shake": 4, "death": 4},
	"tyrant": {"size": 192, "idle": 6, "walk": 8, "charge": 6, "hammer": 6, "recover": 4, "open": 5, "flame": 6, "close": 4, "throw": 6, "overheat": 6, "transition": 6, "death": 10},
}
static var textures: Dictionary = {}
static var frame_textures: Dictionary = {}
static var sprite_images: Dictionary = {}
static var sprite_textures: Dictionary = {}

static func texture(name: String) -> Texture2D:
	if not textures.has(name):
		var image := Image.load_from_file(ROOT + name + ".png")
		if image == null:
			return null
		textures[name] = ImageTexture.create_from_image(image)
	return textures[name]

static func fire_frame_texture(kind: String, frame: int) -> AtlasTexture:
	var key := "fire_effect_%s_%d" % [kind, frame]
	if frame_textures.has(key):
		return frame_textures[key]
	var name := "fire-effects-v2"
	if not sprite_images.has(name):
		var image := Image.load_from_file(SPRITE_ROOT + name + ".png")
		assert(image != null, "Missing generated forge fire atlas")
		sprite_images[name] = image
		sprite_textures[name] = ImageTexture.create_from_image(image)
	var source: Image = sprite_images[name]
	var cell := Vector2(source.get_width() / 6, source.get_height() / 4)
	var atlas := AtlasTexture.new()
	atlas.atlas = sprite_textures[name]
	atlas.region = Rect2(Vector2(frame, FIRE_ROWS[kind]) * cell, cell)
	atlas.filter_clip = true
	frame_textures[key] = atlas
	return atlas


static func frame_count(actor: String, action: String) -> int:
	return int(ACTORS[actor].get(action, 4))


static func frame_texture(actor: String, action: String, frame: int) -> AtlasTexture:
	var key := "%s_%s_%d" % [actor, action, frame]
	if frame_textures.has(key):
		return frame_textures[key]
	for sheet_name: String in SPRITE_SHEETS:
		var spec: Array = SPRITE_SHEETS[sheet_name]
		if spec[2] != actor or not spec[3].has(action):
			continue
		if not sprite_images.has(sheet_name):
			var loaded := Image.load_from_file(SPRITE_ROOT + sheet_name + ".png")
			assert(loaded != null, "Missing forge sprite atlas: " + sheet_name)
			sprite_images[sheet_name] = loaded
			sprite_textures[sheet_name] = ImageTexture.create_from_image(loaded)
		var image: Image = sprite_images[sheet_name]
		var columns: int = spec[0]
		var rows: int = spec[1]
		var index: int = spec[3][action][frame]
		var column := index % columns
		var row := index / columns
		# Read actual dimensions, not assumed tool output sizes. No pixels are edited.
		var start := Vector2i(image.get_width() * column / columns, image.get_height() * row / rows)
		var end := Vector2i(image.get_width() * (column + 1) / columns, image.get_height() * (row + 1) / rows)
		var cell := Rect2i(start, end - start)
		var used := image.get_region(cell).get_used_rect()
		assert(used.has_area(), "Empty forge animation frame: " + key)
		var canvas := ceili(maxf(float(image.get_width()) / columns, float(image.get_height()) / rows) * 1.2)
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_textures[sheet_name]
		atlas.region = Rect2(start + used.position, used.size)
		# Padding fixes the center/feet independently of the source pose's whitespace.
		atlas.margin = Rect2(Vector2((canvas - cell.size.x) / 2.0 + used.position.x, ceili(canvas * 0.9) - used.size.y), Vector2(canvas, canvas) - Vector2(used.size))
		atlas.filter_clip = true
		frame_textures[key] = atlas
		return atlas
	assert(false, "Unknown forge actor animation: " + key)
	return null
