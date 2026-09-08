extends Node

const MAX_RANGE = 150
const SWORD_RAIN_REQUIRED_SWORDS := 6
const SWORD_RAIN_CLUSTER_RADIUS := 54.0
const GIANT_RAIN_TRIGGER_COUNT := 3

@export var sword_ability: PackedScene
@export var sword_rain_ability: PackedScene
@export var sword_barrage_ability: PackedScene

var base_damage = 5
var additional_damage_percent: float = 1.0
var base_wait_time := 0.0
var attack_count := 1
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var chain_enabled := false
var sword_rain_enabled := false
var sword_rain_threshold_met := false
var giant_sword_rain_enabled := false
var giant_rain_threshold_met := false
var sword_barrage_enabled := false
var sword_hit_counts: Dictionary = {}
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
	GameEvents.sword_hit_target.connect(on_sword_hit_target)


func _process(_delta: float) -> void:
	process_sword_rain_trigger()
	process_giant_sword_rain_trigger()


func process_sword_rain_trigger() -> void:
	var has_enough_swords: bool = get_tree().get_nodes_in_group("sword_ability").size() >= SWORD_RAIN_REQUIRED_SWORDS
	if !sword_rain_enabled or !has_enough_swords:
		sword_rain_threshold_met = false
		return
	if sword_rain_threshold_met:
		return
	sword_rain_threshold_met = true
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var foreground_layer: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground_layer == null:
		return
	var enemies: Array = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < MAX_RANGE * MAX_RANGE
	)
	if !enemies.is_empty():
		try_spawn_sword_rain(enemies, foreground_layer)


func process_giant_sword_rain_trigger() -> void:
	var rain_count: int = get_tree().get_nodes_in_group("sword_rain").size()
	if !giant_sword_rain_enabled or rain_count < GIANT_RAIN_TRIGGER_COUNT:
		giant_rain_threshold_met = false
		return
	if giant_rain_threshold_met:
		return
	giant_rain_threshold_met = true
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var foreground_layer: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground_layer == null:
		return
	var giant_rain: SwordRainAbility = sword_rain_ability.instantiate() as SwordRainAbility
	giant_rain.damage = base_damage * additional_damage_percent * 1.6
	giant_rain.duration = SwordRainAbility.DURATION * 0.5
	giant_rain.radius_multiplier = 2.0
	giant_rain.scale = Vector2.ONE * 2.0
	foreground_layer.add_child(giant_rain)
	giant_rain.global_position = player.global_position


func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var enemies = get_tree().get_nodes_in_group("enemy")
	enemies = enemies.filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE, 2)
	)
	
	if enemies.is_empty():
		return
	
	enemies.sort_custom(func(a: Node2D, b: Node2D):
		var a_distance = a.global_position.distance_squared_to(player.global_position)
		var b_distance = b.global_position.distance_squared_to(player.global_position)
		
		return a_distance < b_distance
	)
	
	var foreground_layer: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground_layer == null:
		return
	for index in attack_count:
		var sword_instance = sword_ability.instantiate() as SwordAbility
		sword_instance.damage = base_damage * additional_damage_percent
		sword_instance.chain_enabled = chain_enabled
		sword_instance.scale = Vector2.ONE * permanent_size_multiplier
		foreground_layer.add_child(sword_instance)
		sword_instance.global_position = enemies[index % enemies.size()].global_position
		sword_instance.global_position += Vector2.RIGHT.rotated(randf_range(0, TAU)) * 4
		sword_instance.rotation = (enemies[index % enemies.size()].global_position - sword_instance.global_position).angle()
func try_spawn_sword_rain(enemies: Array, foreground_layer: Node2D) -> void:
	if !sword_rain_enabled or get_tree().get_nodes_in_group("sword_ability").size() < SWORD_RAIN_REQUIRED_SWORDS:
		return
	var target: Node2D = find_densest_enemy(enemies)
	if target == null:
		return
	var sword_rain: SwordRainAbility = sword_rain_ability.instantiate() as SwordRainAbility
	sword_rain.damage = base_damage * additional_damage_percent * 0.8
	foreground_layer.add_child(sword_rain)
	sword_rain.global_position = target.global_position


func on_sword_hit_target(target: Node2D) -> void:
	if !sword_barrage_enabled or target == null:
		return
	var target_id: int = target.get_instance_id()
	var hit_count: int = int(sword_hit_counts.get(target_id, 0)) + 1
	sword_hit_counts[target_id] = hit_count
	if hit_count < 10:
		return
	sword_hit_counts[target_id] = 0
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var foreground_layer: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground_layer == null:
		return
	var barrage: SwordBarrageAbility = sword_barrage_ability.instantiate() as SwordBarrageAbility
	barrage.origin_position = player.global_position
	barrage.target_position = target.global_position
	barrage.damage = base_damage * additional_damage_percent * 1.5
	foreground_layer.add_child(barrage)
	barrage.global_position = barrage.origin_position


func find_densest_enemy(enemies: Array) -> Node2D:
	var densest_enemy: Node2D
	var highest_count := 0
	# ponytail: O(n²) candidate scan; spatial indexing only matters for much larger enemy caps.
	for candidate_value: Variant in enemies:
		var candidate: Node2D = candidate_value as Node2D
		if candidate == null:
			continue
		var nearby_count := 0
		for enemy_value: Variant in enemies:
			var enemy: Node2D = enemy_value as Node2D
			if enemy != null and candidate.global_position.distance_squared_to(enemy.global_position) <= SWORD_RAIN_CLUSTER_RADIUS * SWORD_RAIN_CLUSTER_RADIUS:
				nearby_count += 1
		if nearby_count > highest_count:
			highest_count = nearby_count
			densest_enemy = candidate
	return densest_enemy


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	match upgrade.id:
		"sword_rate":
			var percent_reduction = current_upgrades["sword_rate"]["quantity"] * 0.1
			$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier * (1 - percent_reduction)
			$Timer.start()
		"sword_damage":
			additional_damage_percent = permanent_damage_multiplier * (1 + current_upgrades["sword_damage"]["quantity"] * 0.15)
		"attack_count":
			attack_count = GameEvents.weapon_attack_count
		"sword_chain":
			chain_enabled = true
		"sword_rain":
			sword_rain_enabled = true
		"sword_rain_giant":
			giant_sword_rain_enabled = true
		"sword_barrage":
			sword_barrage_enabled = true
