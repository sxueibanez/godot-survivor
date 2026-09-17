extends Node

signal initial_choices_completed

@export var experience_manager: ExperienceManager
@export var upgrade_screen_scene: PackedScene

var current_upgrades = {}
var upgrade_pool: WeightedTable = WeightedTable.new()
var weapon_pool: WeightedTable = WeightedTable.new()

var upgrade_axe := preload("res://resources/upgrades/axe.tres")
var upgrade_sword := preload("res://resources/upgrades/sword.tres")
var upgrade_axe_damage := preload("res://resources/upgrades/axe_damage.tres")
var upgrade_axe_reflect := preload("res://resources/upgrades/axe_reflect.tres")
var upgrade_axe_count := preload("res://resources/upgrades/axe_count.tres")
var upgrade_axe_return := preload("res://resources/upgrades/axe_return.tres")
var upgrade_axe_knockback := preload("res://resources/upgrades/axe_knockback.tres")
var upgrade_axe_distance_power := preload("res://resources/upgrades/axe_distance_power.tres")
var upgrade_axe_size := preload("res://resources/upgrades/axe_size.tres")
var upgrade_axe_rate := preload("res://resources/upgrades/axe_rate.tres")
var upgrade_sword_rate := preload("res://resources/upgrades/sword_rate.tres")
var upgrade_sword_damage := preload("res://resources/upgrades/sword_damage.tres")
var upgrade_sword_size := preload("res://resources/upgrades/sword_size.tres")
var upgrade_sword_chain := preload("res://resources/upgrades/sword_chain.tres")
var upgrade_sword_rain := preload("res://resources/upgrades/sword_rain.tres")
var upgrade_sword_rain_giant := preload("res://resources/upgrades/sword_rain_giant.tres")
var upgrade_sword_barrage := preload("res://resources/upgrades/sword_barrage.tres")
var upgrade_sword_greatsword_sweep := preload("res://resources/upgrades/sword_greatsword_sweep.tres")
var upgrade_player_speed := preload("res://resources/upgrades/player_speed.tres")
var upgrade_player_health := preload("res://resources/upgrades/player_health.tres")
var upgrade_critical_hit := preload("res://resources/upgrades/critical_hit.tres")
var upgrade_critical_damage := preload("res://resources/upgrades/critical_damage.tres")
var upgrade_speed_damage_no_crit := preload("res://resources/upgrades/speed_damage_no_crit.tres")
var upgrade_auto_collect_experience := preload("res://resources/upgrades/auto_collect_experience.tres")
var upgrade_laser_gun := preload("res://resources/upgrades/laser_gun.tres")
var upgrade_laser_gun_damage := preload("res://resources/upgrades/laser_gun_damage.tres")
var upgrade_laser_gun_size := preload("res://resources/upgrades/laser_gun_size.tres")
var upgrade_laser_gun_cooldown := preload("res://resources/upgrades/laser_gun_cooldown.tres")
var upgrade_laser_gun_damage_ramp := preload("res://resources/upgrades/laser_gun_damage_ramp.tres")
var upgrade_laser_gun_reflect := preload("res://resources/upgrades/laser_gun_reflect.tres")
var upgrade_laser_gun_stun := preload("res://resources/upgrades/laser_gun_stun.tres")
var upgrade_laser_gun_auto_aim := preload("res://resources/upgrades/laser_gun_auto_aim.tres")
var upgrade_laser_gun_kill_duration := preload("res://resources/upgrades/laser_gun_kill_duration.tres")
var upgrade_attack_count := preload("res://resources/upgrades/attack_count.tres")
var upgrade_lightning_whip := preload("res://resources/upgrades/lightning_whip.tres")
var upgrade_lightning_whip_damage := preload("res://resources/upgrades/lightning_whip_damage.tres")
var upgrade_lightning_whip_size := preload("res://resources/upgrades/lightning_whip_size.tres")
var upgrade_lightning_whip_rate := preload("res://resources/upgrades/lightning_whip_rate.tres")
var upgrade_lightning_chain := preload("res://resources/upgrades/lightning_chain.tres")
var upgrade_lightning_cloud := preload("res://resources/upgrades/lightning_cloud.tres")
var upgrade_lightning_wide_arc := preload("res://resources/upgrades/lightning_wide_arc.tres")
var upgrade_bomb := preload("res://resources/upgrades/bomb.tres")
var upgrade_bomb_bounce := preload("res://resources/upgrades/bomb_bounce.tres")
var upgrade_bomb_burn := preload("res://resources/upgrades/bomb_burn.tres")
var upgrade_bomb_cluster := preload("res://resources/upgrades/bomb_cluster.tres")
var upgrade_bomb_heat_reaction := preload("res://resources/upgrades/bomb_heat_reaction.tres")
var upgrade_bomb_giant_charge := preload("res://resources/upgrades/bomb_giant_charge.tres")
var upgrade_bomb_damage := preload("res://resources/upgrades/bomb_damage.tres")
var upgrade_bomb_size := preload("res://resources/upgrades/bomb_size.tres")
var upgrade_bomb_rate := preload("res://resources/upgrades/bomb_rate.tres")
var upgrade_thunder_orb_book := preload("res://resources/upgrades/thunder_orb_book.tres")
var upgrade_thunder_orb_chain := preload("res://resources/upgrades/thunder_orb_chain.tres")
var upgrade_thunder_orb_count := preload("res://resources/upgrades/thunder_orb_count.tres")
var upgrade_thunder_orb_growth := preload("res://resources/upgrades/thunder_orb_growth.tres")
var upgrade_thunder_orb_plasma := preload("res://resources/upgrades/thunder_orb_plasma.tres")
var upgrade_thunder_orb_boss_tracking := preload("res://resources/upgrades/thunder_orb_boss_tracking.tres")
var upgrade_thunder_orb_damage := preload("res://resources/upgrades/thunder_orb_damage.tres")
var upgrade_thunder_orb_size := preload("res://resources/upgrades/thunder_orb_size.tres")
var upgrade_thunder_orb_rate := preload("res://resources/upgrades/thunder_orb_rate.tres")
var upgrade_azure_dragon := preload("res://resources/upgrades/azure_dragon.tres")
var upgrade_azure_dragon_damage := preload("res://resources/upgrades/azure_dragon_damage.tres")
var upgrade_azure_dragon_size := preload("res://resources/upgrades/azure_dragon_size.tres")
var upgrade_azure_dragon_rate := preload("res://resources/upgrades/azure_dragon_rate.tres")
var upgrade_azure_dragon_vermilion_bird := preload("res://resources/upgrades/azure_dragon_vermilion_bird.tres")
var upgrade_azure_dragon_xuanwu := preload("res://resources/upgrades/azure_dragon_xuanwu.tres")
var upgrade_azure_dragon_white_tiger := preload("res://resources/upgrades/azure_dragon_white_tiger.tres")
var upgrade_azure_dragon_four_beasts := preload("res://resources/upgrades/azure_dragon_four_beasts.tres")
var upgrade_nine_treasure_pagoda := preload("res://resources/upgrades/nine_treasure_pagoda.tres")
var upgrade_nine_treasure_pagoda_damage := preload("res://resources/upgrades/nine_treasure_pagoda_damage.tres")
var upgrade_nine_treasure_pagoda_size := preload("res://resources/upgrades/nine_treasure_pagoda_size.tres")
var upgrade_nine_treasure_pagoda_rate := preload("res://resources/upgrades/nine_treasure_pagoda_rate.tres")
var upgrade_nine_treasure_damage := preload("res://resources/upgrades/nine_treasure_damage.tres")
var upgrade_nine_treasure_attack_speed := preload("res://resources/upgrades/nine_treasure_attack_speed.tres")
var upgrade_nine_treasure_health := preload("res://resources/upgrades/nine_treasure_health.tres")
var upgrade_nine_treasure_move_speed := preload("res://resources/upgrades/nine_treasure_move_speed.tres")
var upgrade_nine_treasure_extra_attack := preload("res://resources/upgrades/nine_treasure_extra_attack.tres")
var upgrade_heaven_shaking_hammer := preload("res://resources/upgrades/heaven_shaking_hammer.tres")
var upgrade_heaven_shaking_hammer_damage := preload("res://resources/upgrades/heaven_shaking_hammer_damage.tres")
var upgrade_heaven_shaking_hammer_size := preload("res://resources/upgrades/heaven_shaking_hammer_size.tres")
var upgrade_heaven_shaking_hammer_rate := preload("res://resources/upgrades/heaven_shaking_hammer_rate.tres")
var upgrade_heaven_shaking_hammer_extra_wave := preload("res://resources/upgrades/heaven_shaking_hammer_extra_wave.tres")
var upgrade_heaven_shaking_hammer_lava := preload("res://resources/upgrades/heaven_shaking_hammer_lava.tres")
var upgrade_heaven_shaking_hammer_pull := preload("res://resources/upgrades/heaven_shaking_hammer_pull.tres")
var upgrade_heaven_shaking_hammer_heavy := preload("res://resources/upgrades/heaven_shaking_hammer_heavy.tres")
var upgrade_sniper_rifle := preload("res://resources/upgrades/sniper_rifle.tres")
var upgrade_sniper_rifle_damage := preload("res://resources/upgrades/sniper_rifle_damage.tres")
var upgrade_sniper_rifle_size := preload("res://resources/upgrades/sniper_rifle_size.tres")
var upgrade_sniper_rifle_rate := preload("res://resources/upgrades/sniper_rifle_rate.tres")
var upgrade_sniper_rifle_diamond_bullet := preload("res://resources/upgrades/sniper_rifle_diamond_bullet.tres")
var upgrade_sniper_rifle_scope := preload("res://resources/upgrades/sniper_rifle_scope.tres")
var upgrade_sniper_rifle_shadowless_bullet := preload("res://resources/upgrades/sniper_rifle_shadowless_bullet.tres")
var upgrade_sniper_rifle_ricochet := preload("res://resources/upgrades/sniper_rifle_ricochet.tres")
var upgrade_sniper_rifle_explosive_bullet := preload("res://resources/upgrades/sniper_rifle_explosive_bullet.tres")

