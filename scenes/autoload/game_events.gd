extends Node

signal experience_vial_collected(number: float)
signal ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary)
signal sword_hit_target(target: Node2D)
signal player_damaged
signal player_healed
signal enemy_defeated(enemy: Node2D)

var weapon_attack_count := 1
var base_weapon_attack_count := 1
var arena_difficulty := 0
var critical_chance := 0.0
var ability_critical_chance := 0.0
var meta_critical_chance := 0.0
var critical_damage_multiplier := 2.0
var critical_disabled := false
var speed_damage_no_crit := false
var life_steal_percent := 0.0
var auto_collect_experience := false
var player_damage_multiplier := 1.0
var support_damage_multiplier := 1.0
var support_health_multiplier := 1.0
var support_move_speed_multiplier := 1.0
var support_size_multiplier := 1.0
var support_attack_interval_multiplier := 1.0
var support_weapon_attack_count_bonus := 0
var weapon_damage := {}
var weapon_types: Dictionary = {}
var last_damage_source := "未知伤害"
var game_mode := "campaign"
var campaign_completed_maps := 0
var challenge_attack_interval_multiplier := 1.0
var challenge_experience_multiplier := 1.0
var curse_enemy_health_multiplier := 1.0
var curse_enemy_speed_multiplier := 1.0
var curse_experience_multiplier := 1.0
var curse_weapon_damage_multiplier := 1.0
var curse_attack_interval_multiplier := 1.0
var curse_player_health_multiplier := 1.0
var curse_player_speed_multiplier := 1.0
var curse_elite_interval_multiplier := 1.0
var curse_summon_cooldown_multiplier := 1.0
var curse_summon_count_multiplier := 1.0
var curse_summon_health_multiplier := 1.0
var curse_no_normal_healing := false
var curse_boost_next_upgrade := false
var active_curses: Array[String] = []
const MAX_ENEMIES := 30


func get_enemy_count(bosses_only: bool = false) -> int:
	var count := 0
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if bosses_only and not enemy.is_in_group("boss"):
			continue
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if not enemy.is_queued_for_deletion() and (health == null or health.current_health > 0):
			count += 1
	return count


func can_spawn_enemy(is_boss: bool = false) -> bool:
	var count := get_enemy_count()
	return count < MAX_ENEMIES and (is_boss or count - get_enemy_count(true) < MAX_ENEMIES - 2)


func get_campaign_enemy_health(base_health: float, is_boss: bool = false) -> float:
	if is_boss:
		return 2200.0 * (1.0 + campaign_completed_maps * 0.75)
	var normalized_health := clampf(12.0 * sqrt(maxf(base_health, 1.0) / 10.0), 12.0, 25.0)
	# Arena difficulty ticks every five seconds; health grows every two ticks.
	return normalized_health * (1.0 + campaign_completed_maps * 0.65) * (1.0 + floori(arena_difficulty / 2.0) * 0.025)


func get_campaign_damage_multiplier() -> float:
	return minf(0.65 + campaign_completed_maps * 0.1, 2.0)


func get_enemy_damage(enemy: Node, base_damage: float) -> float:
	return base_damage * float(enemy.get_meta("damage_multiplier", 1.0))


func has_curse(curse_id: String) -> bool:
	return active_curses.has(curse_id)


func get_curse_experience_multiplier_at(point: Vector2) -> float:
	var manager := get_tree().get_first_node_in_group("curse_manager")
	return manager.experience_multiplier_at(point) if manager != null else 1.0


func configure_summon(summon: Node2D, summoner: Node2D) -> void:
	summon.set_meta("curse_summon", true)
	summon.set_meta("summoner_id", summoner.get_instance_id())
	var health := summon.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.max_health *= curse_summon_health_multiplier
		health.current_health = health.max_health


func get_campaign_spawn_count() -> int:
	# ponytail: cap simultaneous batches at six; raise only after profiling crowded maps.
	return mini(1 + floori(campaign_completed_maps / 2.0), 6)


func is_endless_mode() -> bool:
	return game_mode == "endless"


func wait_for_combat_frame() -> void:
	await get_tree().process_frame
	while get_tree().paused:
		await get_tree().process_frame


