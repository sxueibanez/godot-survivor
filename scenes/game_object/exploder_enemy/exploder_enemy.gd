extends CharacterBody2D

const DETONATION_RANGE := 64.0
const DETONATION_DAMAGE := 15.0
const CHARGE_DURATION := 1.5

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

var charging := false
var charge_time := 0.0
var smoke_scene: PackedScene = preload("res://scenes/game_object/explosion_smoke/explosion_smoke.tscn")


func _ready() -> void:
	health_component.health_changed.connect(update_health_bar)


func _process(delta: float) -> void:
	if charging:
		charge_time += delta
		var progress := minf(charge_time / CHARGE_DURATION, 1.0)
		$Visuals.scale = Vector2.ONE * lerp(1.0, 1.4, progress)
		sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.18, 0.18), progress)
		if progress >= 1.0:
			detonate()
		return

	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= DETONATION_RANGE:
		charging = true
		velocity_component.accelerate_in_direction(Vector2.ZERO)


func detonate() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy != self and enemy is Node2D and global_position.distance_to(enemy.global_position) <= DETONATION_RANGE:
			var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.damage(DETONATION_DAMAGE)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= DETONATION_RANGE:
		var player_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if player_health != null:
			player_health.damage(DETONATION_DAMAGE * 10.0)
	spawn_smoke()
	health_component.damage(9999.0)


func spawn_smoke() -> void:
	var foreground: Node2D = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	var smoke := smoke_scene.instantiate() as Node2D
	foreground.add_child(smoke)
	smoke.global_position = global_position


func update_health_bar() -> void:
	health_bar.value = health_component.get_health_percent()