var rng := RandomNumberGenerator.new()
var weapon_upgrades: Array[Ability] = [upgrade_sword, upgrade_axe, upgrade_laser_gun, upgrade_lightning_whip, upgrade_bomb, upgrade_thunder_orb_book, upgrade_azure_dragon, upgrade_nine_treasure_pagoda, upgrade_heaven_shaking_hammer, upgrade_sniper_rifle]
var initial_choices_remaining := 0
var pending_upgrade_choices := 0
var choice_screen_open := false
var pending_challenge_rewards: Array[int] = []
var disabled_upgrade_ids: Dictionary = {}


func _ready():
	GameEvents.reset_run_stats()
	GameEvents.weapon_attack_count = 1
	GameEvents.ability_critical_chance = 0.0
	GameEvents.meta_critical_chance = MetaProgression.get_upgrade_count("meta_critical_chance") * 0.01
	GameEvents.critical_damage_multiplier = 2.0
	GameEvents.critical_disabled = false
	GameEvents.speed_damage_no_crit = false
	GameEvents.life_steal_percent = MetaProgression.get_upgrade_count("meta_life_steal") * 0.01
	GameEvents.refresh_critical_chance()
	upgrade_pool.add_item(upgrade_player_speed, 5)
	upgrade_pool.add_item(upgrade_player_health, 8)
	upgrade_pool.add_item(upgrade_critical_hit, 8)
	upgrade_pool.add_item(upgrade_critical_damage, 5)
	upgrade_pool.add_item(upgrade_speed_damage_no_crit, 5)
	upgrade_pool.add_item(upgrade_auto_collect_experience, 5)
	upgrade_pool.add_item(upgrade_attack_count, 5)
	for weapon: Ability in weapon_upgrades:
		weapon_pool.add_item(weapon, 10)

	experience_manager.level_up.connect(on_level_up)