func emit_experience_vial_collected(number: float):
	experience_vial_collected.emit(number)


func reset_run_stats() -> void:
	challenge_attack_interval_multiplier = 1.0
	challenge_experience_multiplier = 1.0
	curse_enemy_health_multiplier = 1.0
	curse_enemy_speed_multiplier = 1.0
	curse_experience_multiplier = 1.0
	curse_weapon_damage_multiplier = 1.0
	curse_attack_interval_multiplier = 1.0
	curse_player_health_multiplier = 1.0
	curse_player_speed_multiplier = 1.0
	curse_elite_interval_multiplier = 1.0
	curse_summon_cooldown_multiplier = 1.0
	curse_summon_count_multiplier = 1.0
	curse_summon_health_multiplier = 1.0
	curse_no_normal_healing = false
	curse_boost_next_upgrade = false
	active_curses.clear()
	campaign_completed_maps = 0
	weapon_attack_count = 1
	base_weapon_attack_count = 1
	support_damage_multiplier = 1.0
	support_health_multiplier = 1.0
	support_move_speed_multiplier = 1.0
	support_size_multiplier = 1.0
	support_attack_interval_multiplier = 1.0
	support_weapon_attack_count_bonus = 0
	auto_collect_experience = false
	weapon_damage.clear()
	weapon_types.clear()
	last_damage_source = "未知伤害"


func record_weapon_damage(weapon_id: String, damage: float) -> void:
	if weapon_id.is_empty() or damage <= 0.0:
		return
	weapon_damage[weapon_id] = weapon_damage.get(weapon_id, 0.0) + damage


func emit_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "attack_count":
		base_weapon_attack_count = current_upgrades[upgrade.id]["quantity"] + 1
		weapon_attack_count = base_weapon_attack_count + support_weapon_attack_count_bonus
	elif upgrade.id == "critical_hit":
		ability_critical_chance = current_upgrades[upgrade.id]["quantity"] * 0.05
		refresh_critical_chance()
	elif upgrade.id == "critical_damage":
		critical_damage_multiplier = 2.0 + current_upgrades[upgrade.id]["quantity"] * 0.2
	elif upgrade.id == "speed_damage_no_crit":
		speed_damage_no_crit = true
		critical_disabled = true
		refresh_critical_chance()
	elif upgrade.id == "auto_collect_experience":
		auto_collect_experience = true
		for vial: Node in get_tree().get_nodes_in_group("experience_vial"):
			vial.call("collect_to_player")
	ability_upgrade_added.emit(upgrade, current_upgrades)


func refresh_critical_chance() -> void:
	critical_chance = 0.0 if critical_disabled else ability_critical_chance + meta_critical_chance


func get_critical_damage(damage: float, weapon_id: String = "") -> Dictionary:
	var critical := not critical_disabled and randf() < critical_chance
	var character_multiplier := get_character_damage_multiplier(weapon_id)
	return {"damage": damage * player_damage_multiplier * support_damage_multiplier * character_multiplier * (critical_damage_multiplier if critical else 1.0) + get_character_damage_bonus(), "critical": critical}


func get_character_passives() -> CharacterPassives:
	var player := get_tree().get_first_node_in_group("player")
	return player.get_node_or_null("CharacterPassives") as CharacterPassives if player != null else null


func get_character_damage_multiplier(weapon_id: String) -> float:
	var passives := get_character_passives()
	return passives.get_damage_multiplier(weapon_id) if passives != null else 1.0


func get_character_attack_speed_multiplier() -> float:
	var passives := get_character_passives()
	return passives.character.weapon_attack_speed_multiplier if passives != null and passives.character != null else 1.0


func get_character_damage_bonus() -> float:
	var passives := get_character_passives()
	return passives.get_damage_bonus() if passives != null else 0.0


func heal_from_damage(damage: float) -> void:
	if life_steal_percent <= 0.0:
		return
	var player: Node = get_tree().get_first_node_in_group("player") as Node
	if player == null:
		return
	var health_component: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if health_component != null:
		health_component.heal(damage * life_steal_percent, "life_steal")


func emit_player_damaged():
	player_damaged.emit()


func emit_player_healed():
	player_healed.emit()
