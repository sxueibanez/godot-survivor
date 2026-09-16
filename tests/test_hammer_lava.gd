extends Node

func _ready() -> void:
	var upgrade := load("res://resources/upgrades/heaven_shaking_hammer_lava.tres") as AbilityUpgrade
	assert(upgrade != null and upgrade.max_quantity == 1)
	var lava := load("res://scenes/ability/hammer_lava/hammer_lava.tscn").instantiate() as ThunderPlasma
	assert(lava.tick_count == 6)
	assert(is_equal_approx(lava.get_node("Timer").wait_time * lava.tick_count, 3.0))
	assert(lava.weapon_id == "heaven_shaking_hammer")
	assert(lava.get_node("PlasmaSprite").hframes * lava.get_node("PlasmaSprite").vframes == 16)
	lava.configure(Vector2.ZERO, 30.0, 38.5)
	add_child(lava)
	await get_tree().create_timer(3.2).timeout
	assert(not is_instance_valid(lava))
	print("Hammer lava test passed: 6 ticks over 3 seconds, 16 animation frames.")
	get_tree().quit()
