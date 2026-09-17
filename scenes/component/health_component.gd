extends Node
class_name HealthComponent

signal died
signal health_changed
signal shield_changed(current_shield: float)
signal damage_taken(amount: float)

@export var max_health: float = 10
@export_storage var enemy_base_health := 0.0
var current_health: float
var shield := 0.0
var temporary_shield := 0.0
var temporary_shield_time_left := 0.0
var invulnerable_time_left := 0.0
var death_emitted := false


func _ready():
	if get_parent().is_in_group("enemy"):
		if enemy_base_health <= 0.0:
			enemy_base_health = max_health
		if GameEvents.game_mode == "campaign":
			max_health = GameEvents.get_campaign_enemy_health(enemy_base_health, get_parent().is_in_group("boss"))
		elif GameEvents.game_mode == "boss_rush" and not get_parent().is_in_group("boss"):
			max_health = clampf(12.0 * sqrt(enemy_base_health / 10.0), 12.0, 25.0)
		if GameEvents.game_mode != "boss_rush":
			max_health *= MetaProgression.get_enemy_health_multiplier()
	current_health = max_health


func _process(delta: float) -> void:
	invulnerable_time_left = maxf(invulnerable_time_left - delta, 0.0)
	if temporary_shield_time_left > 0.0:
		temporary_shield_time_left = maxf(temporary_shield_time_left - delta, 0.0)
		if temporary_shield_time_left <= 0.0:
			set_temporary_shield(0.0, 0.0)


func damage(damage_amount: float, source: String = "") -> bool:
	if get_tree().paused or current_health <= 0 or invulnerable_time_left > 0.0:
		return false
	if get_parent().is_in_group("player") and GameEvents.game_mode == "campaign":
		damage_amount *= GameEvents.get_campaign_damage_multiplier()
	if owner != null and owner.is_in_group("player") and not source.is_empty():
		var game_events := get_node_or_null("/root/GameEvents")
		if game_events != null:
			game_events.set("last_damage_source", source)
	if temporary_shield > 0.0:
		var absorbed := minf(temporary_shield, damage_amount)
		temporary_shield -= absorbed
		damage_amount -= absorbed
		shield_changed.emit(get_total_shield())
		if damage_amount <= 0.0:
			return false
	if shield > 0.0:
		var absorbed := minf(shield, damage_amount)
		shield -= absorbed
		damage_amount -= absorbed
		shield_changed.emit(get_total_shield())
		if damage_amount <= 0.0:
			return false
	# clamping
	var previous_health := current_health
	current_health = max(current_health - damage_amount, 0)
	health_changed.emit()
	damage_taken.emit(previous_health - current_health)
	Callable(check_death).call_deferred()
	return current_health == 0


func heal(heal_amount: float):
	current_health = min(current_health + heal_amount, max_health)
	health_changed.emit()


func set_shield(amount: float) -> void:
	shield = maxf(amount, 0.0)
	shield_changed.emit(get_total_shield())


func set_temporary_shield(amount: float, duration: float) -> void:
	temporary_shield = maxf(amount, 0.0)
	temporary_shield_time_left = maxf(duration, 0.0)
	shield_changed.emit(get_total_shield())


func get_total_shield() -> float:
	return shield + temporary_shield


func spend_health(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0.0 or current_health <= amount:
		return false
	current_health -= amount
	health_changed.emit()
	return true


func set_invulnerable(duration: float) -> void:
	invulnerable_time_left = maxf(invulnerable_time_left, duration)


func get_health_percent() -> float:
	if max_health <= 0:
		return 0
	return min(current_health / max_health, 1)


func check_death():
	if current_health == 0 and not death_emitted:
		death_emitted = true
		if get_parent().is_in_group("enemy"):
			GameEvents.enemy_defeated.emit(get_parent() as Node2D)
		died.emit()
		owner.queue_free()
