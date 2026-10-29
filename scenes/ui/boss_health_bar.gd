extends CanvasLayer

const DIRECTIONS := ["右", "右下", "下", "左下", "左", "左上", "上", "右上"]
@onready var name_label: Label = %NameLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var damage_bar: ProgressBar = %DamageBar
@onready var health_percent: Label = %HealthPercent
@onready var content: Control = $MarginContainer

var boss_id := 0
var health_component: HealthComponent
var other_bosses: Label
var boss_pointer: Label
var damage_tween: Tween


func _ready() -> void:
	other_bosses = Label.new()
	other_bosses.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	other_bosses.add_theme_font_size_override("font_size", 12)
	$MarginContainer/VBoxContainer.add_child(other_bosses)
	boss_pointer = Label.new()
	boss_pointer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_pointer.add_theme_font_size_override("font_size", 11)
	boss_pointer.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	boss_pointer.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	boss_pointer.add_theme_constant_override("outline_size", 3)
	$MarginContainer/VBoxContainer.add_child(boss_pointer)
	boss_pointer.hide()
	content.hide()


func _process(_delta: float) -> void:
	var others: PackedStringArray = []
	var bosses := get_tree().get_nodes_in_group("boss")
	for index in range(1, bosses.size()):
		var health := bosses[index].get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			others.append("%s  %d%%" % [str(bosses[index].get_meta("display_name", bosses[index].name)), roundi(health.get_health_percent() * 100)])
	other_bosses.text = " / ".join(others)
	other_bosses.visible = not others.is_empty()
	var boss := get_tree().get_first_node_in_group("boss")
	update_boss_pointer(boss as Node2D)
	var new_boss_id := boss.get_instance_id() if boss != null else 0
	if new_boss_id == boss_id:
		return
	boss_id = new_boss_id
	if is_instance_valid(health_component) and health_component.health_changed.is_connected(update_health_bar):
		health_component.health_changed.disconnect(update_health_bar)
	health_component = boss.get_node_or_null("HealthComponent") as HealthComponent if boss != null else null
	content.visible = health_component != null
	if not content.visible:
		return
	name_label.text = str(boss.get_meta("display_name", boss.name))
	health_component.health_changed.connect(update_health_bar)
	if damage_tween != null and damage_tween.is_valid():
		damage_tween.kill()
	damage_bar.value = health_component.get_health_percent()
	update_health_bar()


func update_boss_pointer(boss: Node2D) -> void:
	boss_pointer.hide()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(boss) or boss.is_queued_for_deletion() or not is_instance_valid(player):
		return
	var health := boss.get_node_or_null("HealthComponent") as HealthComponent
	if health == null or health.current_health <= 0.0:
		return
	var view := get_viewport().get_visible_rect().grow(-10.0)
	if view.has_point(get_viewport().get_canvas_transform() * boss.global_position):
		return
	var offset := boss.global_position - player.global_position
	var direction: String = DIRECTIONS[posmod(roundi(offset.angle() / (PI / 4.0)), DIRECTIONS.size())]
	boss_pointer.text = "首领：%s · %d" % [direction, roundi(offset.length())]
	boss_pointer.show()


func update_health_bar() -> void:
	var value := health_component.get_health_percent()
	progress_bar.value = value
	health_percent.text = "%d%%" % roundi(value * 100.0)
	if damage_tween != null and damage_tween.is_valid():
		damage_tween.kill()
	if value >= damage_bar.value:
		damage_bar.value = value
	else:
		damage_tween = create_tween()
		damage_tween.tween_interval(0.25)
		damage_tween.tween_property(damage_bar, "value", value, 0.35)
