extends CanvasLayer

@export var experience_manager: ExperienceManager
@onready var progress_bar = %ProgressBar
@onready var level_label: Label = %LevelLabel
@onready var amount_label: Label = %AmountLabel


func _ready():
	on_experience_updated(experience_manager.current_experience, experience_manager.target_experience)
	on_level_up(experience_manager.current_level)
	experience_manager.experience_updated.connect(on_experience_updated)
	experience_manager.level_up.connect(on_level_up)


func on_experience_updated(current_experience: float, target_experience: float):
	if target_experience == 0:
		return

	var percent = current_experience / target_experience
	progress_bar.value = percent
	amount_label.text = "%s / %s" % [format_amount(current_experience), format_amount(target_experience)]


func format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(roundi(amount))
	return "%.1f" % amount


func on_level_up(new_level: int):
	level_label.text = "等级 %d" % new_level