func start_initial_choices(choice_rounds: int = 1) -> void:
	initial_choices_remaining = maxi(choice_rounds, 0) + clampi(MetaProgression.get_upgrade_count("meta_initial_choices"), 0, 1)
	if initial_choices_remaining == 0:
		initial_choices_completed.emit()
		return
	show_initial_weapon_choices()


func apply_upgrade(upgrade: AbilityUpgrade):
	if upgrade is Ability and (current_upgrades.has(upgrade.id) or get_weapon_count() >= get_weapon_limit()):
		return
	var has_upgrade = current_upgrades.has(upgrade.id)
	if not has_upgrade:
		current_upgrades[upgrade.id] = {
			"resource": upgrade,
			"quantity": 1,
		}
	else:
		current_upgrades[upgrade.id]["quantity"] += 1
	
	# quantity check -> pool 에서 빼버림
	if upgrade.max_quantity > 0:
		var current_quantity = current_upgrades[upgrade.id]["quantity"]
		if current_quantity >= upgrade.max_quantity:
			upgrade_pool.remove_item(upgrade)

	if upgrade is Ability:
		weapon_pool.remove_item(upgrade)
		update_weapon_pool()
	update_upgrade_pool(upgrade)
	GameEvents.emit_ability_upgrade_added(upgrade, current_upgrades)


