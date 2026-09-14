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
var elapsed := 0.0
var impact_triggered := false

var shockwave_scene := preload("res://scenes/ability/heaven_shaking_hammer_shockwave/heaven_shaking_hammer_shockwave.tscn")


func configure(from: Vector2, to: Vector2, new_damage: float, new_radius: float, extra_waves: int) -> void:
	origin = from
	target = to
	damage = new_damage
	radius = new_radius
	extra_wave_count = extra_waves


func _ready() -> void:
	var direction := origin.direction_to(target)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position = origin + direction * 42.0
	rotation = direction.angle() + PI * 0.5
	hammer_sprite.scale = Vector2.ONE * 0.1 * radius / 55.0
	launch_sound.play()


func _process(delta: float) -> void:
	elapsed += delta
	var frame := mini(floori(elapsed / SWING_DURATION * SWING_FRAMES), SWING_FRAMES - 1)
	hammer_sprite.frame = frame
	if frame >= IMPACT_FRAME and not impact_triggered:
		impact_triggered = true
		spawn_shockwaves()
		impact_sound.play()
	if elapsed >= SWING_DURATION:
		hammer_sprite.visible = false
		if not launch_sound.playing and not impact_sound.playing:
			queue_free()


func spawn_shockwaves() -> void:
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var direction := origin.direction_to(target)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	for index in extra_wave_count + 1:
		var wave := shockwave_scene.instantiate() as HeavenShakingHammerShockwave
		wave.configure(global_position + direction * WAVE_SPACING * index, damage, radius, WAVE_DELAY * index)
		parent.add_child(wave)
