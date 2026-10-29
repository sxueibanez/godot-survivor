extends Node2D


@onready var collision_shape_2d = $Area2D/CollisionShape2D
@onready var sprite = $Sprite2D

var collecting := false
var experience_value := 1.0
var pending_experience := 0.0
var collect_target: Node2D
var retry_time := 0.0


func _ready():
	$Area2D.area_entered.connect(on_area_entered)
	set_process(false)
	if GameEvents.auto_collect_experience:
		collect_to_player.call_deferred()


func _process(delta: float) -> void:
	if not GameEvents.auto_collect_experience:
		set_process(false)
		return
	retry_time -= delta
	if retry_time <= 0.0:
		retry_time = 0.25
		collect_to_player()


func is_valid_target(player: Node2D) -> bool:
	if not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_in_group("player"):
		return false
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	return health == null or health.current_health > 0.0


func tween_collect(percent: float, start_position: Vector2):
	if not is_valid_target(collect_target):
		return
	
	global_position = start_position.lerp(collect_target.global_position, percent)
	
	var direction_from_start = collect_target.global_position - start_position

	var target_rotation = direction_from_start.angle() + deg_to_rad(90)
	rotation = lerp_angle(rotation, target_rotation, 1 - exp(-2 * get_process_delta_time()))


func collect():
	if not is_valid_target(collect_target):
		collecting = false
		collect_target = null
		sprite.scale = Vector2.ONE
		collision_shape_2d.set_deferred("disabled", false)
		set_process(GameEvents.auto_collect_experience)
		return
	GameEvents.emit_experience_vial_collected(pending_experience)
	queue_free()


func disable_collision():
	collision_shape_2d.disabled = true


func collect_to_player() -> void:
	if collecting:
		return
	collect_target = get_tree().get_first_node_in_group("player") as Node2D
	if not is_valid_target(collect_target):
		set_process(GameEvents.auto_collect_experience)
		return
	collecting = true
	set_process(false)
	pending_experience = experience_value * GameEvents.get_curse_experience_multiplier_at(global_position)
	Callable(disable_collision).call_deferred()
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_method(tween_collect.bind(global_position), 0.0, 1.0, .5) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.05).set_delay(0.45)
	tween.chain()
	tween.tween_callback(collect)
	
	$RandomAudioStreamPlayer2DComponent.play_random()


func on_area_entered(_other_area: Area2D):
	collect_to_player()
