extends SceneTree

const GameEventsScript = preload("res://scenes/autoload/game_events.gd")

func _init() -> void:
	var events := GameEventsScript.new()
	events.reset_run_stats()
	events.record_weapon_damage("sword", 10.0)
	events.record_weapon_damage("sword", 2.5)
	events.record_weapon_damage("", 99.0)
	assert(is_equal_approx(events.weapon_damage["sword"], 12.5))
	assert(not events.weapon_damage.has(""))
	quit()
