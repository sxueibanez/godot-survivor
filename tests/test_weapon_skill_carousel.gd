extends SceneTree


func _initialize() -> void:
	call_deferred("run_check")


func run_check() -> void:
	var tree := load("res://scenes/ui/weapon_skill_tree.tscn").instantiate()
	root.add_child(tree)
	await process_frame
	assert((tree.get_node("%WeaponTabs") as HBoxContainer).get_child_count() == 9)
	tree.call("on_weapon_selected", "heaven_shaking_hammer")
	await process_frame
	assert((tree.get_node("%WeaponScroll") as ScrollContainer).scroll_horizontal > 0)
	quit()