func update_upgrade_pool(chosen_upgrade: AbilityUpgrade):
	if chosen_upgrade.id == upgrade_speed_damage_no_crit.id:
		upgrade_pool.remove_item(upgrade_critical_hit)
		upgrade_pool.remove_item(upgrade_critical_damage)
	elif chosen_upgrade.id == upgrade_sword.id:
		upgrade_pool.add_item(upgrade_sword_rate, 10)
		upgrade_pool.add_item(upgrade_sword_damage, 10)
		upgrade_pool.add_item(upgrade_sword_size, 10)
		add_unlocked_special(upgrade_sword_chain, "tree_sword_chain", 5)
		add_unlocked_special(upgrade_sword_rain, "tree_sword_rain", 5)
		add_unlocked_special(upgrade_sword_rain_giant, "tree_sword_rain_giant", 5)
		add_unlocked_special(upgrade_sword_barrage, "tree_sword_barrage", 5)
		add_unlocked_special(upgrade_sword_greatsword_sweep, "tree_sword_greatsword_sweep", 5)
	elif chosen_upgrade.id == upgrade_axe.id:
		upgrade_pool.add_item(upgrade_axe_damage, 10)
		upgrade_pool.add_item(upgrade_axe_size, 10)
		upgrade_pool.add_item(upgrade_axe_rate, 10)
		add_unlocked_special(upgrade_axe_reflect, "tree_axe_reflect", 8)
		add_unlocked_special(upgrade_axe_count, "tree_axe_count", 10)
		add_unlocked_special(upgrade_axe_return, "tree_axe_return", 8)
		add_unlocked_special(upgrade_axe_knockback, "tree_axe_knockback", 8)
		add_unlocked_special(upgrade_axe_distance_power, "tree_axe_distance_power", 8)
	elif chosen_upgrade.id == upgrade_laser_gun.id:
		upgrade_pool.add_item(upgrade_laser_gun_damage, 10)
		upgrade_pool.add_item(upgrade_laser_gun_size, 10)
		upgrade_pool.add_item(upgrade_laser_gun_cooldown, 10)
		add_unlocked_special(upgrade_laser_gun_damage_ramp, "tree_laser_ramp", 8)
		add_unlocked_special(upgrade_laser_gun_reflect, "tree_laser_reflect", 8)
		add_unlocked_special(upgrade_laser_gun_stun, "tree_laser_stun", 8)
		add_unlocked_special(upgrade_laser_gun_auto_aim, "tree_laser_auto_aim", 8)
		add_unlocked_special(upgrade_laser_gun_kill_duration, "tree_laser_kill_duration", 8)
	elif chosen_upgrade.id == upgrade_lightning_whip.id:
		upgrade_pool.add_item(upgrade_lightning_whip_damage, 10)
		upgrade_pool.add_item(upgrade_lightning_whip_size, 10)
		upgrade_pool.add_item(upgrade_lightning_whip_rate, 10)
		add_unlocked_special(upgrade_lightning_chain, "tree_lightning_chain", 5)
		add_unlocked_special(upgrade_lightning_cloud, "tree_lightning_cloud", 5)
		add_unlocked_special(upgrade_lightning_wide_arc, "tree_lightning_wide_arc", 5)
	elif chosen_upgrade.id == upgrade_bomb.id:
		upgrade_pool.add_item(upgrade_bomb_damage, 10)
		upgrade_pool.add_item(upgrade_bomb_size, 10)
		upgrade_pool.add_item(upgrade_bomb_rate, 10)
		add_unlocked_special(upgrade_bomb_bounce, "tree_bomb_bounce", 8)
		add_unlocked_special(upgrade_bomb_burn, "tree_bomb_burn", 8)
		add_unlocked_special(upgrade_bomb_cluster, "tree_bomb_cluster", 8)
		add_unlocked_special(upgrade_bomb_heat_reaction, "tree_bomb_heat_reaction", 8)
		add_unlocked_special(upgrade_bomb_giant_charge, "tree_bomb_giant_charge", 8)
	elif chosen_upgrade.id == upgrade_thunder_orb_book.id:
		upgrade_pool.add_item(upgrade_thunder_orb_damage, 10)
		upgrade_pool.add_item(upgrade_thunder_orb_size, 10)
		upgrade_pool.add_item(upgrade_thunder_orb_rate, 10)
		add_unlocked_special(upgrade_thunder_orb_chain, "tree_thunder_orb_chain", 8)
		add_unlocked_special(upgrade_thunder_orb_count, "tree_thunder_orb_count", 10)
		add_unlocked_special(upgrade_thunder_orb_growth, "tree_thunder_orb_growth", 8)
		add_unlocked_special(upgrade_thunder_orb_plasma, "tree_thunder_orb_plasma", 8)
		add_unlocked_special(upgrade_thunder_orb_boss_tracking, "tree_thunder_orb_boss_tracking", 8)
	elif chosen_upgrade.id == upgrade_azure_dragon.id:
		upgrade_pool.add_item(upgrade_azure_dragon_damage, 10)
		upgrade_pool.add_item(upgrade_azure_dragon_size, 10)
		upgrade_pool.add_item(upgrade_azure_dragon_rate, 10)
		add_unlocked_special(upgrade_azure_dragon_vermilion_bird, "tree_azure_dragon_vermilion_bird", 8)
		add_unlocked_special(upgrade_azure_dragon_xuanwu, "tree_azure_dragon_xuanwu", 8)
		add_unlocked_special(upgrade_azure_dragon_white_tiger, "tree_azure_dragon_white_tiger", 8)
	elif chosen_upgrade.id == upgrade_nine_treasure_pagoda.id:
		upgrade_pool.add_item(upgrade_nine_treasure_pagoda_damage, 10)
		upgrade_pool.add_item(upgrade_nine_treasure_pagoda_size, 10)
		upgrade_pool.add_item(upgrade_nine_treasure_pagoda_rate, 10)
		add_unlocked_special(upgrade_nine_treasure_damage, "tree_nine_treasure_damage", 8)
		add_unlocked_special(upgrade_nine_treasure_attack_speed, "tree_nine_treasure_attack_speed", 8)
		add_unlocked_special(upgrade_nine_treasure_health, "tree_nine_treasure_health", 8)
		add_unlocked_special(upgrade_nine_treasure_move_speed, "tree_nine_treasure_move_speed", 8)
		add_unlocked_special(upgrade_nine_treasure_extra_attack, "tree_nine_treasure_extra_attack", 8)
	elif chosen_upgrade.id == upgrade_heaven_shaking_hammer.id:
		upgrade_pool.add_item(upgrade_heaven_shaking_hammer_damage, 10)
		upgrade_pool.add_item(upgrade_heaven_shaking_hammer_size, 10)
		upgrade_pool.add_item(upgrade_heaven_shaking_hammer_rate, 10)
		add_unlocked_special(upgrade_heaven_shaking_hammer_extra_wave, "tree_heaven_shaking_hammer_extra_wave", 8)
		add_unlocked_special(upgrade_heaven_shaking_hammer_lava, "tree_heaven_shaking_hammer_lava", 8)
		add_unlocked_special(upgrade_heaven_shaking_hammer_pull, "tree_heaven_shaking_hammer_pull", 8)
		add_unlocked_special(upgrade_heaven_shaking_hammer_heavy, "tree_heaven_shaking_hammer_heavy", 8)
	elif chosen_upgrade.id == upgrade_sniper_rifle.id:
		upgrade_pool.add_item(upgrade_sniper_rifle_damage, 10)
		upgrade_pool.add_item(upgrade_sniper_rifle_size, 10)
		upgrade_pool.add_item(upgrade_sniper_rifle_rate, 10)
		add_unlocked_special(upgrade_sniper_rifle_diamond_bullet, "tree_sniper_rifle_diamond_bullet", 8)
		add_unlocked_special(upgrade_sniper_rifle_scope, "tree_sniper_rifle_scope", 8)
		add_unlocked_special(upgrade_sniper_rifle_shadowless_bullet, "tree_sniper_rifle_shadowless_bullet", 8)
		add_unlocked_special(upgrade_sniper_rifle_ricochet, "tree_sniper_rifle_ricochet", 8)
		add_unlocked_special(upgrade_sniper_rifle_explosive_bullet, "tree_sniper_rifle_explosive_bullet", 8)
	elif chosen_upgrade.id in [upgrade_azure_dragon_vermilion_bird.id, upgrade_azure_dragon_xuanwu.id, upgrade_azure_dragon_white_tiger.id]:
		try_unlock_four_beasts_upgrade()


