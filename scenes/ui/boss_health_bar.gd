extends CanvasLayer

@onready var name_label: Label = %NameLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var content: Control = $MarginContainer

var boss_id := 0
var health_component: HealthComponent


func _ready() -> void:
	content.hide()


func _process(_delta: float) -> void:
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
