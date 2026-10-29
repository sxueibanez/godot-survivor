extends "res://scenes/frontier/frontier_enemy.gd"

var boss_type := 0
var special_left := 4.0
var warning_left := 0.0
var charging_left := 0.0
var charge_direction := Vector2.ZERO


func _process(delta: float) -> void:
	if not is_instance_valid(mode) or mode.finished or health.current_health <= 0.0:
		return
	if warning_left > 0.0:
		warning_left -= delta
		movement.velocity = Vector2.ZERO
		if warning_left <= 0.0:
			if boss_type == 0:
				charge_direction = global_position.direction_to(mode.tower.global_position)
				charging_left = 1.3
			else:
				mode.damage_tower(95.0)
				if is_instance_valid(mode.player) and not mode.respawning and mode.player.global_position.distance_to(mode.tower.global_position) < 65.0:
					mode.player.health_component.damage(15.0, "攻城巫王")
		queue_redraw()
		return
	if charging_left > 0.0:
		charging_left -= delta
		if movement.stun_time_left <= 0.0:
			move_and_collide(charge_direction * 260.0 * delta)
		if global_position.distance_to(mode.tower.global_position) <= 38.0:
			mode.damage_tower(120.0)
			charging_left = 0.0
		queue_redraw()
		return
	super._process(delta)
	special_left -= delta
	if special_left <= 0.0 and global_position.distance_to(mode.tower.global_position) < 210.0:
		warning_left = 1.5
		special_left = 8.0 if boss_type == 0 else 7.0
		queue_redraw()


func _draw() -> void:
	if warning_left <= 0.0 or not is_instance_valid(mode) or not is_instance_valid(mode.tower):
		return
	var target := to_local(mode.tower.global_position)
	if boss_type == 0:
		draw_line(Vector2.ZERO, target, Color(1.0, 0.3, 0.15, 0.8), 3.0)
	else:
		draw_circle(target, 65.0 / scale.x, Color(0.75, 0.25, 1.0, 0.25))
		draw_arc(target, 65.0 / scale.x, 0.0, TAU, 40, Color(0.9, 0.5, 1.0, 0.9), 1.5)
