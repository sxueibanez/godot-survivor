extends CharacterBody2D

const DETECTION_RANGE := 175.0
const TOWER_ATTACK_RANGE := 30.0

var mode: Node
var tower_damage := 7.0
var attack_left := 0.0
var kind := "normal"

@onready var visuals := $Visuals
@onready var movement: VelocityComponent = $VelocityComponent
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	$HurtboxComponent.hit.connect(on_hit)
	health.health_changed.connect(update_health_bar)
	$VelocityComponent.slow_changed.connect(on_slow_changed)
	update_health_bar()


func _process(delta: float) -> void:
	if not is_instance_valid(mode) or mode.finished or health.current_health <= 0.0:
		return
	attack_left = maxf(attack_left - delta, 0.0)
	var target: Node2D
	if mode.defense_active:
		target = mode.tower
	elif is_instance_valid(mode.player) and global_position.distance_squared_to(mode.player.global_position) <= DETECTION_RANGE * DETECTION_RANGE:
		target = mode.player
	if target == null:
		movement.accelerate_in_direction(Vector2.ZERO)
	else:
		var offset := target.global_position - global_position
		if mode.defense_active and offset.length() <= TOWER_ATTACK_RANGE:
			movement.accelerate_in_direction(Vector2.ZERO)
			if attack_left <= 0.0:
				mode.damage_tower(tower_damage)
				attack_left = 1.0
		else:
			movement.accelerate_in_direction(offset.normalized())
	movement.move(self)
	var horizontal := signf(velocity.x)
	if horizontal != 0.0:
		visuals.scale = Vector2(-horizontal, 1.0)


func on_hit() -> void:
	$HitRandomAudioPlayerComponent.play_random()


func update_health_bar() -> void:
	$HealthBar.value = health.get_health_percent()


func on_slow_changed(active: bool) -> void:
	$ParalyzeIcon.visible = active
