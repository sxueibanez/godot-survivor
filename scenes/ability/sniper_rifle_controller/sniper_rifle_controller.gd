extends Node
class_name SniperRifleController

const MAX_RANGE := 500.0
const SCOPE_VIEW_MULTIPLIER := 1.3
const SCOPE_DAMAGE_MULTIPLIER := 1.1
const RICOCHET_DAMAGE_MULTIPLIER := 1.1
const RIFLE_TEXTURE: Texture2D = preload("res://assets/abilities/sniper_rifle.png")
const RIFLE_SCALE := 0.03
const RIFLE_VISIBLE_TIME := 0.4

@export var bullet_scene: PackedScene

var base_damage := 35.0
var base_wait_time := 2.0
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var damage_upgrade_quantity := 0
var damage_multiplier := 1.0
var size_multiplier := 1.0
var attack_count := 1
var diamond_bullet_enabled := false
var scope_enabled := false
var shadowless_bullet_enabled := false
var ricochet_enabled := false
var explosive_bullet_enabled := false
var scope_applied := false
var character_damage_multiplier := 1.0


@onready var attack_cooldown = preload("res://scenes/ability/attack_cooldown.gd").new($Timer)

func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01 + MetaProgression.get_weapon_tree_bonus("sniper_rifle", "damage")) * character_damage_multiplier
	permanent_attack_speed_multiplier = maxf(0.1, 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03 - MetaProgression.get_weapon_tree_bonus("sniper_rifle", "attack_speed")) / GameEvents.get_character_attack_speed_multiplier()
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05 + MetaProgression.get_weapon_tree_bonus("sniper_rifle", "size")
	size_multiplier = permanent_size_multiplier
	attack_count = GameEvents.weapon_attack_count
	refresh_damage_multiplier()
	$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)


func on_timer_timeout() -> void:
	if attack_cooldown.active_count > 0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if player == null or foreground == null:
		return
	var enemies: Array = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) <= MAX_RANGE * MAX_RANGE
	)
	if enemies.is_empty():
		return
	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)
	for index in attack_count:
		var target := enemies[index % enemies.size()] as Node2D
		var direction := player.global_position.direction_to(target.global_position)
		show_rifle(player, direction)
		var bullet := bullet_scene.instantiate() as SniperRifleBullet
		bullet.configure(player.global_position + direction * 44.0, direction, base_damage * damage_multiplier, size_multiplier, diamond_bullet_enabled, shadowless_bullet_enabled, ricochet_enabled, explosive_bullet_enabled)
		attack_cooldown.track(bullet)
		foreground.add_child(bullet)


func show_rifle(player: Node2D, direction: Vector2) -> void:
	var rifle := Sprite2D.new()
	rifle.texture = RIFLE_TEXTURE
	rifle.position = direction * 12.0
	rifle.rotation = direction.angle()
	rifle.scale = Vector2.ONE * RIFLE_SCALE
	rifle.z_index = 3
	player.add_child(rifle)
	var tween := rifle.create_tween()
	tween.tween_interval(RIFLE_VISIBLE_TIME)
	tween.tween_property(rifle, "modulate:a", 0.0, 0.1)
	tween.tween_callback(rifle.queue_free)


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"sniper_rifle_damage":
			damage_upgrade_quantity = int(current_upgrades[upgrade.id]["quantity"])
			refresh_damage_multiplier()
		"sniper_rifle_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.05)
		"sniper_rifle_rate":
			$Timer.wait_time = base_wait_time * permanent_attack_speed_multiplier * (1.0 - current_upgrades[upgrade.id]["quantity"] * 0.05)
			attack_cooldown.restart()
		"sniper_rifle_diamond_bullet":
			diamond_bullet_enabled = true
		"sniper_rifle_scope":
			scope_enabled = true
			refresh_damage_multiplier()
			apply_scope_view()
		"sniper_rifle_shadowless_bullet":
			shadowless_bullet_enabled = true
		"sniper_rifle_ricochet":
			ricochet_enabled = true
			refresh_damage_multiplier()
		"sniper_rifle_explosive_bullet":
			explosive_bullet_enabled = true
		"attack_count":
			attack_count = GameEvents.weapon_attack_count


func refresh_damage_multiplier() -> void:
	damage_multiplier = permanent_damage_multiplier * (1.0 + damage_upgrade_quantity * 0.05) * (SCOPE_DAMAGE_MULTIPLIER if scope_enabled else 1.0) * (RICOCHET_DAMAGE_MULTIPLIER if ricochet_enabled else 1.0)


func apply_scope_view() -> void:
	if scope_applied:
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	camera.zoom /= SCOPE_VIEW_MULTIPLIER
	scope_applied = true
