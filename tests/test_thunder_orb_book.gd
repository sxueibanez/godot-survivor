extends Node

const ThunderController = preload("res://scenes/ability/thunder_orb_book_controller/thunder_orb_book_controller.gd")
const ThunderOrb = preload("res://scenes/ability/thunder_orb_book/thunder_orb_book.gd")


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var weapon := load("res://resources/upgrades/thunder_orb_book.tres") as Ability
	assert(weapon != null and weapon.weapon_type == Ability.WeaponType.RANGED and weapon.icon != null)
	assert((load("res://resources/upgrades/thunder_orb_count.tres") as AbilityUpgrade).max_quantity == 3)
	assert((load("res://resources/upgrades/thunder_orb_boss_tracking.tres") as AbilityUpgrade).max_quantity == 1)
	assert(is_equal_approx(ThunderController.MAX_RANGE, LaserGunAbility.BEAM_LENGTH))
	assert(is_equal_approx(ThunderOrb.MAX_DISTANCE, LaserGunAbility.BEAM_LENGTH))
	assert(is_equal_approx(ThunderOrb.get_visual_scale(0.0, true), 1.0))
	assert(is_equal_approx(ThunderOrb.get_visual_scale(1.0, true), 1.8))
	assert(ThunderOrb.CHAIN_TARGET_COUNT == 3 and ThunderOrb.HIT_INTERVAL_MS == 1000)
	assert(is_equal_approx(ThunderOrb.EXPLOSION_MULTIPLIER, 2.0) and is_equal_approx(ThunderOrb.PLASMA_MULTIPLIER, 0.3))
	assert(is_equal_approx(ThunderOrb.PLASMA_RADIUS, 30.0))
	assert(is_equal_approx(ThunderOrb.SPEED * 4.0, ThunderOrb.MAX_DISTANCE))
	var controller: Variant = ThunderController.new()
	var count_upgrade := load("res://resources/upgrades/thunder_orb_count.tres") as AbilityUpgrade
	controller.on_ability_upgrade_added(count_upgrade, {count_upgrade.id: {"quantity": 3}})
	assert(controller.additional_orb_count == 3)
	var tracking_upgrade := load("res://resources/upgrades/thunder_orb_boss_tracking.tres") as AbilityUpgrade
	controller.on_ability_upgrade_added(tracking_upgrade, {tracking_upgrade.id: {"quantity": 1}})
	assert(controller.boss_tracking_enabled)
	controller.free()
	var near_enemy := Node2D.new()
	near_enemy.position = Vector2(100, 0)
	add_child(near_enemy)
	var far_enemy := Node2D.new()
	far_enemy.position = Vector2(200, 0)
	add_child(far_enemy)
	assert(ThunderController.find_nearest_enemy([far_enemy, near_enemy], Vector2.ZERO) == near_enemy)
	var orb: Variant = load("res://scenes/ability/thunder_orb_book/thunder_orb_book.tscn").instantiate()
	orb.configure(Vector2.ZERO, Vector2.RIGHT, 10.0, true, true, true, true)
	add_child(orb)
	assert(orb.z_index == -1)
	assert(orb.orb_sprite.hframes == 4 and orb.orb_sprite.vframes == 4)
	var boss := Node2D.new()
	boss.position = Vector2(0, 100)
	boss.add_to_group("boss")
	add_child(boss)
	orb.update_boss_tracking()
	assert(orb.direction.is_equal_approx(Vector2.DOWN))
	boss.remove_from_group("boss")
	orb.update_boss_tracking()
	assert(orb.direction.is_equal_approx(Vector2.RIGHT))
	var plasma: Variant = load("res://scenes/ability/thunder_plasma/thunder_plasma.tscn").instantiate()
	plasma.configure(Vector2.ZERO, 3.0, ThunderOrb.PLASMA_RADIUS)
	add_child(plasma)
	assert(plasma.z_index == -1)
	assert(plasma.ticks_left == 3 and plasma.plasma_sprite.hframes == 4 and plasma.plasma_sprite.vframes == 4)
	get_tree().quit()
