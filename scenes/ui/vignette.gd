extends CanvasLayer

const LOW_HEALTH_THRESHOLD := 0.25

@onready var low_health_overlay: ColorRect = $LowHealthOverlay
var warning_time := 0.0


func _ready():
	GameEvents.player_damaged.connect(on_player_damaged)
	GameEvents.player_healed.connect(on_player_healed)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var health := player.get_node_or_null("HealthComponent") as HealthComponent if player != null else null
	var health_percent := health.get_health_percent() if health != null else 1.0
	low_health_overlay.visible = health_percent > 0.0 and health_percent <= LOW_HEALTH_THRESHOLD
	if low_health_overlay.visible:
		warning_time += delta
		low_health_overlay.modulate.a = 0.28 + 0.12 * sin(warning_time * 3.0)
	else:
		warning_time = 0.0


func on_player_damaged():
	$AnimationPlayer.play("hit")


func on_player_healed():
	$AnimationPlayer.play("heal")
