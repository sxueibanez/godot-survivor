extends PanelContainer
class_name AbilityUpgradeCard

signal selected

const WEAPON_ICONS := {
	"sword": preload("res://scenes/ability/sword_ability/sword.png"),
	"axe": preload("res://scenes/ability/axe_ability/axe.png"),
	"laser_gun": preload("res://scenes/ability/laser_gun_ability/laser_gun.png"),
	"bomb": preload("res://assets/abilities/bomb.png"),
	"thunder_orb_book": preload("res://assets/abilities/thunder_orb_book.png"),
}

const ICON_SHEETS := {
	"common": preload("res://assets/icons/skills/common_skill_icons.png"),
	"sword": preload("res://assets/icons/skills/sword_skill_icons.png"),
	"axe": preload("res://assets/icons/skills/axe_skill_icons.png"),
	"laser": preload("res://assets/icons/skills/laser_gun_skill_icons.png"),
	"whip": preload("res://assets/icons/skills/lightning_whip_skill_icons.png"),
	"bomb": preload("res://assets/icons/skills/bomb_skill_icons.png"),
	"thunder": preload("res://assets/icons/skills/thunder_orb_skill_icons.png"),
	"general": preload("res://assets/icons/skills/general_skill_icons.png"),
	"whip_weapon": preload("res://scenes/ability/lightning_whip_ability/lightning_whip_frames.png"),
	"azure_skills": preload("res://assets/icons/skills/azure_dragon_skill_icons.png"),
}

const ICON_REGIONS := {
	"sword_damage": ["common", Rect2(0, 0, 627, 627)],
	"axe_damage": ["common", Rect2(0, 0, 627, 627)],
	"laser_gun_damage": ["common", Rect2(0, 0, 627, 627)],
	"lightning_whip_damage": ["common", Rect2(0, 0, 627, 627)],
	"bomb_damage": ["common", Rect2(0, 0, 627, 627)],
	"thunder_orb_damage": ["common", Rect2(0, 0, 627, 627)],
	"azure_dragon_damage": ["common", Rect2(0, 0, 627, 627)],
	"sword_size": ["common", Rect2(627, 0, 627, 627)],
	"axe_size": ["common", Rect2(627, 0, 627, 627)],
	"laser_gun_size": ["common", Rect2(627, 0, 627, 627)],
	"lightning_whip_size": ["common", Rect2(627, 0, 627, 627)],
	"bomb_size": ["common", Rect2(627, 0, 627, 627)],
	"thunder_orb_size": ["common", Rect2(627, 0, 627, 627)],
	"azure_dragon_size": ["common", Rect2(627, 0, 627, 627)],
	"sword_rate": ["common", Rect2(0, 627, 627, 627)],
	"axe_rate": ["common", Rect2(0, 627, 627, 627)],
	"laser_gun_cooldown": ["common", Rect2(0, 627, 627, 627)],
	"lightning_whip_rate": ["common", Rect2(0, 627, 627, 627)],
	"bomb_rate": ["common", Rect2(0, 627, 627, 627)],
	"thunder_orb_rate": ["common", Rect2(0, 627, 627, 627)],
	"azure_dragon_rate": ["common", Rect2(0, 627, 627, 627)],
	"sword_chain": ["sword", Rect2(0, 0, 627, 627)],
	"sword_rain": ["sword", Rect2(627, 0, 627, 627)],
	"sword_rain_giant": ["sword", Rect2(0, 627, 627, 627)],
	"sword_barrage": ["sword", Rect2(627, 627, 627, 627)],
	"axe_return": ["axe", Rect2(0, 0, 627, 418)],
	"axe_knockback": ["axe", Rect2(627, 0, 627, 418)],
	"axe_reflect": ["axe", Rect2(0, 418, 627, 418)],
	"axe_count": ["axe", Rect2(627, 418, 627, 418)],
	"axe_distance_power": ["axe", Rect2(0, 836, 627, 418)],
	"laser_gun_damage_ramp": ["laser", Rect2(0, 0, 627, 418)],
	"laser_gun_reflect": ["laser", Rect2(627, 0, 627, 418)],
	"laser_gun_stun": ["laser", Rect2(0, 418, 627, 418)],
	"laser_gun_auto_aim": ["laser", Rect2(627, 418, 627, 418)],
	"laser_gun_kill_duration": ["laser", Rect2(0, 836, 627, 418)],
	"lightning_chain": ["whip", Rect2(0, 0, 627, 627)],
	"lightning_cloud": ["whip", Rect2(627, 0, 627, 627)],
	"lightning_wide_arc": ["whip", Rect2(0, 627, 627, 627)],
	"bomb_bounce": ["bomb", Rect2(0, 0, 627, 627)],
	"bomb_burn": ["bomb", Rect2(627, 0, 627, 627)],
	"bomb_cluster": ["bomb", Rect2(0, 627, 627, 627)],
	"thunder_orb_chain": ["thunder", Rect2(0, 0, 627, 418)],
	"thunder_orb_count": ["thunder", Rect2(627, 0, 627, 418)],
	"thunder_orb_growth": ["thunder", Rect2(0, 418, 627, 418)],
	"thunder_orb_plasma": ["thunder", Rect2(627, 418, 627, 418)],
	"thunder_orb_boss_tracking": ["thunder", Rect2(0, 836, 627, 418)],
	"player_speed": ["general", Rect2(0, 0, 627, 418)],
	"player_health": ["general", Rect2(627, 0, 627, 418)],
	"critical_hit": ["general", Rect2(0, 418, 627, 418)],
	"critical_damage": ["general", Rect2(627, 418, 627, 418)],
	"speed_damage_no_crit": ["general", Rect2(0, 836, 627, 418)],
	"attack_count": ["general", Rect2(627, 836, 627, 418)],
	"lightning_whip": ["whip_weapon", Rect2(0, 0, 418, 418)],
	"azure_dragon_vermilion_bird": ["azure_skills", Rect2(0, 0, 627, 627)],
	"azure_dragon_xuanwu": ["azure_skills", Rect2(627, 0, 627, 627)],
	"azure_dragon_white_tiger": ["azure_skills", Rect2(0, 627, 627, 627)],
	"azure_dragon_four_beasts": ["azure_skills", Rect2(627, 627, 627, 627)],
}

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var icon_texture: TextureRect = %IconTexture

