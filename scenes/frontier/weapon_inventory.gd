extends Node

const WEAPONS := {
	"sword": preload("res://resources/upgrades/sword.tres"),
	"axe": preload("res://resources/upgrades/axe.tres"),
	"laser_gun": preload("res://resources/upgrades/laser_gun.tres"),
	"lightning_whip": preload("res://resources/upgrades/lightning_whip.tres"),
	"bomb": preload("res://resources/upgrades/bomb.tres"),
	"thunder_orb_book": preload("res://resources/upgrades/thunder_orb_book.tres"),
	"azure_dragon": preload("res://resources/upgrades/azure_dragon.tres"),
	"nine_treasure_pagoda": preload("res://resources/upgrades/nine_treasure_pagoda.tres"),
	"heaven_shaking_hammer": preload("res://resources/upgrades/heaven_shaking_hammer.tres"),
	"sniper_rifle": preload("res://resources/upgrades/sniper_rifle.tres"),
}
const SKILLS := {
	"sword": ["sword_chain", "sword_barrage", "sword_greatsword_sweep", "sword_damage", "sword_size", "sword_rate"],
	"axe": ["axe_reflect", "axe_count", "axe_return", "axe_knockback", "axe_distance_power", "axe_damage", "axe_size", "axe_rate"],
	"laser_gun": ["laser_gun_damage_ramp", "laser_gun_reflect", "laser_gun_stun", "laser_gun_auto_aim", "laser_gun_kill_duration", "laser_gun_damage", "laser_gun_size", "laser_gun_cooldown"],
	"lightning_whip": ["lightning_chain", "lightning_cloud", "lightning_wide_arc", "lightning_paralysis", "lightning_whip_damage", "lightning_whip_size", "lightning_whip_rate"],
	"bomb": ["bomb_bounce", "bomb_burn", "bomb_cluster", "bomb_giant_charge", "bomb_implosion", "bomb_damage", "bomb_size", "bomb_rate"],
	"thunder_orb_book": ["thunder_orb_chain", "thunder_orb_count", "thunder_orb_growth", "thunder_orb_plasma", "thunder_orb_boss_tracking", "thunder_orb_damage", "thunder_orb_size", "thunder_orb_rate"],
	"azure_dragon": ["azure_dragon_vermilion_bird", "azure_dragon_xuanwu", "azure_dragon_white_tiger", "azure_dragon_damage", "azure_dragon_size", "azure_dragon_rate"],
	"nine_treasure_pagoda": ["nine_treasure_damage", "nine_treasure_attack_speed", "nine_treasure_health", "nine_treasure_move_speed", "nine_treasure_extra_attack", "nine_treasure_pagoda_damage", "nine_treasure_pagoda_size", "nine_treasure_pagoda_rate"],
	"heaven_shaking_hammer": ["heaven_shaking_hammer_extra_wave", "heaven_shaking_hammer_lava", "heaven_shaking_hammer_pull", "heaven_shaking_hammer_heavy", "heaven_shaking_hammer_aftershock", "heaven_shaking_hammer_damage", "heaven_shaking_hammer_size", "heaven_shaking_hammer_rate"],
	"sniper_rifle": ["sniper_rifle_diamond_bullet", "sniper_rifle_shadowless_bullet", "sniper_rifle_ricochet", "sniper_rifle_explosive_bullet", "sniper_rifle_damage", "sniper_rifle_size", "sniper_rifle_rate"],
}
const RARITY_NAMES := ["白色", "绿色", "蓝色", "紫色", "橙色"]
const RARITY_COLORS := [Color.WHITE, Color(0.42, 1.0, 0.48), Color(0.4, 0.72, 1.0), Color(0.84, 0.55, 1.0), Color(1.0, 0.66, 0.2)]
const CHEST_WEIGHTS := [[70, 24, 5, 1, 0], [25, 40, 25, 9, 1], [5, 15, 30, 35, 15]]

var player: Node
var rng := RandomNumberGenerator.new()
var items: Array = [null, null]
var controllers: Array = [null, null]
var xuanwu_save_used := false


