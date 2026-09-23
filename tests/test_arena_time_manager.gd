extends SceneTree


func _init() -> void:
	var manager := ArenaTimeManager.new()
	root.add_child(manager)
	manager._process(305.0)
	assert(manager.arena_difficulty == 61)
	assert(GameEvents.arena_difficulty == 61)
	quit()
