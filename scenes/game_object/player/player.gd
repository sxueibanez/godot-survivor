extends CharacterBody2D

const MAX_SPEED = 125
const ACCELERATION_SMOOTHING = 25
const BOSS_CONTACT_KNOCKBACK_SPEED := 360.0
const BOSS_CONTACT_KNOCKBACK_DURATION := 0.28

@export var character: Resource = preload("res://resources/characters/warrior.tres")

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar
@onready var shield_bar = $ShieldBar
@onready var abilities = $Abilities
@onready var animation_player = $AnimationPlayer
@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent


var number_colliding_bodies := 0
var base_speed := 0
var base_health := 0.0
var previous_health := 0.0
var player_speed_upgrade_quantity := 0
var player_health_upgrade_quantity := 0
var character_visual_scale := 1.0
var walk_animation_time := 0.0


func _ready():
	apply_character_visual()
	apply_character_base_stats()
	
	$CollisionArea2D.body_entered.connect(on_body_entered)
	$CollisionArea2D.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_changed.connect(on_health_changed)
	health_component.shield_changed.connect(update_shield_display)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	update_health_display()
	update_shield_display(health_component.shield)


func apply_character_visual() -> void:
	character_visual_scale = float(character.get("visual_scale"))
	visuals.scale = Vector2.ONE * character_visual_scale
	var character_sprite := character.get("sprite") as Texture2D
	if character_sprite == null:
		return
	var sprite := $Visuals/Sprite2D as Sprite2D
	sprite.texture = character_sprite
	var sprite_offset: Vector2 = character.get("sprite_offset")
	sprite.offset = sprite_offset
	if bool(character.get("custom_walk_animation")):
		animation_player.stop()
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0


func set_character(new_character: Resource) -> void:
	character = new_character
	apply_character_visual()
	if is_node_ready():
		apply_character_base_stats()


func apply_character_base_stats() -> void:
	base_health = float(character.get("max_health")) * (1.0 + MetaProgression.get_upgrade_count("meta_health") * 0.01)
	health_component.max_health = get_upgraded_max_health()
	health_component.current_health = health_component.max_health
	previous_health = health_component.max_health
	base_speed = roundi(int(character.get("move_speed")) * (1.0 + MetaProgression.get_upgrade_count("meta_speed") * 0.01))
	refresh_missing_health_passive()
	update_health_display()


static func get_missing_health_stacks(max_health: float, current_health: float) -> int:
	return floori(maxf(max_health - current_health, 0.0) / 10.0)


static func get_speed_damage_multiplier(move_speed: int) -> float:
	return 1.0 + floori(move_speed / 20.0) * 0.1


func refresh_missing_health_passive() -> void:
	var stacks := get_missing_health_stacks(health_component.max_health, health_component.current_health)
	var move_speed := roundi(base_speed * (1.0 + player_speed_upgrade_quantity * 0.1)) + stacks * int(character.get("missing_health_speed_bonus_per_10"))
	move_speed = roundi(move_speed * GameEvents.support_move_speed_multiplier)
	velocity_component.max_speed = move_speed
	GameEvents.player_damage_multiplier = 1.0 + stacks * float(character.get("missing_health_damage_bonus_per_10"))
	if GameEvents.speed_damage_no_crit:
		GameEvents.player_damage_multiplier *= get_speed_damage_multiplier(move_speed)


func get_upgraded_max_health() -> float:
	return base_health * (1.0 + player_health_upgrade_quantity * 0.1) * GameEvents.support_health_multiplier


func refresh_support_stats() -> void:
	var health_ratio: float = health_component.get_health_percent()
	health_component.max_health = get_upgraded_max_health()
	health_component.current_health = health_component.max_health * health_ratio
	previous_health = health_component.current_health
	health_component.health_changed.emit()
	update_shield_display(health_component.shield)