func roll_rarity(chest_level: int) -> int:
	var weights: Array = CHEST_WEIGHTS[clampi(chest_level, 1, 3) - 1]
	var roll := rng.randi_range(1, 100)
	for index in weights.size():
		roll -= int(weights[index])
		if roll <= 0:
			return index + 1
	return 5


func roll_skills(weapon_id: String, rarity: int) -> Array:
	var pool: Array = SKILLS[weapon_id].duplicate()
	var chosen: Array = []
	for index in clampi(rarity, 1, 5):
		var pick := rng.randi_range(0, pool.size() - 1)
		chosen.append(pool[pick])
		pool.remove_at(pick)
	return chosen


func make_weapon(chest_level: int) -> Dictionary:
	var ids := WEAPONS.keys()
	var id: String = ids[rng.randi_range(0, ids.size() - 1)]
	var rarity := roll_rarity(chest_level)
	return {"id": id, "rarity": rarity, "skills": roll_skills(id, rarity)}


func equip(item: Dictionary, slot: int) -> void:
	if not can_equip(item, slot):
		return
	items[slot] = item.duplicate(true)
	rebuild(slot)


func can_equip(item: Dictionary, slot: int) -> bool:
	if slot < 0 or slot >= mini(items.size(), int(player.character.get("weapon_limit"))):
		return false
	if item.id in ["azure_dragon", "nine_treasure_pagoda"]:
		for index in items.size():
			if index != slot and items[index] != null and items[index].id == item.id:
				return false
	return true


