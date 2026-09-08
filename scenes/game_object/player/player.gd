extends CharacterBody2D

const MAX_SPEED = 125
const ACCELERATION_SMOOTHING = 25

@export var character: Resource = preload("res://resources/characters/warrior.tres")

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var animation_player = $AnimationPlayer
@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent


var number_colliding_bodies := 0
var base_speed := 0
var base_health := 0.0
var previous_health := 0.0
var character_visual_scale := 1.0
var walk_animation_time := 0.0


func _ready():
	apply_character_visual()
	base_health = health_component.max_health * (1.0 + MetaProgression.get_upgrade_count("meta_health") * 0.01)
	health_component.max_health = base_health
	health_component.current_health = health_component.max_health
	previous_health = health_component.current_health
	base_speed = roundi(velocity_component.max_speed * (1.0 + MetaProgression.get_upgrade_count("meta_speed") * 0.01))
	velocity_component.max_speed = base_speed
	
	$CollisionArea2D.body_entered.connect(on_body_entered)
	$CollisionArea2D.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_changed.connect(on_health_changed)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	update_health_display()


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
	
	health_component.damage((1.0 + GameEvents.arena_difficulty * 0.05) * 10.0)
	damage_interval_timer.start()
	print(health_component.current_health)


func update_health_display():
	health_bar.value = health_component.get_health_percent()


#---------------------------------------------


func on_body_entered(other_body: Node2D):
	number_colliding_bodies += 1
	check_deal_damage()


func on_body_exited(other_body: Node2D):
	number_colliding_bodies -= 1


func on_damage_interval_timer_timeout():
	check_deal_damage()


func on_health_changed():
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
		velocity_component.max_speed = base_speed + (base_speed * current_upgrades["player_speed"]["quantity"] * 0.1)
	elif ability_upgrade.id == "player_health":
		var previous_max_health: float = health_component.max_health
		health_component.max_health = base_health * (1.0 + current_upgrades["player_health"]["quantity"] * 0.1)
		health_component.heal(health_component.max_health - previous_max_health)
