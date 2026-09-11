extends Node
class_name HealthComponent

signal died
signal health_changed
signal shield_changed(current_shield: float)

@export var max_health: float = 10
var current_health: float
var shield := 0.0
var invulnerable_time_left := 0.0


func _ready():
	current_health = max_health


func _process(delta: float) -> void:
	invulnerable_time_left = maxf(invulnerable_time_left - delta, 0.0)


func damage(damage_amount: float, source: String = "") -> bool:
	if current_health <= 0 or invulnerable_time_left > 0.0:
		return false
	if owner != null and owner.is_in_group("player") and not source.is_empty():
		var game_events := get_node_or_null("/root/GameEvents")
		if game_events != null:
			game_events.set("last_damage_source", source)
	if shield > 0.0:
		var absorbed := minf(shield, damage_amount)
		shield -= absorbed
		damage_amount -= absorbed
		shield_changed.emit(shield)
		if damage_amount <= 0.0:
			return false
	# clamping
	current_health = max(current_health - damage_amount, 0)
	health_changed.emit()
	Callable(check_death).call_deferred()
	return current_health == 0


func heal(heal_amount: float):
	current_health = min(current_health + heal_amount, max_health)
	health_changed.emit()


func set_shield(amount: float) -> void:
	shield = maxf(amount, 0.0)
	shield_changed.emit(shield)


func set_invulnerable(duration: float) -> void:
	invulnerable_time_left = maxf(invulnerable_time_left, duration)


func get_health_percent() -> float:
	if max_health <= 0:
		return 0
	return min(current_health / max_health, 1)


func check_death():
	if current_health == 0:
		died.emit()
		owner.queue_free()
