extends Resource
class_name CharacterData

@export var id: String
@export var display_name: String
@export var max_health := 100.0
@export var move_speed := 90
@export var melee_damage_bonus := 0.0
@export var ranged_damage_bonus := 0.0
@export var weapon_limit := 2
@export var weapon_attack_speed_multiplier := 1.0
@export var missing_health_damage_bonus_per_10 := 0.0
@export var missing_health_speed_bonus_per_10 := 0.0
@export_multiline var passive_description := ""
@export_group("孤胆枪手")
@export var nearby_enemy_radius := 140.0
@export var solitude_enemy_cap := 5
@export var solitude_bonus_per_enemy := 0.08
@export var danger_radius := 60.0
@export var danger_speed_multiplier := 1.5
@export var danger_duration := 1.5
@export var danger_cooldown := 10.0
@export_group("赌命书生")
@export var health_reroll_fraction := 0.15
@export var elite_heal_fraction := 0.15
@export_group("浪客")
@export var dash_distance := 60.0
@export var dash_duration := 0.15
@export var dash_cooldown := 3.5
@export var dash_attack_window := 1.0
@export var dash_damage_bonus := 10.0
@export_group("复仇者")
@export var rage_damage_threshold := 40.0
@export var rage_duration := 5.0
@export var rage_damage_multiplier := 1.4
@export var rage_shield_fraction := 0.2
@export_group("外观")
@export var sprite: Texture2D
@export var visual_scale := 1.25
@export var sprite_offset := Vector2.ZERO
@export var custom_walk_animation := false
@export var walk_bob_height := 0.0
@export var walk_tilt := 0.0


func get_weapon_damage_multiplier(weapon: Ability) -> float:
	if weapon.weapon_type == Ability.WeaponType.MELEE:
		return 1.0 + melee_damage_bonus
	if weapon.weapon_type == Ability.WeaponType.RANGED:
		return 1.0 + ranged_damage_bonus
	return 1.0
