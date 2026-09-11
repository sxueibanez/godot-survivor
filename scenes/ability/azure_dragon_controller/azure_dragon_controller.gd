extends Node
class_name AzureDragonController

const MAX_RANGE := 280.0
const FOUR_BEASTS_INTERVAL := 15.0
const FOUR_BEASTS_DURATION := 5.0
const FOUR_BEASTS_RADIUS := 92.0
const FOUR_BEASTS_HIT_RADIUS := 18.0
const FOUR_BEASTS_DAMAGE_MULTIPLIER := 0.5
const FOUR_BEASTS_HIT_INTERVAL_MS := 500
const FOUR_BEAST_COLORS := [Color("49dfff"), Color("ff5a32"), Color("64a9ff"), Color("f7f7ff")]

@export var azure_dragon_scene: PackedScene
@export var vermilion_bird_scene: PackedScene
@export var xuanwu_scene: PackedScene
@export var white_tiger_scene: PackedScene

var base_damage := 20.0
var base_cooldown := 4.0
var damage_multiplier := 1.0
var size_multiplier := 1.0
var cooldown_multiplier := 1.0
var permanent_damage_multiplier := 1.0
var permanent_attack_speed_multiplier := 1.0
var permanent_size_multiplier := 1.0
var character_damage_multiplier := 1.0
var dragon: AzureDragonAbility
var vermilion_bird: VermilionBirdAbility
var xuanwu: XuanwuAbility
var white_tiger: WhiteTigerAbility
var four_beasts_active := false
var four_beasts_time := 0.0
var four_beasts_hit_times: Dictionary = {}
var four_beasts_trails: Array[Line2D] = []
var four_beasts_rings: Array[Line2D] = []


func _ready() -> void:
	permanent_damage_multiplier = (1.0 + MetaProgression.get_upgrade_count("meta_damage") * 0.01) * character_damage_multiplier
	permanent_attack_speed_multiplier = 1.0 - MetaProgression.get_upgrade_count("meta_attack_speed") * 0.03
	permanent_size_multiplier = 1.0 + MetaProgression.get_upgrade_count("meta_weapon_size") * 0.05
	damage_multiplier = permanent_damage_multiplier
	size_multiplier = permanent_size_multiplier
	update_cooldown()
	$Timer.timeout.connect(on_timer_timeout)
	$FourBeastsTimer.timeout.connect(begin_four_beasts_rush)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	call_deferred("spawn_dragon")


func _process(delta: float) -> void:
	if not four_beasts_active:
		return
	four_beasts_time += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		end_four_beasts_rush()
		return
	var beasts: Array[Node2D] = [dragon, vermilion_bird, xuanwu, white_tiger]
	for index in beasts.size():
		var beast := beasts[index]
		var axis := Vector2.RIGHT.rotated(index * TAU / beasts.size() + four_beasts_time * 0.65)
		beast.global_position = player.global_position + axis * sin(four_beasts_time * 9.0 + index * 0.8) * FOUR_BEASTS_RADIUS
		beast.rotation = axis.angle()
		damage_ultimate_contacts(beast.global_position)
	update_four_beasts_effect(player, beasts)
	if four_beasts_time >= FOUR_BEASTS_DURATION:
		end_four_beasts_rush()


func spawn_dragon() -> void:
	if is_instance_valid(dragon):
		return
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	dragon = azure_dragon_scene.instantiate() as AzureDragonAbility
	dragon.configure(base_damage * damage_multiplier, size_multiplier)
	foreground.add_child(dragon)


func spawn_vermilion_bird() -> void:
	if is_instance_valid(vermilion_bird):
		return
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	vermilion_bird = vermilion_bird_scene.instantiate() as VermilionBirdAbility
	vermilion_bird.configure(base_damage * damage_multiplier, size_multiplier, get_attack_interval_multiplier())
	foreground.add_child(vermilion_bird)


func spawn_xuanwu() -> void:
	if is_instance_valid(xuanwu):
		return
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	xuanwu = xuanwu_scene.instantiate() as XuanwuAbility
	foreground.add_child(xuanwu)


func spawn_white_tiger() -> void:
	if is_instance_valid(white_tiger):
		return
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	white_tiger = white_tiger_scene.instantiate() as WhiteTigerAbility
	white_tiger.configure(base_damage * damage_multiplier, size_multiplier, get_attack_interval_multiplier())
	foreground.add_child(white_tiger)


func on_timer_timeout() -> void:
	if four_beasts_active:
		return
	if not is_instance_valid(dragon):
		spawn_dragon()
	if not is_instance_valid(dragon):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var target := find_nearest_enemy(get_tree().get_nodes_in_group("enemy"), player.global_position)
	if target != null:
		dragon.start_attack(target.global_position)


static func find_nearest_enemy(enemies: Array, origin: Vector2) -> Node2D:
	var nearest: Node2D
	for value: Variant in enemies:
		var enemy := value as Node2D
		if enemy == null:
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance <= MAX_RANGE * MAX_RANGE and (nearest == null or distance < origin.distance_squared_to(nearest.global_position)):
			nearest = enemy
	return nearest


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary) -> void:
	match upgrade.id:
		"azure_dragon_damage":
			damage_multiplier = permanent_damage_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.2)
			refresh_dragon()
		"azure_dragon_size":
			size_multiplier = permanent_size_multiplier * (1.0 + current_upgrades[upgrade.id]["quantity"] * 0.2)
			refresh_dragon()
		"azure_dragon_rate":
			cooldown_multiplier = maxf(0.1, 1.0 - current_upgrades[upgrade.id]["quantity"] * 0.15)
			update_cooldown()
			refresh_dragon()
			$Timer.start()
		"azure_dragon_vermilion_bird":
			spawn_vermilion_bird()
		"azure_dragon_xuanwu":
			spawn_xuanwu()
		"azure_dragon_white_tiger":
			spawn_white_tiger()
		"azure_dragon_four_beasts":
			$FourBeastsTimer.start(FOUR_BEASTS_INTERVAL)


