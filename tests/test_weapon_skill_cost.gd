extends SceneTree


func _initialize() -> void:
	var original_skills: Dictionary = MetaProgression.save_data["weapon_skills"]
	MetaProgression.save_data["weapon_skills"] = {
		"tree_bonus_sword_0_damage": 1,
		"tree_bonus_sword_1_damage": 1,
		"tree_bonus_sword_1_size": 1,
		"tree_sword_chain": 1,
	}
	assert(is_equal_approx(MetaProgression.get_weapon_tree_bonus("sword", "damage"), 0.10))
	assert(is_equal_approx(MetaProgression.get_weapon_tree_bonus("sword", "size"), 0.05))
	assert(is_zero_approx(MetaProgression.get_weapon_tree_bonus("axe", "damage")))
	assert(is_equal_approx(MetaProgression.get_enemy_health_multiplier(), 1.02))
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	var health := HealthComponent.new()
	health.max_health = 100.0
	enemy.add_child(health)
	root.add_child(enemy)
	assert(is_equal_approx(health.max_health, 102.0))
	MetaProgression.save_data["weapon_skills"] = original_skills
	enemy.queue_free()
	quit()
