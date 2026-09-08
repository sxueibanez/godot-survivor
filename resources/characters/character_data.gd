extends Resource
class_name CharacterData

@export var id: String
@export var display_name: String
@export var max_health := 100.0
@export var move_speed := 90
@export var melee_damage_bonus := 0.0
@export var ranged_damage_bonus := 0.0
@export var missing_health_damage_bonus_per_10 := 0.0
@export var missing_health_speed_bonus_per_10 := 0
@export_multiline var passive_description := ""
@export var sprite: Texture2D
@export var visual_scale := 1.0
@export var sprite_offset := Vector2.ZERO
@export var custom_walk_animation := false
@export var walk_bob_height := 0.0
@export var walk_tilt := 0.0


func get_weapon_damage_multiplier(weapon: Ability) -> float:
	return 1.0 + melee_damage_bonus if weapon.weapon_type == Ability.WeaponType.MELEE else 1.0 + ranged_damage_bonus
