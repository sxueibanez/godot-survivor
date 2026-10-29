extends Node

const DETECTION_RANGE := 300.0
const PURSUIT_RANGE := 450.0

var mode: Node
var enemy: CharacterBody2D
var defending := false
var alerted := false
var attack_range := 38.0
var tower_damage := 7.0
var attack_left := 0.0


func _process(delta: float) -> void:
	if not is_instance_valid(mode) or not is_instance_valid(enemy) or mode.finished:
		return
	var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health == null or health.current_health <= 0.0:
		return
	if not defending:
		var range_limit := PURSUIT_RANGE if alerted else DETECTION_RANGE
		var awake: bool = not mode.respawning and is_instance_valid(mode.player) and enemy.global_position.distance_squared_to(mode.player.global_position) <= range_limit * range_limit
		alerted = awake
		if enemy.is_processing() != awake:
			enemy.set_process(awake)
			if not awake:
				var movement := enemy.get_node_or_null("VelocityComponent") as VelocityComponent
				if movement != null:
					movement.velocity = Vector2.ZERO
				enemy.velocity = Vector2.ZERO
		return
	attack_left = maxf(attack_left - delta, 0.0)
	if mode.defense_active and enemy.global_position.distance_to(mode.tower.global_position) <= attack_range and attack_left <= 0.0:
		mode.damage_tower(tower_damage)
		attack_left = 1.5 if attack_range > 60.0 else 1.0
