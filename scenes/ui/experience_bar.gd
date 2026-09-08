extends CanvasLayer

@export var experience_manager: ExperienceManager
@onready var progress_bar = %ProgressBar
@onready var level_label: Label = %LevelLabel


func _ready():
	progress_bar.value = 0
	on_level_up(experience_manager.current_level)
	experience_manager.experience_updated.connect(on_experience_updated)
	experience_manager.level_up.connect(on_level_up)


func on_experience_updated(current_experience: float, target_experience: float):
	if target_experience == 0:
		return

	var percent = current_experience / target_experience
	progress_bar.value = percent


func on_level_up(new_level: int):
	level_label.text = "等级 %d" % new_level
