extends Node
class_name ThunderOrbBookController

const MAX_RANGE := LaserGunAbility.BEAM_LENGTH
const SPREAD_ANGLE := 12.0

@export var thunder_orb_scene: PackedScene

var base_damage := 10.0
var base_cooldown := 4.0
var damage_multiplier := 1.0
var size_multiplier := 1.0
var cooldown_multiplier := 1.0
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var attack_count := 1
var additional_orb_count := 0
var chain_enabled := false
var growth_enabled := false
var plasma_enabled := false
var boss_tracking_enabled := false
var character_damage_multiplier := 1.0


func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	permanent_attack_speed_multiplier = 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	damage_multiplier = permanent_damage_multiplier
	size_multiplier = permanent_size_multiplier
	attack_count = GameEvents.weapon_attack_count
	update_cooldown()
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	var target := find_nearest_enemy(get_tree().get_nodes_in_group("enemy"), player.global_position)
	if target == null:
		return
	var direction := player.global_position.direction_to(target.global_position)
	var count := attack_count + additional_orb_count
	for index in count:
		var orb := thunder_orb_scene.instantiate()
		orb.configure(player.global_position, direction.rotated(deg_to_rad((index - (count - 1) * 0.5) * SPREAD_ANGLE)), base_damage * damage_multiplier, chain_enabled, growth_enabled, plasma_enabled, boss_tracking_enabled, size_multiplier)
		foreground.add_child(orb)


static func find_nearest_enemy(enemies: Array, origin: Vector2) -> Node2D:
	var nearest: Node2D
	for value: Variant in enemies:
		var enemy := value as Node2D
		if enemy == null:
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance <= MAX_RANGE * MAX_RANGE and (nearest == null or distance < origin.distance_squared_to(nearest.global_position)):
			nearest = enemy
	return nearest


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"thunder_orb_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"thunder_orb_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"thunder_orb_rate":
			cooldown_multiplier = 1.0 - current_upgrades[upgrade.id]["quantity"] * 0.05
			update_cooldown()
			$Timer.start()
		"thunder_orb_chain":
			chain_enabled = true
		"thunder_orb_count":
			additional_orb_count = int(current_upgrades[upgrade.id]["quantity"])
		"thunder_orb_growth":
			growth_enabled = true
		"thunder_orb_plasma":
			plasma_enabled = true
		"thunder_orb_boss_tracking":
			boss_tracking_enabled = true
		"attack_count":
			attack_count = GameEvents.weapon_attack_count


func update_cooldown() -> void:
	$Timer.wait_time = base_cooldown * permanent_attack_speed_multiplier * cooldown_multiplier
