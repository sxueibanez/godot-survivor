# 新角色实现与改动清单

本次项目：`C:/GoDot_Game/godot-survivor-tutorial-main`。原有战士、魔导师和嗜血者的基础属性未修改。

## 默认数值

用户没有指定这四个角色的生命、速度和技能具体数值，暂统一为最大生命 100、移速 90。各角色资源以及 CharacterData 导出属性可在 Godot 检查器调整。

|角色|技能默认值|
|---|---|
|孤胆枪手|140 范围内，每少一个敌人远程增伤 8%，最多 40%；精英或 Boss 进入 60 范围时加速 50%，持续 1.5 秒，冷却 10 秒|
|赌命书生|每次升级可支付当前生命 15%，刷新一次选项；击杀精英恢复最大生命 15%；不用于初始武器或挑战奖励选项|
|浪客|空格沿移动方向冲刺 60，持续 0.15 秒，冷却 3.5 秒；释放冲刺后 1 秒内，每次伤害在倍率与暴击结算后固定 +10（含持续伤害），不会被一次攻击消耗；不提供无敌|
|复仇者|实际损失生命累计 40 后狂怒 5 秒，增伤 40%，获得最大生命 20% 的临时护盾；狂怒期间不积攒怒气，临时护盾到期不清除原有护盾|

暂停时技能计时停止。四个角色复用原有移动动画，增加左下角技能状态提示。

## 图像交付

使用内置图像生成工具，参考项目原有小尺寸像素角色；生成后保留透明背景，裁切主体，最近邻缩放为 16×16 游戏贴图。没有增加图像处理依赖。

交付贴图（绝对路径）：

- `C:/GoDot_Game/godot-survivor-tutorial-main/assets/characters/lone_gunner.png`
- `C:/GoDot_Game/godot-survivor-tutorial-main/assets/characters/gambling_scholar.png`
- `C:/GoDot_Game/godot-survivor-tutorial-main/assets/characters/ronin.png`
- `C:/GoDot_Game/godot-survivor-tutorial-main/assets/characters/avenger.png`

生成提示词规格：单个完整角色、透明背景、正面略朝右、与现有角色一致的迷你像素比例、深色轮廓、有限色板、清晰像素边缘，无文字、无场景、无额外角色。四个主体分别为棕色宽檐帽与风衣的持枪者、青绿色长袍持书书生、深蓝服装红围巾的浪客、深色盔甲与红色面部标记的复仇者。走路由现有 Godot 动画完成，不生成新动画帧。

## 本次新增文件

- `assets/characters/lone_gunner.png`、`gambling_scholar.png`、`ronin.png`、`avenger.png`，以及各自 `.png.import`。
- `resources/characters/lone_gunner.tres`、`gambling_scholar.tres`、`ronin.tres`、`avenger.tres`。
- `scenes/game_object/player/character_passives.gd` 及 `.uid`。
- `tests/test_new_characters.gd`、`tests/test_new_characters.tscn`。
- `docs/new_characters.md`（本文件）。

## 本次修改文件

- `project.godot`：空格冲刺输入。
- `resources/characters/character_data.gd`：技能参数。
- `scenes/game_object/player/player.gd`：技能节点、移动、护盾和武器类型接入。
- `scenes/autoload/game_events.gd`：角色伤害与整轮攻击强化、敌人死亡事件。
- `scenes/component/health_component.gd`：实际受伤事件、非致命生命支付、限时护盾。
- `scenes/component/hurtbox_component.gd`：伤害传递武器类型。
- `scenes/manager/challenge_manager.gd`：为精英添加分组（保留原有未提交挑战代码）。
- `scenes/manager/upgrade_manager.gd`：升级刷新接入（保留原有挑战奖励逻辑）。
- `scenes/ui/character_select.gd`：七角色可滚动选择列表与图标。
- `scenes/ui/upgrade_screen.gd`：支付生命刷新按钮。
- `scenes/ability/sword_ability_controller/sword_ability_controller.gd`
- `scenes/ability/axe_ability_controller/axe_ability_controller.gd`
- `scenes/ability/laser_gun_ability_controller/laser_gun_ability_controller.gd`
- `scenes/ability/lightning_whip_ability_controller/lightning_whip_ability_controller.gd`
- `scenes/ability/bomb_ability_controller/bomb_ability_controller.gd`
- `scenes/ability/thunder_orb_book_controller/thunder_orb_book_controller.gd`
- `scenes/ability/sniper_rifle_controller/sniper_rifle_controller.gd`
- `scenes/ability/heaven_shaking_hammer_controller/heaven_shaking_hammer_controller.gd`
- `scenes/ability/azure_dragon_controller/azure_dragon_controller.gd`

上述九个攻击控制器接入一次整轮强化；以下文件接入远程武器伤害倍率：

- `scenes/ability/bomb_ability/bomb_ability.gd`
- `scenes/ability/bomb_burn/bomb_burn.gd`
- `scenes/ability/laser_gun_ability/laser_gun_ability.gd`
- `scenes/ability/sniper_rifle_bullet/sniper_rifle_bullet.gd`
- `scenes/ability/thunder_orb_book/thunder_orb_book.gd`
- `scenes/ability/thunder_plasma/thunder_plasma.gd`
- `scenes/game_object/arcane_projectile/arcane_projectile.gd`
- `scenes/game_object/cyclops_laser/cyclops_laser.gd`

其他原本已修改的文件不属于本次改动。

## 验证

新增测试 `res://tests/test_new_characters.tscn` 通过：四角色倍率、精英触发与冷却、暂停计时、升级支付与一次刷新、精英治疗、冲刺整轮强化、狂怒与临时护盾、七角色列表宽度与滚动。

挑战、炸弹、雷球书、青龙回归检查通过。宝塔测试在仅内存清空永久升级后通过，没有写入用户存档。

狙击枪测试期待爆炸伤害 50，而原实现倍率为 0.05，本次未改动其行为。部分场景退出时还有已有资源泄漏警告，需要另行排查。

## 2026-09-16 数值调整

战士近战加成 20%；魔导师远程加成 20%；嗜血者每损失 10 生命增伤 1.5%、移速 +1.5。浪客数值与行为见上表，旧的下一轮强化已删除。

这次修改文件：

- `resources/characters/warrior.tres`、`elf_ranger.tres`、`blooddrinker.tres`、`ronin.tres`、`character_data.gd`。
- `scenes/game_object/player/player.gd`、`character_passives.gd`。
- `scenes/component/velocity_component.gd`（移速支持小数）。
- `scenes/autoload/game_events.gd`、`scenes/ability/bomb_burn/bomb_burn.gd`（每次伤害固定加成）。
- 上述九个攻击控制器（移除旧的整轮倍率接入）。
- `scenes/ui/pause_menu.gd`（移速显示小数）。
- `tests/test_new_characters.gd`、`tests/test_character_passives.gd`。
- `docs/new_characters.md`。
