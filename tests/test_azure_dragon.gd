extends Node

const DRAGON_SCRIPT = preload("res://scenes/ability/azure_dragon/azure_dragon.gd")
const CONTROLLER_SCRIPT = preload("res://scenes/ability/azure_dragon_controller/azure_dragon_controller.gd")


func _ready() -> void:
	var weapon := load("res://resources/upgrades/azure_dragon.tres") as Ability
	assert(weapon != null and weapon.weapon_type == Ability.WeaponType.MELEE and weapon.icon != null)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var dragon := load("res://scenes/ability/azure_dragon/azure_dragon.tscn").instantiate() as AzureDragonAbility
	add_child(dragon)
	assert(dragon.dragon_sprite.hframes == 3 and dragon.dragon_sprite.vframes == 3)
	assert(dragon.start_attack(Vector2.RIGHT * 100.0))
	dragon.process_windup(DRAGON_SCRIPT.WINDUP_DURATION)
	assert(dragon.state == DRAGON_SCRIPT.State.DASH)
	dragon.process_dash(DRAGON_SCRIPT.DASH_DURATION)
	assert(dragon.state == DRAGON_SCRIPT.State.IDLE)
	var near_enemy := Node2D.new()
	near_enemy.position = Vector2(100, 0)
	var far_enemy := Node2D.new()
	far_enemy.position = Vector2(CONTROLLER_SCRIPT.MAX_RANGE + 1.0, 0)
	assert(CONTROLLER_SCRIPT.find_nearest_enemy([far_enemy, near_enemy], Vector2.ZERO) == near_enemy)
	print("AZURE_DRAGON_TEST_PASSED")
	get_tree().quit()