func rebuild(slot: int) -> void:
	if is_instance_valid(controllers[slot]):
		if controllers[slot] is AzureDragonController:
			var dragon_controller: AzureDragonController = controllers[slot]
			if dragon_controller.four_beasts_active:
				dragon_controller.end_four_beasts_rush()
			if is_instance_valid(dragon_controller.xuanwu):
				xuanwu_save_used = xuanwu_save_used or dragon_controller.xuanwu.death_save_used
			for companion: Node in [dragon_controller.dragon, dragon_controller.vermilion_bird, dragon_controller.xuanwu, dragon_controller.white_tiger]:
				if is_instance_valid(companion):
					companion.queue_free()
		if controllers[slot] is NineTreasurePagodaController:
			remove_pagoda_buffs(controllers[slot])
		if controllers[slot].get_script().resource_path == "res://scenes/ability/heaven_shaking_hammer_controller/heaven_shaking_hammer_controller.gd" and is_instance_valid(controllers[slot].charge_label):
			controllers[slot].get("charge_label").queue_free()
		player.abilities.remove_child(controllers[slot])
		controllers[slot].queue_free()
	var item: Dictionary = items[slot]
	var weapon: Ability = WEAPONS[item.id]
	var controller: Node = weapon.ability_controller_scene.instantiate()
	controller.character_damage_multiplier = player.character.get_weapon_damage_multiplier(weapon)
	player.abilities.add_child(controller)
	controllers[slot] = controller
	GameEvents.weapon_types[weapon.id] = weapon.weapon_type
	var tier: int = item.rarity
	var damage_factor := 1.0 + 0.30 * (tier - 1)
	var size_factor := 1.0 + 0.08 * (tier - 1)
	var interval_factor := 1.0 - 0.06 * (tier - 1)
	var skills: Array = item.skills
	var stat_prefix: String = "thunder_orb" if item.id == "thunder_orb_book" else item.id
	if skills.has(stat_prefix + "_damage"):
		damage_factor *= 1.05
	if skills.has(stat_prefix + "_size"):
		size_factor *= 1.05
	if skills.has(stat_prefix + "_rate") or skills.has(stat_prefix + "_cooldown"):
		interval_factor *= 0.95
	match item.id:
		"sword":
			controller.additional_damage_percent = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.get_node("Timer").wait_time = controller.base_wait_time * controller.permanent_attack_speed_multiplier * interval_factor
			controller.chain_enabled = skills.has("sword_chain")
			controller.sword_barrage_enabled = skills.has("sword_barrage")
			controller.sword_greatsword_enabled = skills.has("sword_greatsword_sweep")
			if controller.sword_greatsword_enabled:
				controller.get_node("GreatswordTimer").start(10.0 * controller.permanent_attack_speed_multiplier * interval_factor)
		"axe":
			controller.additional_damage_percent = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.get_node("Timer").wait_time = controller.base_wait_time * controller.permanent_attack_speed_multiplier * interval_factor
			controller.reflect_projectiles = skills.has("axe_reflect")
			controller.additional_axe_count = 1 if skills.has("axe_count") else 0
			controller.return_to_player = skills.has("axe_return")
			controller.knockback_enabled = skills.has("axe_knockback")
			controller.distance_scaling_enabled = skills.has("axe_distance_power")
		"laser_gun":
			controller.damage_multiplier = controller.permanent_damage_multiplier * damage_factor
			controller.beam_size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.cooldown_reduction = 1.0 - interval_factor
			controller.update_cooldown()
			controller.damage_ramp_enabled = skills.has("laser_gun_damage_ramp")
			controller.reflection_enabled = skills.has("laser_gun_reflect")
			controller.stun_enabled = skills.has("laser_gun_stun")
			controller.auto_aim_enabled = skills.has("laser_gun_auto_aim")
			controller.kill_duration_extension_enabled = skills.has("laser_gun_kill_duration")
		"lightning_whip":
			controller.damage_multiplier = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.get_node("Timer").wait_time = controller.base_wait_time * controller.permanent_attack_speed_multiplier * interval_factor
			controller.chain_enabled = skills.has("lightning_chain")
			controller.cloud_enabled = skills.has("lightning_cloud")
			controller.wide_arc_enabled = skills.has("lightning_wide_arc")
			controller.paralysis_enabled = skills.has("lightning_paralysis")
		"bomb":
			controller.damage_multiplier = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.get_node("Timer").wait_time = controller.base_wait_time * controller.permanent_attack_speed_multiplier * interval_factor
			controller.bounce_level = 1 if skills.has("bomb_bounce") else 0
			controller.burn_enabled = skills.has("bomb_burn")
			controller.cluster_enabled = skills.has("bomb_cluster")
			controller.giant_charge_enabled = skills.has("bomb_giant_charge")
			controller.implosion_enabled = skills.has("bomb_implosion")
		"thunder_orb_book":
			controller.damage_multiplier = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.cooldown_multiplier = interval_factor
			controller.update_cooldown()
			controller.chain_enabled = skills.has("thunder_orb_chain")
			controller.additional_orb_count = 1 if skills.has("thunder_orb_count") else 0
			controller.growth_enabled = skills.has("thunder_orb_growth")
			controller.plasma_enabled = skills.has("thunder_orb_plasma")
			controller.boss_tracking_enabled = skills.has("thunder_orb_boss_tracking")
		"azure_dragon":
			controller.damage_multiplier = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.cooldown_multiplier = interval_factor
			controller.update_cooldown()
			controller.spawn_dragon()
			if skills.has("azure_dragon_vermilion_bird"):
				controller.spawn_vermilion_bird()
			if skills.has("azure_dragon_xuanwu"):
				controller.spawn_xuanwu()
				if is_instance_valid(controller.xuanwu):
					controller.xuanwu.death_save_used = xuanwu_save_used
			if skills.has("azure_dragon_white_tiger"):
				controller.spawn_white_tiger()
		"nine_treasure_pagoda":
			controller.common_damage_levels = (tier - 1) * 3.0 + (1.0 if skills.has("nine_treasure_pagoda_damage") else 0.0)
			controller.common_size_levels = (tier - 1) * 0.8 + (1.0 if skills.has("nine_treasure_pagoda_size") else 0.0)
			controller.common_rate_levels = (tier - 1) * 0.6 + (1.0 if skills.has("nine_treasure_pagoda_rate") else 0.0)
			controller.damage_skill = skills.has("nine_treasure_damage")
			controller.attack_speed_skill = skills.has("nine_treasure_attack_speed")
			controller.health_skill = skills.has("nine_treasure_health")
			controller.move_speed_skill = skills.has("nine_treasure_move_speed")
			controller.extra_attack_skill = skills.has("nine_treasure_extra_attack")
			controller.apply_support_buffs()
		"heaven_shaking_hammer":
			controller.damage_multiplier = controller.permanent_damage_multiplier * damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.get_node("Timer").wait_time = controller.base_wait_time * controller.permanent_attack_speed_multiplier * interval_factor
			controller.extra_wave_count = 1 if skills.has("heaven_shaking_hammer_extra_wave") else 0
			controller.lava_enabled = skills.has("heaven_shaking_hammer_lava")
			controller.pull_enabled = skills.has("heaven_shaking_hammer_pull")
			controller.heavy_enabled = skills.has("heaven_shaking_hammer_heavy")
			controller.aftershock_enabled = skills.has("heaven_shaking_hammer_aftershock")
		"sniper_rifle":
			controller.diamond_bullet_enabled = skills.has("sniper_rifle_diamond_bullet")
			controller.shadowless_bullet_enabled = skills.has("sniper_rifle_shadowless_bullet")
			controller.ricochet_enabled = skills.has("sniper_rifle_ricochet")
			controller.explosive_bullet_enabled = skills.has("sniper_rifle_explosive_bullet")
			controller.refresh_damage_multiplier()
			controller.damage_multiplier *= damage_factor
			controller.size_multiplier = controller.permanent_size_multiplier * size_factor
			controller.get_node("Timer").wait_time = controller.base_wait_time * controller.permanent_attack_speed_multiplier * interval_factor
	var timer := controller.get_node_or_null("Timer") as Timer
	if timer != null:
		timer.start()


