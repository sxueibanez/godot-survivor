extends Resource
class_name MetaUpgrade

@export var id: String
@export var max_quantity: int = 1
@export var experience_cost: int = 10
@export var escalating_cost: bool = false
@export var title: String
@export_multiline var description: String


func get_experience_cost(current_quantity: int) -> int:
	if max_quantity == 0 or escalating_cost:
		return experience_cost * (current_quantity + 1)
	return experience_cost
