extends SceneTree


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	var health := HealthComponent.new()
	health.max_health = 100.0
	player.add_child(health)
	root.add_child(player)
	var knight := preload("res://scenes/game_object/lightning_knight/lightning_knight.gd").new()
	root.add_child(knight)
	assert(knight.call("knockback_dash_targets", Vector2.RIGHT, false))
	assert(is_equal_approx(health.current_health, 45.0))
	assert(not knight.call("knockback_dash_targets", Vector2.RIGHT, true))
	assert(is_equal_approx(health.current_health, 45.0))
	assert(not knight.call("is_attack_interrupted"))
	paused = true
	assert(knight.call("is_attack_interrupted"))
	paused = false
	knight.set("attacking", true)
	knight.call("on_ability_upgrade_added", AbilityUpgrade.new(), {})
	assert(knight.call("is_attack_interrupted"))
	quit()