var disabled := false


func _ready():
	gui_input.connect(on_gui_input)
	mouse_entered.connect(on_mouse_entered)


func play_in(delay: float = 0):
	modulate = Color.TRANSPARENT
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("in")


func play_discard():
	$AnimationPlayer.play("discard")


func set_ability_upgrade(upgrade: AbilityUpgrade) -> void:
	name_label.text = upgrade.name
	description_label.text = upgrade.description
	icon_texture.texture = get_upgrade_icon(upgrade)
	icon_texture.visible = icon_texture.texture != null


static func get_upgrade_icon(upgrade: AbilityUpgrade) -> Texture2D:
	if upgrade.icon != null:
		return upgrade.icon
	if WEAPON_ICONS.has(upgrade.id):
		return WEAPON_ICONS[upgrade.id]
	if not ICON_REGIONS.has(upgrade.id):
		return null
	var icon_data: Array = ICON_REGIONS[upgrade.id]
	var icon := AtlasTexture.new()
	icon.atlas = ICON_SHEETS[icon_data[0]]
	icon.region = icon_data[1]
	return icon


func select_card():
	disabled = true
	$AnimationPlayer.play("selected")
	
	# make other cards disappear
	for other_card in get_tree().get_nodes_in_group("upgrade_card"):
		if other_card == self:
			continue
		(other_card as AbilityUpgradeCard).play_discard()
	
	await $AnimationPlayer.animation_finished
	selected.emit()


func on_gui_input(event: InputEvent):
	if disabled:
		return

	if event.is_action_pressed("left_click"):
		select_card()


func on_mouse_entered():
	if disabled:
		return true

	$HoverAnimationPlayer.play("hover")
