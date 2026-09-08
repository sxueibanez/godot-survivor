extends Node

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
var upgrade_sword_rate := preload("res://resources/upgrades/sword_rate.tres")
var upgrade_sword_damage := preload("res://resources/upgrades/sword_damage.tres")
var upgrade_sword_chain := preload("res://resources/upgrades/sword_chain.tres")
var upgrade_sword_rain := preload("res://resources/upgrades/sword_rain.tres")
var upgrade_sword_rain_giant := preload("res://resources/upgrades/sword_rain_giant.tres")
var upgrade_sword_barrage := preload("res://resources/upgrades/sword_barrage.tres")
var upgrade_player_speed := preload("res://resources/upgrades/player_speed.tres")
var upgrade_player_health := preload("res://resources/upgrades/player_health.tres")
var upgrade_critical_hit := preload("res://resources/upgrades/critical_hit.tres")
var upgrade_critical_damage := preload("res://resources/upgrades/critical_damage.tres")
var upgrade_speed_damage_no_crit := preload("res://resources/upgrades/speed_damage_no_crit.tres")
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

var rng := RandomNumberGenerator.new()
var weapon_upgrades: Array[Ability] = [upgrade_sword, upgrade_axe, upgrade_laser_gun, upgrade_lightning_whip]


func _ready():
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
	upgrade_pool.add_item(upgrade_attack_count, 5)
	for weapon: Ability in weapon_upgrades:
		weapon_pool.add_item(weapon, 10)

	experience_manager.level_up.connect(on_level_up)
	call_deferred("show_initial_weapon_choices")


func apply_upgrade(upgrade: AbilityUpgrade):
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
		add_unlocked_special(upgrade_sword_chain, "tree_sword_chain", 5)
		add_unlocked_special(upgrade_sword_rain, "tree_sword_rain", 5)
		add_unlocked_special(upgrade_sword_rain_giant, "tree_sword_rain_giant", 5)
		add_unlocked_special(upgrade_sword_barrage, "tree_sword_barrage", 5)
	elif chosen_upgrade.id == upgrade_axe.id:
		upgrade_pool.add_item(upgrade_axe_damage, 10)
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


func add_unlocked_special(upgrade: AbilityUpgrade, tree_skill_id: String, weight: int) -> void:
	if MetaProgression.get_weapon_skill_count(tree_skill_id) > 0:
		upgrade_pool.add_item(upgrade, weight)


func update_weapon_pool() -> void:
	if get_weapon_count() >= 2:
		for weapon: Ability in weapon_upgrades:
			upgrade_pool.remove_item(weapon)
		return
	for weapon: Ability in weapon_upgrades:
		if not current_upgrades.has(weapon.id):
			upgrade_pool.add_item(weapon, 10)


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
	show_choices(pick_upgrades(choice_count))


func show_choices(chosen_upgrades: Array[AbilityUpgrade]) -> void:
	if chosen_upgrades.is_empty():
		return
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)


func pick_weapon_upgrades(choice_count: int) -> Array[AbilityUpgrade]:
	var chosen_upgrades: Array[AbilityUpgrade] = []
	for index in choice_count:
		if weapon_pool.items.size() == chosen_upgrades.size():
			break
		var chosen_upgrade: AbilityUpgrade = weapon_pool.pick_item(chosen_upgrades) as AbilityUpgrade
		chosen_upgrades.append(chosen_upgrade)
	return chosen_upgrades


func on_upgrade_selected(upgrade: AbilityUpgrade):
	apply_upgrade(upgrade)