func _process(delta):
	var movement_vector = get_movement_vector()
	var direction = movement_vector.normalized()
	velocity_component.accelerate_in_direction(direction)
	velocity_component.move(self)
	
	if bool(character.get("custom_walk_animation")):
		update_custom_walk_animation(movement_vector, delta)
	elif movement_vector.x != 0 || movement_vector.y != 0:
		animation_player.play("walk")
	else:
		animation_player.play("RESET")
	
	var move_sign = sign(movement_vector.x)
	if move_sign != 0:
		visuals.scale = Vector2(move_sign * character_visual_scale, character_visual_scale)


func update_custom_walk_animation(movement_vector: Vector2, delta: float) -> void:
	if movement_vector == Vector2.ZERO:
		visuals.position = Vector2.ZERO
		visuals.rotation = 0.0
		return
	walk_animation_time += delta * 10.0
	visuals.position.y = sin(walk_animation_time) * float(character.get("walk_bob_height"))
	visuals.rotation = sin(walk_animation_time) * float(character.get("walk_tilt"))


func get_movement_vector():	
	var x_movement = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y_movement = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	return Vector2(x_movement, y_movement)


func check_deal_damage():
	if number_colliding_bodies == 0 || !damage_interval_timer.is_stopped():
		return
	
	health_component.damage((1.0 + GameEvents.arena_difficulty * 0.05) * 10.0, get_contact_damage_source())
	damage_interval_timer.start()
	print(health_component.current_health)


func update_health_display():
	health_bar.value = health_component.get_health_percent()


func update_shield_display(current_shield: float) -> void:
	shield_bar.value = current_shield / health_component.max_health if health_component.max_health > 0.0 else 0.0


#---------------------------------------------


func on_body_entered(other_body: Node2D):
	number_colliding_bodies += 1
	if other_body.is_in_group("boss"):
		var direction := global_position - other_body.global_position
		velocity_component.apply_knockback(Vector2.RIGHT if direction == Vector2.ZERO else direction, BOSS_CONTACT_KNOCKBACK_SPEED, BOSS_CONTACT_KNOCKBACK_DURATION)
	check_deal_damage()


func on_body_exited(other_body: Node2D):
	number_colliding_bodies -= 1


func get_contact_damage_source() -> String:
	var enemy_names := {"BasicEnemy": "小怪", "WizardEnemy": "法师怪", "RangedEnemy": "远程怪", "ExploderEnemy": "炸弹人", "CyclopsBat": "独眼蝙蝠", "IronGolem": "铁魔像"}
	for body: Node2D in $CollisionArea2D.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			return str(body.get_meta("display_name", enemy_names.get(body.name, "小怪")))
	return "小怪"


func on_damage_interval_timer_timeout():
	check_deal_damage()


func on_health_changed():
	refresh_missing_health_passive()
	if health_component.current_health < previous_health:
		GameEvents.emit_player_damaged()
		$HitRandomStreamPlayer.play_random()
	elif health_component.current_health > previous_health:
		GameEvents.emit_player_healed()
	update_health_display()
	previous_health = health_component.current_health


func on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if ability_upgrade is Ability:
		var ability = ability_upgrade as Ability
		var controller: Node = ability.ability_controller_scene.instantiate()
		controller.set("character_damage_multiplier", character.call("get_weapon_damage_multiplier", ability))
		abilities.add_child(controller)
	elif ability_upgrade.id == "player_speed":
		player_speed_upgrade_quantity = int(current_upgrades["player_speed"]["quantity"])
		refresh_missing_health_passive()
	elif ability_upgrade.id == "speed_damage_no_crit":
		refresh_missing_health_passive()
	elif ability_upgrade.id == "player_health":
		var previous_max_health: float = health_component.max_health
		player_health_upgrade_quantity = int(current_upgrades["player_health"]["quantity"])
		health_component.max_health = get_upgraded_max_health()
		health_component.heal(health_component.max_health - previous_max_health)
