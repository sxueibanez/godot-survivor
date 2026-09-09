extends SceneTree


func _init() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	health.current_health = 50.0
	health.heal(10.0)
	assert(health.current_health == 60.0)
	health.heal(100.0)
	assert(health.current_health == 100.0)
	assert(load("res://scenes/game_object/health_vial/health_vial.tscn") is PackedScene)
	assert(load("res://scenes/ability/lightning_whip_ability/lightning_whip_ability.tscn") is PackedScene)
	assert(load("res://scenes/ability/lightning_chain_ability/lightning_chain_ability.tscn") is PackedScene)
	assert(load("res://scenes/ability/lightning_cloud_ability/lightning_cloud_ability.tscn") is PackedScene)
	assert(load("res://resources/upgrades/lightning_cloud.tres") is AbilityUpgrade)
	assert(load("res://resources/upgrades/lightning_wide_arc.tres") is AbilityUpgrade)
	var whip_scene := load("res://scenes/ability/lightning_whip_ability/lightning_whip_ability.tscn") as PackedScene
	assert(whip_scene != null)
	quit()
