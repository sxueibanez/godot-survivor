extends Node

const SKILL_FIELDS := {
	"sword_chain": ["chain_enabled", true], "sword_barrage": ["sword_barrage_enabled", true], "sword_greatsword_sweep": ["sword_greatsword_enabled", true],
	"axe_reflect": ["reflect_projectiles", true], "axe_count": ["additional_axe_count", 1], "axe_return": ["return_to_player", true], "axe_knockback": ["knockback_enabled", true], "axe_distance_power": ["distance_scaling_enabled", true],
	"laser_gun_damage_ramp": ["damage_ramp_enabled", true], "laser_gun_reflect": ["reflection_enabled", true], "laser_gun_stun": ["stun_enabled", true], "laser_gun_auto_aim": ["auto_aim_enabled", true], "laser_gun_kill_duration": ["kill_duration_extension_enabled", true],
	"lightning_chain": ["chain_enabled", true], "lightning_cloud": ["cloud_enabled", true], "lightning_wide_arc": ["wide_arc_enabled", true], "lightning_paralysis": ["paralysis_enabled", true],
	"bomb_bounce": ["bounce_level", 1], "bomb_burn": ["burn_enabled", true], "bomb_cluster": ["cluster_enabled", true], "bomb_giant_charge": ["giant_charge_enabled", true], "bomb_implosion": ["implosion_enabled", true],
	"thunder_orb_chain": ["chain_enabled", true], "thunder_orb_count": ["additional_orb_count", 1], "thunder_orb_growth": ["growth_enabled", true], "thunder_orb_plasma": ["plasma_enabled", true], "thunder_orb_boss_tracking": ["boss_tracking_enabled", true],
	"heaven_shaking_hammer_extra_wave": ["extra_wave_count", 1], "heaven_shaking_hammer_lava": ["lava_enabled", true], "heaven_shaking_hammer_pull": ["pull_enabled", true], "heaven_shaking_hammer_heavy": ["heavy_enabled", true], "heaven_shaking_hammer_aftershock": ["aftershock_enabled", true],
	"sniper_rifle_diamond_bullet": ["diamond_bullet_enabled", true], "sniper_rifle_shadowless_bullet": ["shadowless_bullet_enabled", true], "sniper_rifle_ricochet": ["ricochet_enabled", true], "sniper_rifle_explosive_bullet": ["explosive_bullet_enabled", true],
	"nine_treasure_damage": ["damage_skill", true], "nine_treasure_attack_speed": ["attack_speed_skill", true], "nine_treasure_health": ["health_skill", true], "nine_treasure_move_speed": ["move_speed_skill", true], "nine_treasure_extra_attack": ["extra_attack_skill", true],
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "frontier"
	var mode := preload("res://scenes/frontier/frontier.tscn").instantiate()
	add_child(mode)
	for child: Node in mode.get_children():
		if child.has_signal("character_selected"):
			child.select_character(preload("res://resources/characters/warrior.tres"))
	mode.player.set_process(false)
	var inventory: Node = mode.inventory
	inventory.rng.seed = 91827
	var card := preload("res://scenes/ui/ability_upgrade_card.gd")
	for weapon_id: String in inventory.WEAPONS:
		for skill_id: String in inventory.SKILLS[weapon_id]:
			var resource: AbilityUpgrade = inventory.skill_resource(skill_id)
			assert(resource != null and card.get_upgrade_icon(resource) != null, "%s has no icon" % skill_id)
			if SKILL_FIELDS.has(skill_id):
				inventory.equip({"id": weapon_id, "rarity": 1, "skills": [skill_id]}, 0)
				var mapping: Array = SKILL_FIELDS[skill_id]
				assert(inventory.controllers[0].get(mapping[0]) == mapping[1], "%s not applied" % skill_id)
				await get_tree().process_frame
		for tier in range(1, 6):
			var skills: Array = inventory.roll_skills(weapon_id, tier)
			assert(skills.size() == tier)
			var unique := {}
			for skill_id: String in skills:
				assert(not unique.has(skill_id))
				unique[skill_id] = true
			var item := {"id": weapon_id, "rarity": tier, "skills": skills}
			inventory.equip(item, 0)
			assert(inventory.items[0].id == weapon_id and is_instance_valid(inventory.controllers[0]))
			assert(inventory.items[0].skills.size() == tier)
			await get_tree().process_frame
	var plain := {"id": "axe", "rarity": 1, "skills": ["axe_return"]}
	inventory.equip(plain, 0)
	assert(inventory.controllers[0].return_to_player)
	for tier in range(2, 6):
		assert(inventory.upgrade(0))
		assert(inventory.items[0].rarity == tier and inventory.items[0].skills.size() == tier)
		assert(inventory.items[0].skills.has("axe_return"))
	assert(not inventory.upgrade(0))
	assert(inventory.reroll(0) and inventory.items[0].skills.size() == 5)
	var beast := {"id": "azure_dragon", "rarity": 1, "skills": ["azure_dragon_xuanwu"]}
	inventory.equip(beast, 0)
	assert(is_instance_valid(inventory.controllers[0].xuanwu))
	assert(not inventory.can_equip(beast, 1))
	inventory.controllers[0].xuanwu.death_save_used = true
	inventory.equip(plain, 0)
	inventory.equip(beast, 0)
	assert(inventory.controllers[0].xuanwu.death_save_used)
	var pagoda := {"id": "nine_treasure_pagoda", "rarity": 1, "skills": ["nine_treasure_damage"]}
	inventory.equip(plain, 1)
	var other: Node = inventory.controllers[1]
	var old_wait: float = other.get_node("Timer").wait_time
	var old_size: float = other.size_multiplier
	inventory.equip(pagoda, 0)
	assert(GameEvents.support_damage_multiplier > 1.0 and not inventory.can_equip(pagoda, 1))
	await get_tree().process_frame
	assert(other.get_node("Timer").wait_time < old_wait and other.size_multiplier >= old_size)
	inventory.equip(plain, 0)
	assert(GameEvents.support_damage_multiplier == 1.0 and GameEvents.support_health_multiplier == 1.0)
	assert(is_equal_approx(other.get_node("Timer").wait_time, old_wait) and is_equal_approx(other.size_multiplier, old_size))
	var tiger := {"id": "azure_dragon", "rarity": 1, "skills": ["azure_dragon_white_tiger"]}
	inventory.equip(tiger, 1)
	var tiger_timer: Timer = inventory.controllers[1].white_tiger.get_node("AttackTimer")
	var tiger_wait := tiger_timer.wait_time
	inventory.equip(pagoda, 0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(tiger_timer.wait_time < tiger_wait)
	inventory.equip(plain, 0)
	assert(is_equal_approx(tiger_timer.wait_time, tiger_wait))
	var rare_counts := [0, 0, 0]
	for index in 4000:
		for chest_level in range(1, 4):
			if inventory.roll_rarity(chest_level) >= 4:
				rare_counts[chest_level - 1] += 1
	assert(rare_counts[0] < rare_counts[1] and rare_counts[1] < rare_counts[2])
	get_tree().paused = false
	print("FRONTIER_GEAR_OK %s" % [rare_counts])
	get_tree().quit()
