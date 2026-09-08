extends CanvasLayer


func _ready():
	GameEvents.player_damaged.connect(on_player_damaged)
	GameEvents.player_healed.connect(on_player_healed)


func on_player_damaged():
	$AnimationPlayer.play("hit")


func on_player_healed():
	$AnimationPlayer.play("heal")
