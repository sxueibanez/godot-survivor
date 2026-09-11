extends Node

signal experience_vial_collected(number: float)
signal ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary)
signal sword_hit_target(target: Node2D)
signal player_damaged
signal player_healed

var weapon_attack_count := 1
var arena_difficulty := 0
var critical_chance := 0.0
var ability_critical_chance := 0.0
var meta_critical_chance := 0.0
var critical_damage_multiplier := 2.0
var critical_disabled := false
var speed_damage_no_crit := false
var life_steal_percent := 0.0
var player_damage_multiplier := 1.0
var weapon_damage := {}
var last_damage_source := "未知伤害"
var game_mode := "campaign"


func is_endless_mode() -> bool:
	return game_mode == "endless"


func emit_experience_vial_collected(number: float):
	experience_vial_collected.emit(number)


func reset_run_stats() -> void:
	weapon_damage.clear()
	last_damage_source = "未知伤害"


func record_weapon_damage(weapon_id: String, damage: float) -> void:
	if weapon_id.is_empty() or damage <= 0.0:
		return
	weapon_damage[weapon_id] = weapon_damage.get(weapon_id, 0.0) + damage


func emit_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "attack_count":
		weapon_attack_count = current_upgrades[upgrade.id]["quantity"] + 1
	elif upgrade.id == "critical_hit":
		ability_critical_chance = current_upgrades[upgrade.id]["quantity"] * 0.05
		refresh_critical_chance()
	elif upgrade.id == "critical_damage":
		critical_damage_multiplier = 2.0 + current_upgrades[upgrade.id]["quantity"] * 0.2
	elif upgrade.id == "speed_damage_no_crit":
		speed_damage_no_crit = true
		critical_disabled = true
		refresh_critical_chance()
	ability_upgrade_added.emit(upgrade, current_upgrades)


func refresh_critical_chance() -> void:
	critical_chance = 0.0 if critical_disabled else ability_critical_chance + meta_critical_chance


func get_critical_damage(damage: float) -> Dictionary:
	var critical := not critical_disabled and randf() < critical_chance
	return {"damage": damage * player_damage_multiplier * (critical_damage_multiplier if critical else 1.0), "critical": critical}


func heal_from_damage(damage: float) -> void:
	if life_steal_percent <= 0.0:
		return
	var player: Node = get_tree().get_first_node_in_group("player") as Node
	if player == null:
		return
	var health_component: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if health_component != null:
		health_component.heal(damage * life_steal_percent)


func emit_player_damaged():
	player_damaged.emit()


func emit_player_healed():
	player_healed.emit()