func add_unlocked_special(upgrade: AbilityUpgrade, tree_skill_id: String, weight: int) -> void:
	if MetaProgression.get_weapon_skill_count(tree_skill_id) > 0 and not disabled_upgrade_ids.has(upgrade.id):
		upgrade_pool.add_item(upgrade, weight)


func try_unlock_four_beasts_upgrade() -> void:
	if MetaProgression.get_weapon_skill_count("tree_azure_dragon_four_beasts") == 0 or disabled_upgrade_ids.has(upgrade_azure_dragon_four_beasts.id):
		return
	for upgrade_id: String in ["azure_dragon_vermilion_bird", "azure_dragon_xuanwu", "azure_dragon_white_tiger"]:
		if not current_upgrades.has(upgrade_id):
			return
	upgrade_pool.add_item(upgrade_azure_dragon_four_beasts, 8)


func update_weapon_pool() -> void:
	if get_weapon_count() >= get_weapon_limit():
		for weapon: Ability in weapon_upgrades:
			upgrade_pool.remove_item(weapon)
			weapon_pool.remove_item(weapon)
		return
	for weapon: Ability in weapon_upgrades:
		if not current_upgrades.has(weapon.id) and not disabled_upgrade_ids.has(weapon.id):
			upgrade_pool.add_item(weapon, 10)


