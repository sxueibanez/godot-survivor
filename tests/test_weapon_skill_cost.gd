extends SceneTree


func _initialize() -> void:
	assert(MetaProgression.calculate_weapon_skill_cost(0) == 200)
	assert(MetaProgression.calculate_weapon_skill_cost(1) == 400)
	assert(MetaProgression.calculate_weapon_skill_cost(5) == 1200)
	quit()