func refresh_dragon() -> void:
	if is_instance_valid(dragon):
		dragon.configure(base_damage * damage_multiplier, size_multiplier)
	if is_instance_valid(vermilion_bird):
		vermilion_bird.configure(base_damage * damage_multiplier, size_multiplier, get_attack_interval_multiplier())
	if is_instance_valid(white_tiger):
		white_tiger.configure(base_damage * damage_multiplier, size_multiplier, get_attack_interval_multiplier())


func update_cooldown() -> void:
	$Timer.wait_time = base_cooldown * permanent_attack_speed_multiplier * cooldown_multiplier


func get_attack_interval_multiplier() -> float:
	return permanent_attack_speed_multiplier * cooldown_multiplier


func begin_four_beasts_rush() -> void:
	if not (is_instance_valid(dragon) and is_instance_valid(vermilion_bird) and is_instance_valid(xuanwu) and is_instance_valid(white_tiger)):
		return
	four_beasts_active = true
	four_beasts_time = 0.0
	four_beasts_hit_times.clear()
	$Timer.paused = true
	vermilion_bird.set_ultimate_active(true)
	xuanwu.set_ultimate_active(true)
	white_tiger.set_ultimate_active(true)
	dragon.set_ultimate_active(true)
	create_four_beasts_effect()


func end_four_beasts_rush() -> void:
	four_beasts_active = false
	$Timer.paused = false
	for beast: Node2D in [dragon, vermilion_bird, xuanwu, white_tiger]:
		if is_instance_valid(beast):
			beast.rotation = 0.0
			beast.call("set_ultimate_active", false)
	clear_four_beasts_effect()


func create_four_beasts_effect() -> void:
	clear_four_beasts_effect()
	var foreground := get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground == null:
		return
	for color: Color in FOUR_BEAST_COLORS:
		var trail := Line2D.new()
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(color, 0.0), color])
		trail.width = 8.0
		trail.gradient = gradient
		trail.z_index = -1
		foreground.add_child(trail)
		four_beasts_trails.append(trail)
	for ring_index in 2:
		var ring := Line2D.new()
		ring.closed = true
		ring.width = 5.0 if ring_index == 0 else 2.0
		ring.default_color = Color(0.75, 0.95, 1.0, 0.8 if ring_index == 0 else 0.5)
		ring.z_index = -1
		foreground.add_child(ring)
		four_beasts_rings.append(ring)


func update_four_beasts_effect(player: Node2D, beasts: Array[Node2D]) -> void:
	for index in mini(beasts.size(), four_beasts_trails.size()):
		var trail := four_beasts_trails[index]
		trail.add_point(beasts[index].global_position)
		if trail.get_point_count() > 18:
			trail.remove_point(0)
	for ring_index in four_beasts_rings.size():
		var ring := four_beasts_rings[ring_index]
		ring.global_position = player.global_position
		ring.rotation = four_beasts_time * (2.5 if ring_index == 0 else -3.5)
		ring.clear_points()
		var radius := 48.0 + ring_index * 22.0 + sin(four_beasts_time * 8.0 + ring_index) * 8.0
		for point_index in 32:
			var angle := TAU * point_index / 32.0
			var spike := 8.0 if point_index % 4 == 0 else 0.0
			ring.add_point(Vector2.RIGHT.rotated(angle) * (radius + spike))


func clear_four_beasts_effect() -> void:
	for effect: Node in four_beasts_trails + four_beasts_rings:
		if is_instance_valid(effect):
			effect.queue_free()
	four_beasts_trails.clear()
	four_beasts_rings.clear()


func damage_ultimate_contacts(center: Vector2) -> void:
	var now := Time.get_ticks_msec()
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy"):
		var enemy_id := enemy.get_instance_id()
		if now - int(four_beasts_hit_times.get(enemy_id, -FOUR_BEASTS_HIT_INTERVAL_MS)) < FOUR_BEASTS_HIT_INTERVAL_MS:
			continue
		if center.distance_squared_to(enemy.global_position) > FOUR_BEASTS_HIT_RADIUS * FOUR_BEASTS_HIT_RADIUS:
			continue
		var hurtbox := enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox == null or hurtbox.health_component == null or hurtbox.health_component.current_health <= 0.0:
			continue
		var critical_hit: Dictionary = GameEvents.get_critical_damage(base_damage * damage_multiplier * FOUR_BEASTS_DAMAGE_MULTIPLIER)
		var damage_amount := float(critical_hit["damage"])
		hurtbox.health_component.damage(damage_amount)
		GameEvents.record_weapon_damage("azure_dragon", damage_amount)
		GameEvents.heal_from_damage(damage_amount)
		hurtbox.show_damage(damage_amount, bool(critical_hit["critical"]))
		hurtbox.hit.emit()
		four_beasts_hit_times[enemy_id] = now
