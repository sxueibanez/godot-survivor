extends CanvasLayer

const DIRECTIONS := ["右", "右下", "下", "左下", "左", "左上", "上", "右上"]

var player: Node2D
var entrance: Node2D
var label: Label


func _ready() -> void:
	layer = 10
	label = Label.new()
	label.name = "DirectionLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -180.0
	label.offset_right = -12.0
	label.offset_top = 56.0
	label.offset_bottom = 76.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.247, 0.149, 0.192))
	add_child(label)
	update_direction()


func _process(_delta: float) -> void:
	update_direction()


func update_direction() -> void:
	if not is_instance_valid(player) or not is_instance_valid(entrance):
		queue_free()
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health != null and health.current_health <= 0.0:
		label.hide()
		return
	var offset := entrance.global_position - player.global_position
	var direction: String = DIRECTIONS[posmod(roundi(offset.angle() / (PI / 4.0)), 8)]
	label.text = "入口：%s · %d" % [direction, roundi(offset.length())]
	label.show()
