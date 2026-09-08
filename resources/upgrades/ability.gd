extends AbilityUpgrade
class_name Ability

enum WeaponType { MELEE, RANGED }

@export var ability_controller_scene: PackedScene
@export var weapon_type: WeaponType = WeaponType.MELEE