func remove_pagoda_buffs(controller: NineTreasurePagodaController) -> void:
	if is_instance_valid(controller.pagoda):
		controller.pagoda.queue_free()
	for timer: Timer in controller.get_weapon_attack_timers():
		if timer.has_meta("pagoda_base_wait"):
			timer.wait_time = float(timer.get_meta("pagoda_base_wait"))
			timer.remove_meta("pagoda_base_wait")
			timer.remove_meta("pagoda_applied_wait")
	for other: Node in player.abilities.get_children():
		if other.has_meta("pagoda_base_size"):
			var property := "size_multiplier" if controller.has_property(other, "size_multiplier") else "beam_size_multiplier"
			other.set(property, float(other.get_meta("pagoda_base_size")))
			other.remove_meta("pagoda_base_size")
			other.remove_meta("pagoda_applied_size")
			if other.has_method("refresh_dragon"):
				other.refresh_dragon()
	GameEvents.support_damage_multiplier = 1.0
	GameEvents.support_health_multiplier = 1.0
	GameEvents.support_move_speed_multiplier = 1.0
	GameEvents.support_size_multiplier = 1.0
	GameEvents.support_attack_interval_multiplier = 1.0
	GameEvents.support_weapon_attack_count_bonus = 0
	GameEvents.weapon_attack_count = GameEvents.base_weapon_attack_count
	controller.apply_attack_count_to_weapon_controllers()
	player.refresh_support_stats()
	player.refresh_missing_health_passive()


func upgrade(slot: int) -> bool:
	if slot < 0 or slot >= items.size() or items[slot] == null or int(items[slot].rarity) >= 5:
		return false
	var item: Dictionary = items[slot]
	var remaining: Array = SKILLS[item.id].filter(func(id: String): return not item.skills.has(id))
	item.rarity += 1
	item.skills.append(remaining[rng.randi_range(0, remaining.size() - 1)])
	rebuild(slot)
	return true


func reroll(slot: int) -> bool:
	if slot < 0 or slot >= items.size() or items[slot] == null:
		return false
	var item: Dictionary = items[slot]
	item.skills = roll_skills(item.id, item.rarity)
	rebuild(slot)
	return true


func item_name(item: Dictionary) -> String:
	return "%s · %s" % [RARITY_NAMES[int(item.rarity) - 1], WEAPONS[item.id].name]


func skill_resource(id: String) -> AbilityUpgrade:
	return load("res://resources/upgrades/%s.tres" % id) as AbilityUpgrade
