# 铸炉放大、出生、伤害与火焰更新

## 伤害（未计时间等外部倍率）

| 项目 | 原值 | 新值 |
|---|---:|---:|
| 煤渣虫/守卫/工人/Boss接触 | 10 | 18/24/20/30 |
| 守卫挥锤 | 14 | 24 |
| 工人炸药桶 | 16 | 28 |
| 煤渣虫余烬 | 3 | 6 |
| Boss重拳 | 24 | 40 |
| Boss冲击波 | 8 | 14 |
| Boss喷火（每0.5秒） | 8 | 14 |
| Boss熔渣火区（每0.5秒） | 6 | 12 |
| Boss裂缝连喷（每0.5秒） | 6 | 12 |

地图自然裂缝伤害仍为6；武器与永久技能倍率不变。接触伤害仍乘原有 (1+arena_difficulty×0.05)。多个怪重叠时取接触基础伤害最大者，而不是叠加所有怪。

守卫显示帧高度42→70，脚底位置与死亡动画匹配，原有移动碰撞8.4半径和受击碰撞不放大。其他人物显示尺寸不变。

## 出生

所有Boss共用 EnemyManager.get_boss_spawn_position，不再复用可能返回世界原点的小怪屏外出生函数。铸炉使用72像素障碍/边界留白。共享TileMap逐点检查地面、40像素实体空间与视线；找不到远处位置时回退玩家当前位置。离开较大的铸炉回共享地图时玩家回到(384,384)，防止沿用铸炉边缘位置导致玩家/Boss落在共享地图外。

## 火焰素材

内置 imagegen 生成，最终文件 assets/forge/sprites/fire-effects-v2.png，1536×1024、6列4行，真正透明。第一行地面燃烧，第二行向右喷火，第三行裂缝喷发，第四行余烬，每种6帧。没有程序重画PNG像素。Godot AtlasTexture读取格子，喷火随攻击方向旋转，裂缝按长度铺设错帧火柱，地面危险边界/预警仍保留。自然裂缝、Boss技能和煤渣虫均接入同一套素材，其他武器火焰不修改。

## 本次文件清单

修改：

- scenes/game_object/forge_enemy/forge_enemy.gd
- scenes/game_object/furnace_tyrant/furnace_tyrant.gd
- scenes/game_object/player/player.gd
- scenes/manager/enemy_manager.gd
- scenes/main/main.gd
- scenes/environment/forge_art.gd
- scenes/environment/forge_effect.gd
- tests/test_forge.gd
- tests/preview_forge.gd
- assets/forge/README.md
- 重新渲染 assets/forge/map-preview.png、assets/forge/combat-preview.png

新增：

- assets/forge/sprites/fire-effects-v2.png
- assets/forge/fire-preview.png
- assets/forge/fire-update.md（本文）
- tests/test_forge_tuning.gd
- tests/test_forge_tuning.tscn

## 验证

Godot 4.7.2 Mono：test_forge_tuning覆盖24火焰帧透明/非空/缓存、守卫大小与碰撞、玩家接触伤害路径、强化技能、地图转换、五地图共25次真实Boss生成。test_forge玩法回归、test_boss_rush普通/无尽/多Boss回归通过成功标记与断言。preview_forge使用NVIDIA OpenGL实际渲染四种新火焰并目视检查。仍存在完整场景退出资源/ObjectDB/RID警告，未执行Web导出或长期真人平衡测试。

## 最终提示词（内置 imagegen）

```text
Use case: stylized-concept. Asset type: production 2D pixel-art fire animation atlas for a dark industrial forge survivor game. Generate a genuinely transparent RGBA PNG, landscape 1536x1024, exactly 6 columns and 4 rows equal 256x256 cells, 24 independent frames. Background fully transparent alpha zero, NOT a painted checkerboard, no backdrop, no panels or grid lines. Crisp pixel clusters, polished warm orange tongues with yellow-white cores, deep red outer curls, small ember sparks, dark smoke only sparse near tips, readable against grey metal floor. Row 1 six sequential loop frames of a ground fire pool, oblique top-down oval base with multiple flickering tongues, anchored center at x128,y184 in each cell. Row 2 six sequential loop frames of directional flamethrower blast pointing RIGHT, jet begins at x24,y128 and expands to x220,y128, layered flowing turbulent flames, whole silhouette inside padding. Row 3 six sequential frames of a vertical molten fissure eruption, thick luminous column rises from an oval base centered at x128,y210, fiery splashes and sparks contained fully inside cell. Row 4 six sequential loop frames of a small dying ember fire, glowing scattered coal with short flame tongues at x128,y184. Each sprite fully contained within its own cell with at least 20px transparent margins. Same size and pivot within each row, actual alternating evolving flame shapes for smooth six-frame looping, not identical copies. Strictly NO characters, ground tiles, barrels, letters, labels, numerals, watermark, black or white background, checkerboard backdrop, rectangular glow patches. Only the 24 isolated fire-effect sprites on actual transparency.
```

