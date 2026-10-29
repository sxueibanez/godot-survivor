extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.game_mode = "endless"
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	player.add_child(health)
	var momentum := preload("res://scenes/manager/combat_momentum.gd").new()
	add_child(momentum)
	momentum.set_process(false)
	var enemy := Node2D.new()
	add_child(enemy)
	GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 1 and momentum.kills == 1)
	enemy.add_to_group("elite")
	GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 4)
	enemy.add_to_group("boss")
	GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 9)
	enemy.remove_from_group("boss")
	GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 12 and health.shield == 5.0)
	for i in 12:
		GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 48 and health.shield == 15.0)
	health.set_shield(30.0)
	for i in 4:
		GameEvents.enemy_defeated.emit(enemy)
	assert(health.shield == 30.0)
	var best: int = momentum.best_streak
	var kills: int = momentum.kills
	momentum._process(4.1)
	assert(momentum.streak == 0 and momentum.best_streak == best and momentum.kills == kills)
	GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 3)
	momentum.process_mode = Node.PROCESS_MODE_PAUSABLE
	momentum.set_process(true)
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	assert(momentum.time_left == momentum.STREAK_WINDOW)
	get_tree().paused = false
	momentum.set_process(false)
	health.current_health = 0.0
	GameEvents.enemy_defeated.emit(enemy)
	assert(momentum.streak == 3 and momentum.kills == kills + 1)
	var screen := preload("res://scenes/ui/end_screen.tscn").instantiate()
	var host := Node.new()
	add_child(host)
	momentum.reparent(host)
	momentum.name = "CombatMomentum"
	host.add_child(screen)
	assert(screen.panel_container.get_node("MarginContainer/VBoxContainer/SummaryLabel").text == "本局击败 %d · 最高连击 %d" % [kills + 1, best])
	get_tree().paused = false
	print("COMBAT_MOMENTUM_OK")
	get_tree().quit()
