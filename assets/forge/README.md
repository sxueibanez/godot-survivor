# 熔火铸炉：首版交付

## 状态与进入方式

已接入可玩玩法。三种小怪与熔炉暴君已换为 `sprites/` 中的 7 张真实透明生成精灵表，覆盖 128 个播放帧（守卫待机有一个保持帧）。旧人物占位图不再进入游戏。
环境仍沿用 `placeholders/` 中的素材。地面燃烧、定向喷火、裂缝喷发、死亡余烬已接入 `sprites/fire-effects-v2.png`，每种6帧；其他特效继续复用已有资源。
炉膛守卫显示高度改为70，碰撞仍用原42高度计算。铸炉敌人的接触/技能伤害已提高，血量和技能时序保持不变；Boss出生改为地图内有效地面位置，离开较大铸炉地图时玩家回到共享地图中央。
人物按实际图片尺寸和固定网格创建 AtlasTexture，透明边界裁切并统一脚底锚点，最近邻显示；不沿用手工 RUN_X 裁切。
最新提示词、图片清单和切帧说明见 [sprites/README.md](sprites/README.md)。
参考图 `reference/tyrant-reference.png` 和 `reference/tyrant-walk-rejected.png` 不进入游戏：
这些早期图片生成结果印有棋盘格背景，走路图还不符合要求的 1536×192 网格；它们已由上述新精灵表替代。
具体生成提示词、各素材替换路径和事件帧见 [art_prompts.md](art_prompts.md)。

- 普通模式：地图池包含 ID 5，首轮五张地图打乱顺序，随后继续随机无限闯关。
- 无尽模式：初始地图池增加 ID 5；铸炉地图只刷新三种怪，其他地图不自动混入它们。
- Boss 车轮战：每轮增加第五场熔炉暴君，额外随机 Boss 池也包含它；原有初始 5 次、后续轮 3 次升级规则不变。
- 测试入口：战斗右下角地图列表选择“熔火铸炉”，点击“熔炉暴君”生成 Boss。
- 沿用现有第四张地图音乐，没有新增音频、插件或依赖。

## 地图与数值

有效范围 `(-192,-192)～(960,960)`，1152×1152，中央出生 `(384,384)`；
中央 384×384 金属广场，四角永久熔岩池，外侧四个作业区与宽环路。
北熔炉、东铁砧/工作台、南矿石/旧轨道、西冷却池/管道；各有两侧绕行出口。
新地图激活时关闭旧 TileMap 图层（不只是隐藏），退出时恢复原碰撞。
熔炉、矿石、工作台等仅实体下部碰撞；轨道和管道装饰不阻挡移动。
怪物、挑战精英和 Boss 召唤物的出生点避开实体/熔岩；老 Boss 在这张图召唤时也会验证入口位置。
Boss 出现时玩家不被传送；只有进入新地图时才放到中央安全出生点。

