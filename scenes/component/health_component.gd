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
var last_damage_weapon_id := ""
var impact_cooldown := 0.0


func _ready():
	if get_parent().is_in_group("enemy"):
		if enemy_base_health <= 0.0:
			enemy_base_health = max_health
		if GameEvents.game_mode in ["campaign", "expedition"]:
			max_health = GameEvents.get_campaign_enemy_health(enemy_base_health, get_parent().is_in_group("boss"))
		elif GameEvents.game_mode == "boss_rush" and not get_parent().is_in_group("boss"):
			max_health = clampf(12.0 * sqrt(enemy_base_health / 10.0), 12.0, 25.0)
		if GameEvents.game_mode != "boss_rush":
			max_health *= MetaProgression.get_enemy_health_multiplier()
		if not get_parent().is_in_group("boss") and not get_parent().is_in_group("elite"):
			max_health *= GameEvents.curse_enemy_health_multiplier
	current_health = max_health


func _process(delta: float) -> void:
	invulnerable_time_left = maxf(invulnerable_time_left - delta, 0.0)
	impact_cooldown = maxf(impact_cooldown - delta, 0.0)
	if temporary_shield_time_left > 0.0:
		temporary_shield_time_left = maxf(temporary_shield_time_left - delta, 0.0)
		if temporary_shield_time_left <= 0.0:
			set_temporary_shield(0.0, 0.0)


func damage(damage_amount: float, source: String = "", source_position: Vector2 = Vector2.INF, damage_kind: String = "direct", source_weapon_id: String = "") -> bool:
	if get_tree().paused or current_health <= 0 or invulnerable_time_left > 0.0:
		return false
	if get_parent().is_in_group("player") and get_parent().has_method("is_dash_invulnerable") and get_parent().is_dash_invulnerable():
		return false
	if get_parent().has_method("modify_incoming_damage"):
		damage_amount = get_parent().modify_incoming_damage(damage_amount, source_position, damage_kind, source)
	if get_parent().is_in_group("player") and GameEvents.game_mode == "campaign":
		damage_amount *= GameEvents.get_campaign_damage_multiplier()
	if get_parent().is_in_group("player"):
		damage_amount *= GameEvents.expedition_incoming_multiplier
	if owner != null and owner.is_in_group("player") and not source.is_empty():
		var game_events := get_node_or_null("/root/GameEvents")
		if game_events != null:
			game_events.set("last_damage_source", source)
	if temporary_shield > 0.0:
		var absorbed := minf(temporary_shield, damage_amount)
		temporary_shield -= absorbed
		damage_amount -= absorbed
		if absorbed > 0.0 and get_parent().is_in_group("player"):
			show_impact("shield", source_position, false)
		shield_changed.emit(get_total_shield())
		if damage_amount <= 0.0:
			return false
	if shield > 0.0:
		var absorbed := minf(shield, damage_amount)
		shield -= absorbed
		damage_amount -= absorbed
		if absorbed > 0.0 and get_parent().is_in_group("player"):
			show_impact("shield", source_position, false)
		shield_changed.emit(get_total_shield())
		if damage_amount <= 0.0:
			return false
	# clamping
	var previous_health := current_health
	current_health = max(current_health - damage_amount, 0)
	if current_health < previous_health and (get_parent().is_in_group("enemy") or get_parent().is_in_group("player")):
		var impact_type := "player" if get_parent().is_in_group("player") else source_weapon_id
		show_impact(impact_type, source_position, previous_health - current_health >= max_health * 0.2)
	if get_parent().is_in_group("boss") and current_health < previous_health:
		last_damage_weapon_id = source_weapon_id
	health_changed.emit()
	damage_taken.emit(previous_health - current_health)
	Callable(check_death).call_deferred()
	return current_health == 0


func show_impact(weapon_id: String, source_position: Vector2, strong: bool) -> void:
	if impact_cooldown > 0.0 or get_tree().get_nodes_in_group("impact_spark").size() >= 40:
		return
	var layer := get_tree().get_first_node_in_group("combat_effects_layer") as Node2D
	var target := get_parent() as Node2D
	if layer == null or target == null:
		return
	impact_cooldown = 0.06
	var effect := preload("res://scenes/component/impact_spark.gd").new()
	effect.weapon_id = weapon_id
	effect.strong = strong
	if source_position.is_finite():
		var direction := source_position.direction_to(target.global_position)
		if direction != Vector2.ZERO:
			effect.direction = direction
	layer.add_child(effect)
	effect.global_position = target.global_position + Vector2.UP * 7.0


func heal(heal_amount: float, source: String = "normal"):
	if get_parent().is_in_group("player") and GameEvents.curse_no_normal_healing and source not in ["life_steal", "boss_reward", "elite_reward", "curse_reward", "max_health_upgrade"]:
		return
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
		# The main scene keeps the player briefly for the death dissolve animation.
		if not get_parent().is_in_group("player"):
			owner.queue_free()
