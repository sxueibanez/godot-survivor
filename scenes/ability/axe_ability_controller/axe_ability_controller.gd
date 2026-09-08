extends Node

@export var axe_ability_scene: PackedScene

var base_damage = 10
var additional_damage_percent: float = 1.0
var base_wait_time := 0.0
var attack_count := 1
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var reflect_projectiles := false
var additional_axe_count := 0
var return_to_player := false
var knockback_enabled := false
var distance_scaling_enabled := false
var character_damage_multiplier := 1.0


func _ready():
	base_wait_time = $Timer.wait_time
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	permanent_attack_speed_multiplier = 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	additional_damage_percent = permanent_damage_multiplier
	attack_count = GameEvents.weapon_attack_count
	$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var foreground = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	
	for index in attack_count + additional_axe_count:
		var axe_instance = axe_ability_scene.instantiate() as AxeAbility
		axe_instance.reflect_projectiles = reflect_projectiles
		axe_instance.return_to_player = return_to_player
		axe_instance.knockback_enabled = knockback_enabled
		axe_instance.distance_scaling_enabled = distance_scaling_enabled
		axe_instance.scale = Vector2.ONE * permanent_size_multiplier
		axe_instance.base_damage = base_damage * additional_damage_percent
		foreground.add_child(axe_instance)
		axe_instance.global_position = player.global_position


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	match upgrade.id:
		"axe_damage":
			additional_damage_percent = permanent_damage_multiplier * (1 + current_upgrades["axe_damage"]["quantity"] * 0.1)
		"attack_count":
			attack_count = GameEvents.weapon_attack_count
		"axe_reflect":
			reflect_projectiles = true
		"axe_count":
			additional_axe_count = current_upgrades["axe_count"]["quantity"]
		"axe_return":
			return_to_player = true
		"axe_knockback":
			knockback_enabled = true
		"axe_distance_power":
			distance_scaling_enabled = true