| 项目 | 首版设置/位置 |
|---|---|
| 压力阀 | 相对中央 `(-120,-95)`、`(120,-95)`、`(0,125)` |
| 阀激活 | 距离 30 内停留 0.6 秒，10 秒冷却，环形进度/冷色外观 |
| 随机裂缝 | 首次 8 秒，随后每 6 秒尝试一条；同时预警/喷发总数 ≤2 |
| 裂缝 | 1.2 秒预警、1.5 秒喷发，宽 32，0.5 秒伤害间隔 |
| 裂缝伤害 | 玩家 6/跳、小怪 12/跳；Boss 每跳 `min(最大血量×0.004,8)` |
| 煤渣虫 | 场景 HP 6、速度 48；各模式实际 HP 为此前5倍，普通首图/车轮战初始45；95距离开始预热，0.65～1.6秒后在玩家身前自爆，半径38、伤害22；死亡余烬半径15、伤害6 |
| 炉膛守卫 | 场景 HP 55、普通基础 HP 25、速度 26；近战 70、0.8 秒蓄力、0.35 秒挥锤、0.7 秒恢复、玩家伤害 14；正面直伤×0.6 |
| 运火工 | 场景 HP 22、普通基础 HP 约17.8、速度36；220距离内锁定目标，点火0.4秒后用0.65秒抛物线投掷炸药，落地倒计时1秒，爆炸半径58、玩家28/敌人45，冷却3.2秒；死亡位置另留一枚0.8秒炸药，最多3只运火工 |
| 刷怪 | 开场煤渣虫，30 秒加入运火工权重 3，60 秒加入守卫权重 2；煤渣虫权重 10，守卫最多 2 只，全局怪物上限仍为 30 |
| Boss 血量 | 原始场景 2400；普通首关按共享 Boss 规则为 2200（再走现有倍率）；车轮战第五场固定 1600；无尽走已有 Boss 曲线 |
| Boss 阶段 | >65% / 30%～65% / <30%；转换 0.65 秒；速度 38 / 暴走 52 |
| 重拳 | 普通蓄力 1 秒、暴走 0.85 秒，加落地动画前半段 0.15 秒；半径 54，连砸最后 70；落地 24、波浪 8，各只命中一次 |
| 连砸 | 二阶段 2 次、三阶段 3 次；每次重新预警/锁点，间隔 0.35 秒；普通拳恢复 0.8 秒，连砸结束恢复 1.15 秒 |
| 喷火 | 固定方向扇形，0.9 秒预警、1.5 秒喷火；射程 175、角度 1.1 弧度，玩家 8/0.5 秒，关闭窗口 0.8 秒 |
| 召唤 | 两批各 2 虫，二阶段起另加 1 工人，自己的存活召唤物最多 8；仍遵守全局怪物/运火工上限 |
| 熔渣 | 第 4/6 投射帧生成 3 枚，飞行 0.8 秒；分散预警，火区 3 秒、半径 32、玩家 6/0.5 秒；每 Boss 火区最多 6，自己不受伤 |
| 裂缝连喷 | 暴走才进入技能池；0.8 秒后依次尝试三条，间隔 1.4 秒，整个技能暂停随机裂缝；完成/中断/死亡恢复调度 |
| 过热 | 拳头覆盖可用阀时触发；3 秒停攻、玩家伤害×1.25且不叠加，随后 8 秒免疫；打断的攻击/召唤不恢复 |

最新战斗调整：煤渣虫各模式的实际生命值为此前5倍（普通/车轮战初始45），进入95距离后开始预热并提速至120，按触发距离蓄力0.65～1.6秒；预热圈填满时立即以38半径自爆并造成22伤害，不再等待接近玩家。熔炉暴君在150距离外必定优先使用熔火冲锋：0.45秒、宽48的直线预警，速度480、最多280距离；命中造成32伤害和击退，随后立即衔接原有砸地。

表内小怪“普通基础 HP”不包含时间、通关数、永久倍率；永久倍率函数未修改。
煤渣虫额外乘 0.75，是为了避免共享最低 12 HP 抹平其低血量定位。
玩家现有默认速度为 90，因此告警留出了离开 54～70 半径重拳和扇形近战的时间。
这些是起始调参，不是经过长时间真人平衡验证的最终数值。
只有重拳会调用阀的攻击激活接口；炸药和玩家武器不会。
地图与炸药伤害独立记录死因，不计到武器伤害中；持续伤害绕过守卫正面减伤。

## 代码文件变更清单

新增：

- `scenes/environment/forge_art.gd`：格子/动画规格与 PNG 纹理缓存。
- `scenes/environment/forge_effect.gd`：裂缝、警告、喷火、熔渣/火区、余烬、桶、蒸汽、无伤害死亡表现；爆炸复用旧 PNG，不实例化玩家炸弹技能。
- `scenes/environment/level_5_forge.gd`：布局、实体碰撞、安全出生点、阀/裂缝调度。
- `scenes/game_object/forge_enemy/forge_enemy.gd`，`cinder.tscn`、`guard.tscn`、`worker.tscn`：三种小怪复用铁傀儡场景的健康/移动/受击/掉落组件。
- `scenes/game_object/furnace_tyrant/furnace_tyrant.gd`、`furnace_tyrant.tscn`：六种技能、三阶段、过热和自身战场清理。
- `tools/generate_forge_placeholders.gd`：可重复生成全部占位 PNG。
- `tests/test_forge.gd/.tscn`：玩法、通行、碰撞、图格/透明/锚点、模式接入检查。
- `tests/test_forge_compile.gd/.tscn`：最小加载/第五图/Boss 生成检查。
- `tests/preview_forge.gd/.tscn`：实际渲染地图和战斗 PNG 截图。
- 本文、`art_prompts.md`、45 个 `placeholders/*.png`、2 个 `reference/*.png` 和 2 个预览 PNG。