func get_weapon_limit() -> int:
	var player := get_tree().get_first_node_in_group("player")
	return int(player.character.weapon_limit) if player != null else 2


func get_weapon_count() -> int:
	var count := 0
	for upgrade_id: String in current_upgrades:
		var upgrade_data: Dictionary = current_upgrades[upgrade_id]
		if upgrade_data["resource"] is Ability:
			count += 1
	return count


func pick_upgrades(choice_count: int = 3) -> Array[AbilityUpgrade]:
	var chosen_upgrades: Array[AbilityUpgrade] = []
	for i in choice_count:
		if upgrade_pool.items.size() == chosen_upgrades.size():  # no more viable upgrade
			break

		var upgr = upgrade_pool.pick_item(chosen_upgrades)
		chosen_upgrades.append(upgr)

	return chosen_upgrades


## Get random upgrades from pool (up to 2), without duplicates
#func pick_upgrades() -> Array[AbilityUpgrade]:
	##assert(upgrade_pool.size() >= 2, "upgrade pool size should >= 2")
	#var picked := {}  # <index, null>
	#var next_idx: int
	#var max_pick_size: int = min(upgrade_pool.size(), 2)
	#if max_pick_size == 0:
		#return []
#
	#while true:
		#next_idx = rng.randi_range(0, upgrade_pool.size() - 1)
		#if picked.has(next_idx):
			#continue
		#
		#picked[next_idx] = null
		#
		#if picked.size() >= max_pick_size:
			#break
	#
	## https://github.com/godotengine/godot/issues/72566
	#var ret: Array[AbilityUpgrade]
	#ret.assign(picked.keys().map(func(i): return upgrade_pool[i]))
	#return ret


func on_level_up(current_level: int):
	show_upgrade_choices(3)


func show_initial_weapon_choices() -> void:
	show_choices(pick_weapon_upgrades(3))


func show_upgrade_choices(choice_count: int = 3) -> void:
	if upgrade_pool.items.is_empty():
		return
	if choice_screen_open:
		pending_upgrade_choices += 1
		return
	show_choices(pick_upgrades(choice_count), initial_choices_remaining == 0)


