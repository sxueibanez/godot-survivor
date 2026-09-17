extends SceneTree

const Cooldown = preload("res://scenes/ability/attack_cooldown.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	# Parse every affected controller, including persistent companions.
	for weapon in ["axe_ability", "laser_gun_ability", "sword_ability", "lightning_whip_ability", "bomb_ability", "heaven_shaking_hammer", "sniper_rifle", "thunder_orb_book", "azure_dragon"]:
		var script = load("res://scenes/ability/%s_controller/%s_controller.gd" % [weapon, weapon])
		assert(script != null and script.can_instantiate())
	for companion in ["vermilion_bird", "white_tiger", "nine_treasure_pagoda"]:
		var script = load("res://scenes/ability/%s/%s.gd" % [companion, companion])
		assert(script != null and script.can_instantiate())
	var timer := Timer.new()
	timer.wait_time = 0.25
	root.add_child(timer)
	timer.start()
	var cooldown = Cooldown.new(timer)
	var first := Node.new()
	var second := Node.new()
	root.add_child(first)
	root.add_child(second)
	cooldown.track(first)
	cooldown.track(second)
	assert(timer.is_stopped())
	timer.wait_time = 0.15
	cooldown.restart() # A rate upgrade must not start cooldown during attack.
	assert(timer.is_stopped())
	first.free()
	assert(timer.is_stopped() and cooldown.active_count == 1)
	var child := Node.new()
	root.add_child(child)
	cooldown.track(child) # Bounce/fragment inherits this attack batch.
	second.free()
	assert(timer.is_stopped())
	child.free()
	assert(not timer.is_stopped() and cooldown.active_count == 0)
	assert(timer.time_left > 0.14)
	cooldown.begin() # Persistent dragon ends by signal, not destruction.
	assert(timer.is_stopped())
	cooldown.finish()
	assert(not timer.is_stopped())
	timer.free()
	# Actual laser: lasts two seconds, then starts the separate two-second CD.
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)
	var foreground := Node2D.new()
	foreground.add_to_group("foreground_layer")
	root.add_child(foreground)
	var enemy := Node2D.new()
	enemy.position = Vector2(100, 0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	var laser = load("res://scenes/ability/laser_gun_ability_controller/laser_gun_ability_controller.tscn").instantiate()
	root.add_child(laser)
	laser.permanent_attack_speed_multiplier = 1.0
	laser.cooldown_reduction = 0.0
	laser.update_cooldown()
	laser.on_timer_timeout()
	assert(laser.get_node("Timer").is_stopped())
	await create_timer(1.9).timeout
	assert(laser.get_node("Timer").is_stopped())
	await create_timer(0.25).timeout
	assert(not laser.get_node("Timer").is_stopped())
	assert(laser.get_node("Timer").time_left > 1.7)
	laser.free()
	enemy.free()
	# Returning axe: wait for the complete outgoing + return flight.
	var axe = load("res://scenes/ability/axe_ability_controller/axe_ability_controller.tscn").instantiate()
	root.add_child(axe)
	axe.return_to_player = true
	axe.get_node("Timer").wait_time = 3.5
	axe.on_timer_timeout()
	await create_timer(1.7).timeout
	assert(axe.get_node("Timer").is_stopped())
	await create_timer(1.0).timeout
	assert(not axe.get_node("Timer").is_stopped())
	assert(axe.get_node("Timer").time_left > 3.1)
	axe.free()
	# Real bomb descendants must keep the original cooldown stopped.
	var bomb_timer := Timer.new()
	bomb_timer.wait_time = 2.0
	root.add_child(bomb_timer)
	var bomb_cooldown = Cooldown.new(bomb_timer)
	var bomb = load("res://scenes/ability/bomb_ability/bomb_ability.tscn").instantiate()
	bomb.configure(Vector2.ZERO, Vector2(40, 0), 15.0, 30.0, 2, false, true)
	bomb_cooldown.track(bomb)
	foreground.add_child(bomb)
	bomb.explode()
	assert(bomb_cooldown.active_count == 7) # Root + bounce + five mini bombs.
	bomb.free()
	assert(bomb_timer.is_stopped() and bomb_cooldown.active_count == 6)
	for attack in foreground.get_children():
		attack.free()
	assert(not bomb_timer.is_stopped() and bomb_cooldown.active_count == 0)
	bomb_timer.free()
	# Hammer waves, including delayed extra waves, belong to the same batch.
	var hammer_timer := Timer.new()
	root.add_child(hammer_timer)
	var hammer_cooldown = Cooldown.new(hammer_timer)
	var hammer = load("res://scenes/ability/heaven_shaking_hammer/heaven_shaking_hammer.tscn").instantiate()
	hammer.configure(Vector2.ZERO, Vector2(40, 0), 12.0, 38.5, 4)
	hammer_cooldown.track(hammer)
	foreground.add_child(hammer)
	hammer.spawn_shockwaves()
	assert(hammer_cooldown.active_count == 6)
	hammer.free()
	assert(hammer_timer.is_stopped())
	for wave in foreground.get_children():
		wave.free()
	assert(not hammer_timer.is_stopped() and hammer_cooldown.active_count == 0)
	hammer_timer.free()
	foreground.free()
	player.free()
	print("Attack cooldown passed: batch completion, upgrade guard, child attacks, laser 2+2, returning axe then 3.5.")
	quit()
