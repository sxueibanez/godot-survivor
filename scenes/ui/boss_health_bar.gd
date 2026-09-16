extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var content: Control = $MarginContainer

var boss_id := 0
var health_component: HealthComponent
var other_bosses: Label


func _ready() -> void:
	other_bosses = Label.new()
	other_bosses.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	other_bosses.add_theme_font_size_override("font_size", 12)
	$MarginContainer/VBoxContainer.add_child(other_bosses)
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
	update_health_bar()


func update_health_bar() -> void:
	progress_bar.value = health_component.get_health_percent()
