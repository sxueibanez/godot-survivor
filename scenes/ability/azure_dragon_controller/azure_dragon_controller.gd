extends Node
class_name AzureDragonController

const MAX_RANGE := 280.0

@export var azure_dragon_scene: PackedScene

var base_damage := 20.0
var base_cooldown := 4.0
var damage_multiplier := 1.0
var size_multiplier := 1.0
var cooldown_multiplier := 1.0
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var character_damage_multiplier := 1.0
var dragon: AzureDragonAbility


func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	permanent_attack_speed_multiplier = 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	damage_multiplier = permanent_damage_multiplier
	size_multiplier = permanent_size_multiplier
	update_cooldown()
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	call_deferred("spawn_dragon")


func spawn_dragon() -> void:
	if is_instance_valid(dragon):
		return
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	dragon = azure_dragon_scene.instantiate() as AzureDragonAbility
	dragon.configure(base_damage * damage_multiplier, size_multiplier)
	foreground.add_child(dragon)


func on_timer_timeout() -> void:
	if not is_instance_valid(dragon):
		spawn_dragon()
	if not is_instance_valid(dragon):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var target := find_nearest_enemy(get_tree().get_nodes_in_group("enemy"), player.global_position)
	if target != null:
		dragon.start_attack(target.global_position)


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
		"azure_dragon_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.2)
			refresh_dragon()
		"azure_dragon_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.2)
			refresh_dragon()
		"azure_dragon_rate":
			cooldown_multiplier = maxf(0.1, 1.0 - current_upgrades[upgrade.id]["quantity"] * 0.15)
			update_cooldown()
			$Timer.start()


func refresh_dragon() -> void:
	if is_instance_valid(dragon):
		dragon.configure(base_damage * damage_multiplier, size_multiplier)


func update_cooldown() -> void:
	$Timer.wait_time = base_cooldown * permanent_attack_speed_multiplier * cooldown_multiplier
