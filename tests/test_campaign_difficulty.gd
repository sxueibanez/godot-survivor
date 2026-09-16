extends Node


func make_health(base_health: float, group: String, boss: bool = false) -> HealthComponent:
	var body := Node2D.new()
	body.add_to_group(group)
	if boss:
		body.add_to_group("boss")
	var health := HealthComponent.new()
	health.max_health = base_health
	body.add_child(health)
	add_child(body)
	return health


func _ready() -> void:
	GameEvents.game_mode = "campaign"
	GameEvents.reset_run_stats()
	GameEvents.arena_difficulty = 0
	var meta_multiplier := MetaProgression.get_enemy_health_multiplier()
	var basic := make_health(10.0, "enemy")
	var wisp := make_health(85.0, "enemy")
	assert(is_equal_approx(basic.max_health, 12.0 * meta_multiplier))
	assert(wisp.max_health <= 36.0 * meta_multiplier)
	assert(is_equal_approx(wisp.current_health, wisp.max_health))
	var duplicate_wisp := wisp.get_parent().duplicate()
	add_child(duplicate_wisp)
	assert(is_equal_approx((duplicate_wisp.get_child(0) as HealthComponent).max_health, wisp.max_health))
	var queen := make_health(7600.0, "enemy", true)
	var king := make_health(2400.0, "enemy", true)
	assert(is_equal_approx(queen.max_health, king.max_health))
	assert(is_equal_approx(queen.max_health, 2200.0 * meta_multiplier))
	assert(GameEvents.get_campaign_spawn_count() == 1)
	var player := make_health(100.0, "player")
	player.damage(20.0)
	assert(is_equal_approx(player.current_health, 87.0))
	GameEvents.campaign_completed_maps = 2
	assert(make_health(10.0, "enemy").max_health > basic.max_health * 2.0)
	assert(make_health(7600.0, "enemy", true).max_health > queen.max_health * 2.0)
	assert(GameEvents.get_campaign_spawn_count() == 2)
	assert(GameEvents.get_campaign_damage_multiplier() > 0.65)
	GameEvents.arena_difficulty = 60
	assert(make_health(10.0, "enemy").max_health > basic.max_health * 5.0)
	GameEvents.game_mode = "endless"
	assert(is_equal_approx(make_health(85.0, "enemy").max_health, 85.0 * meta_multiplier))
	GameEvents.reset_run_stats()
	assert(GameEvents.campaign_completed_maps == 0)
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_tree().quit()