修改：

- `scenes/main/main.gd`：五地图池、地图切换/碰撞开关、Boss 和测试入口、铸炉内传送门落点。
- `scenes/manager/enemy_manager.gd`：新图刷怪节奏、数量限制和出生点。
- `scenes/manager/challenge_manager.gd`：挑战怪出生位置、新 Boss 池、不再写死四地图。
- `scenes/manager/boss_rush_manager.gd`：第五场、五场计数/轮结束、新 Boss 固定血量与随机池。
- `scenes/ui/arena_time_ui.gd`：地图名称。
- `scenes/component/health_component.gd`、`hurtbox_component.gd`：可选命中位置/伤害类型，旧调用兼容；只有新怪/Boss 使用减伤钩子。
- `scenes/ability/bomb_ability/bomb_ability.gd`：标注范围伤害。
- `scenes/ability/bomb_burn/bomb_burn.gd`、`lightning_cloud_ability/lightning_cloud_ability.gd`、`sacred_tornado/sacred_tornado.gd`、`thunder_plasma/thunder_plasma.gd`：标注持续伤害，避免守卫错误减伤。
- `tests/test_boss_rush.gd`、`test_random_map_order.gd`：五地图/五场预期。
- `export_presets.cfg`：包含运行时读取的占位 PNG 原文件，避免导出时只有导入纹理而缺失原图。

## 已执行验证

使用本机 Godot 4.7.2 Mono，完整场景加载与测试脚本均实际执行：

- `test_forge_compile.tscn`：加载主场景、第五张地图和新 Boss 成功。
- `test_forge.tscn`：全部 `FORGE_*_OK`。覆盖 8 个可达出口、200 个合法出生点、真实物理碰撞、图格/透明/所有动作脚底锚点、阀蓄力/冷却、伤害间隔/两裂缝上限、守卫锁向/减伤、桶两路径去重/连锁、阶段/重拳命中阀/过热免疫/攻击中断、三连砸/熔渣生成帧/火区上限、死亡清理与五图模式接入。
- `test_boss_rush.tscn`：两整轮各五场胜利、第三轮三 Boss、后续 3 次选择、重复信号保护、30 怪补位、休整/升级/死亡及普通和无尽入口回归通过。
- `test_campaign_difficulty.tscn`、`test_campaign_portal.tscn`、`test_challenges.tscn`、`test_enemy_cap.tscn`、`test_blizzard.tscn`、`test_bomb_specials.tscn`、`test_hammer_specials.tscn`：无断言/解析错误并正常结束。
- `preview_forge.tscn`：使用实际 NVIDIA OpenGL Compatibility 渲染，生成 `map-preview.png`、`combat-preview.png` 并逐张检查。中央出生、角池边界、绕行出口、阀/拳预警和人物位置可见。

运行方式（项目目录中）：

```powershell
& 'C:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path . res://tests/test_forge.tscn --quit-after 400
& 'C:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path . res://tests/test_boss_rush.tscn --quit-after 1800
```

已知限制：完整主场景测试退出时仍报告 ObjectDB/资源/RID 未释放；原有模式测试也存在此类退出警告，不能据此声称零泄漏。没有执行 Web 打包、长时间真人平衡测试或正式美术验收。
主场景实际加载验证不是只跑 `--check-only`；资源导入/.NET 编辑器环境曾出现 SDK/Busy 问题，运行玩法不依赖新 PNG 的导入完成。
