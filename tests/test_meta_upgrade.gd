extends SceneTree


func _init() -> void:
	var upgrade := MetaUpgrade.new()
	upgrade.max_quantity = 0
	upgrade.experience_cost = 10
	assert(upgrade.get_experience_cost(0) == 10)
	assert(upgrade.get_experience_cost(1) == 20)
	assert(upgrade.get_experience_cost(9) == 100)
	upgrade.max_quantity = 10
	upgrade.experience_cost = 200
	upgrade.escalating_cost = true
	assert(upgrade.get_experience_cost(0) == 200)
	assert(upgrade.get_experience_cost(1) == 400)
	assert(upgrade.get_experience_cost(9) == 2000)
	quit()
