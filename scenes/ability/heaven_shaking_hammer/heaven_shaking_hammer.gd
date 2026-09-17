extends Node2D
class_name HeavenShakingHammerAbility

const SWING_DURATION := 0.48
const IMPACT_FRAME := 4
const SWING_FRAMES := 6
const WAVE_SPACING := 36.4
const WAVE_DELAY := 0.1

@onready var hammer_sprite: Sprite2D = $HammerSprite
@onready var launch_sound: AudioStreamPlayer2D = $LaunchSound
@onready var impact_sound: AudioStreamPlayer2D = $ImpactSound

var origin := Vector2.ZERO
var target := Vector2.ZERO
var damage := 12.0
var radius := 38.5
var extra_wave_count := 0
var lava_enabled := false
var pull_enabled := false
var is_heavy := false
var elapsed := 0.0
var impact_triggered := false

var shockwave_scene := preload("res://scenes/ability/heaven_shaking_hammer_shockwave/heaven_shaking_hammer_shockwave.tscn")


func configure(from: Vector2, to: Vector2, new_damage: float, new_radius: float, extra_waves: int, leaves_lava: bool = false, pulls_enemies: bool = false, heavy: bool = false) -> void:
	origin = from
	target = to
	damage = new_damage
	radius = new_radius
	extra_wave_count = extra_waves
	lava_enabled = leaves_lava
	pull_enabled = pulls_enemies
	is_heavy = heavy
	if is_heavy:
		damage *= 2.0
		radius *= 2.0


func _ready() -> void:
	var direction := origin.direction_to(target)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position = origin + direction * 42.0
	rotation = direction.angle() + PI * 0.5
	hammer_sprite.scale = Vector2.ONE * 0.1 * radius / 55.0
	if is_heavy:
		hammer_sprite.modulate = Color("ffda68")
	launch_sound.play()


func _process(delta: float) -> void:
	elapsed += delta
	var frame := mini(floori(elapsed / SWING_DURATION * SWING_FRAMES), SWING_FRAMES - 1)
	hammer_sprite.frame = frame
	if not impact_triggered:
		if pull_enabled:
			pull_enemies(delta)
		if is_heavy:
			var impact_time := SWING_DURATION * IMPACT_FRAME / SWING_FRAMES
			hammer_sprite.global_position = global_position + Vector2.UP * 110.0 * (1.0 - minf(elapsed / impact_time, 1.0))
	queue_redraw()
	if frame >= IMPACT_FRAME and not impact_triggered:
		impact_triggered = true
		spawn_shockwaves()
		impact_sound.play()
	if elapsed >= SWING_DURATION:
		hammer_sprite.visible = false
		if not launch_sound.playing and not impact_sound.playing:
			queue_free()


func pull_enemies(delta: float) -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var distance := enemy.global_position.distance_to(global_position)
		if distance > radius * 2.0 or distance <= 4.0:
			continue
		var movement := enemy.global_position.direction_to(global_position) * minf(240.0 * delta, distance - 4.0)
		if enemy is CharacterBody2D:
			(enemy as CharacterBody2D).move_and_collide(movement)
		else:
			enemy.global_position += movement


func _draw() -> void:
	if impact_triggered or not (pull_enabled or is_heavy):
		return
	var color := Color(1.0, 0.72, 0.2, 0.55)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, 2.0)
	if pull_enabled:
		var ring_radius := radius * 2.0 * (1.0 - fmod(elapsed * 4.0, 1.0))
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, color, 1.0)


func spawn_shockwaves() -> void:
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var direction := origin.direction_to(target)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	for index in extra_wave_count + 1:
		var wave := shockwave_scene.instantiate() as HeavenShakingHammerShockwave
		wave.configure(global_position + direction * WAVE_SPACING * index, damage, radius, WAVE_DELAY * index, lava_enabled)
		if has_meta("attack_cooldown"):
			get_meta("attack_cooldown").track(wave)
		parent.add_child(wave)