func pick_challenge_upgrades(choice_count: int) -> Array[AbilityUpgrade]:
	var special: Array[AbilityUpgrade] = []
	var common: Array[AbilityUpgrade] = []
	for entry: Dictionary in upgrade_pool.items:
		var upgrade := entry["item"] as AbilityUpgrade
		if special.has(upgrade) or common.has(upgrade):
			continue
		if upgrade is Ability or disabled_upgrade_ids.has(upgrade.id):
			continue
		for weapon: Ability in weapon_upgrades:
			var prefix := "thunder_orb" if weapon.id == "thunder_orb_book" else weapon.id
			if current_upgrades.has(weapon.id) and upgrade.id.begins_with(prefix + "_"):
				if upgrade.max_quantity == 1:
					special.append(upgrade)
				else:
					common.append(upgrade)
				break
	special.shuffle()
	common.shuffle()
	special.append_array(common)
	if special.is_empty():
		return pick_upgrades(choice_count)
	special.resize(mini(special.size(), choice_count))
	return special


func show_challenge_reward(choice_count: int = 3) -> void:
	if choice_screen_open:
		pending_challenge_rewards.append(choice_count)
	else:
		show_choices(pick_challenge_upgrades(choice_count))


func show_choices(chosen_upgrades: Array[AbilityUpgrade], allow_health_reroll: bool = false) -> void:
	if chosen_upgrades.is_empty():
		return
	choice_screen_open = true
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected.bind(upgrade_screen_instance))
	upgrade_screen_instance.upgrade_disabled.connect(on_upgrade_disabled.bind(upgrade_screen_instance))
	upgrade_screen_instance.closed_without_selection.connect(on_upgrade_screen_closed.bind(upgrade_screen_instance))
	var passives := GameEvents.get_character_passives()
	if allow_health_reroll and passives != null and passives.character.id == "gambling_scholar":
		upgrade_screen_instance.enable_health_reroll(passives.character.health_reroll_fraction)
		upgrade_screen_instance.health_reroll_requested.connect(on_health_reroll.bind(upgrade_screen_instance, chosen_upgrades.size()))


func on_health_reroll(screen: Node, choice_count: int) -> void:
	if screen.closing or screen.health_reroll_used:
		return
	var choices := pick_upgrades(choice_count)
	var passives := GameEvents.get_character_passives()
	if choices.is_empty() or passives == null or not passives.spend_reroll_health():
		return
	screen.health_reroll_used = true
	screen.health_reroll_button.disabled = true
	screen.health_reroll_button.text = "本次升级已刷新"
	screen.set_ability_upgrades(choices)


func pick_weapon_upgrades(choice_count: int) -> Array[AbilityUpgrade]:
	var chosen_upgrades: Array[AbilityUpgrade] = []
	for index in choice_count:
		if weapon_pool.items.size() == chosen_upgrades.size():
			break
		var chosen_upgrade: AbilityUpgrade = weapon_pool.pick_item(chosen_upgrades) as AbilityUpgrade
		chosen_upgrades.append(chosen_upgrade)
	return chosen_upgrades


func on_upgrade_selected(upgrade: AbilityUpgrade, upgrade_screen: Node = null):
	apply_upgrade(upgrade)
	var continue_initial_choices := false
	if initial_choices_remaining > 0:
		initial_choices_remaining -= 1
		continue_initial_choices = initial_choices_remaining > 0
		if initial_choices_remaining == 0:
			initial_choices_completed.emit()
	if upgrade_screen != null:
		await upgrade_screen.tree_exited
	choice_screen_open = false
	if continue_initial_choices:
		show_upgrade_choices(3)
	elif not pending_challenge_rewards.is_empty():
		show_challenge_reward(pending_challenge_rewards.pop_front())
	elif pending_upgrade_choices > 0:
		pending_upgrade_choices -= 1
		show_upgrade_choices(3)


func on_upgrade_disabled(upgrade: AbilityUpgrade, _upgrade_screen: Node = null) -> void:
	disable_upgrade_for_run(upgrade)


func disable_upgrade_for_run(upgrade: AbilityUpgrade) -> void:
	disabled_upgrade_ids[upgrade.id] = true
	upgrade_pool.remove_item(upgrade)
	weapon_pool.remove_item(upgrade)


func on_upgrade_screen_closed(upgrade_screen: Node) -> void:
	await upgrade_screen.tree_exited
	choice_screen_open = false
	if initial_choices_remaining > 0:
		if weapon_pool.items.is_empty():
			initial_choices_remaining = 0
			initial_choices_completed.emit()
		else:
			show_initial_weapon_choices()
	elif not pending_challenge_rewards.is_empty():
		show_challenge_reward(pending_challenge_rewards.pop_front())
	elif pending_upgrade_choices > 0:
		pending_upgrade_choices -= 1
		show_upgrade_choices(3)
