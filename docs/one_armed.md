# 单臂者

基础生命 100、移速 90，沿用当前默认配置。全局只能装备一把武器（包含宝塔等辅助武器），但仍能升级已有武器、触发该武器的多发或衍生攻击。

武器伤害 ×1.5，含暴击与持续伤害。攻击速度 ×1.5，即攻击间隔 ÷1.5；不是移动速度，也不是弹道飞行速度。升级、初始选择、挑战奖励和直接装备事件均受单武器上限约束。

绘画由内置 imagegen 工具生成，保存原图至 `C:/GoDot_Game/godot-survivor-tutorial-main/assets/characters/one_armed_original.png`。使用 AtlasTexture 裁掉透明边距，没有缩小原图文件；显示高度沿用当前约 20，复用现有走路动画。

## 本次新增文件

- `assets/characters/one_armed_original.png` 及 `.png.import`。
- `resources/characters/one_armed.tres`。
- `docs/one_armed.md`。

## 本次修改文件

- `resources/characters/character_data.gd`。
- `scenes/game_object/player/character_passives.gd`、`player.gd`。
- `scenes/autoload/game_events.gd`。
- `scenes/manager/upgrade_manager.gd`。
- `scenes/ui/character_select.gd`。
- `tests/test_new_characters.gd`。
- `scenes/ability/sword_ability_controller/sword_ability_controller.gd`。
- `scenes/ability/axe_ability_controller/axe_ability_controller.gd`。
- `scenes/ability/laser_gun_ability_controller/laser_gun_ability_controller.gd`。
- `scenes/ability/lightning_whip_ability_controller/lightning_whip_ability_controller.gd`。
- `scenes/ability/bomb_ability_controller/bomb_ability_controller.gd`。
- `scenes/ability/thunder_orb_book_controller/thunder_orb_book_controller.gd`。
- `scenes/ability/sniper_rifle_controller/sniper_rifle_controller.gd`。
- `scenes/ability/heaven_shaking_hammer_controller/heaven_shaking_hammer_controller.gd`。
- `scenes/ability/azure_dragon_controller/azure_dragon_controller.gd`。

## 绘画提示词

Use case: stylized-concept. Asset type: transparent Godot playable character sprite, high resolution original. Reference image is style only, not edit target. Create a NEW single character named One-Armed Warrior, matching the reference's chibi miniature pixel art, big head and short body, chunky square pixels, dark plum outline, limited colors, front view slightly facing right, complete body including feet. Character has exactly ONE arm: right arm holding one compact sword, left arm absent with neatly closed empty sleeve at shoulder, non-graphic, no prosthesis, no extra hand. Short dark hair, rust orange sleeveless tunic, brown leather belt, dark trousers and boots, determined expression. Genuine transparent alpha background, centered isolated character, no scene, no text, no watermark, no shadow outside sprite. Keep crisp pixel edges and readable silhouette, retain high resolution image, do not reduce to 16x16.
