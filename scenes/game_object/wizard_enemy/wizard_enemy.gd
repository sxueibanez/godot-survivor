extends CharacterBody2D

@onready var visuals := $Visuals
@onready var velocity_component: VelocityComponent = $VelocityComponent


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	$HealthComponent.health_changed.connect(update_health_bar)
	$VelocityComponent.slow_changed.connect(on_slow_changed)


func _process(delta):
	velocity_component.accelerate_to_player()
	velocity_component.move(self)

	var move_sign = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(move_sign, 1)


func on_hit():
	$HitRandomAudioPlayerComponent.play_random()


func update_health_bar() -> void:
	$HealthBar.value = $HealthComponent.get_health_percent()


func on_slow_changed(active: bool) -> void:
	$ParalyzeIcon.visible = active
