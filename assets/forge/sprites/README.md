# 熔火铸炉人物精灵表

使用内置 imagegen 生成；以下是实际采用的提示词。PNG 原图未进行程序像素编辑。

## 文件与动作

- cinder-v2.png：煤渣虫，4×2 网格，行走、死亡。
- guard-v2.png：炉膛守卫，6×6 网格，待机、行走、蓄力、挥锤、恢复、死亡。待机三张有效姿势加一个保持帧，未把空格作为动画。
- worker-v2.png：运火工，6×4 网格，行走、点火、摇晃、死亡。
- tyrant-locomotion-v2.png：熔炉暴君，4×4 网格，待机6帧、行走8帧。
- tyrant-punch-v2.png：6×3 网格，蓄力6帧、重拳6帧、恢复4帧。
- tyrant-furnace-v2.png：6×4 网格，炉膛打开5帧、喷火6帧、关闭4帧、投掷6帧。
- tyrant-states-v2.png：6×4 网格，过热6帧、阶段转换6帧、死亡10帧。

## 接入与验证

动作到网格格子的映射位于 scenes/environment/forge_art.gd 的 SPRITE_SHEETS。生成的实际尺寸可能不同于提示词：实现读取实际尺寸，不硬编码生成尺寸。AtlasTexture 裁去透明留白，使用固定格子中心和90%高度脚底锚点；PNG 本身没有重画或修改。场景保留最近邻、左右翻转和原有受击闪光。显示尺寸为煤渣虫22、守卫42、工人30、Boss96像素的虚拟帧高度，实际身体高度低于这个值。

运行 tests/test_forge_sprites.tscn 检查7张图的透明背景、128帧边界和脚底锚点、所有人物动作的场景接入。tests/preview_forge.tscn 保存实际游戏渲染到 assets/forge/combat-preview.png。环境和技能攻击特效没有在本次重做。

## 最终生成提示词

## 本次改动文件与验证记录

- 新增上述7张 PNG 及本 README。
- 修改 scenes/environment/forge_art.gd：生成精灵表映射、实际尺寸切帧与缓存。
- 修改 scenes/game_object/forge_enemy/forge_enemy.gd：人物显示接入 AtlasTexture，保留原玩法组件与数值。
- 修改 scenes/environment/forge_effect.gd：死亡动画使用新人物帧。
- 修改 export_presets.cfg：打包时包含新 PNG 原文件。
- 修改 tests/test_forge.gd：检查实际使用的人物帧，不再检查旧人物占位图。
- 新增 tests/test_forge_sprites.gd、tests/test_forge_sprites.tscn：透明、切帧、脚底和场景动画检查。
- 修改 assets/forge/README.md：更新素材状态。
- 重新渲染 assets/forge/map-preview.png、assets/forge/combat-preview.png：实际游戏截图。

Godot 4.7.2 Mono 实际执行 test_forge_sprites、test_forge、test_boss_rush 均通过各自断言与成功标记，普通/无尽入口回归通过。OpenGL 游戏截图已经目视检查，新人物透明背景正常。git diff --check 通过。完整场景退出仍有 ObjectDB/资源/RID 释放警告，原模式回归也有同类警告；未执行 Web 导出或长时间真人动画验收。

### 提示词原文

### cinder-v2.png

```text
Use case: stylized-concept. Asset type: production pixel-game animated sprite atlas, NOT a concept illustration. Generate one CINDER BUG animation sprite sheet for a Godot top-down survivor game. Compact black coal beetle with 6 short jointed legs, ember-orange cracks, two small pale glowing eyes; dark crisp outlined pixel art with the detailed shading of retro iron golem game sprites. Orthographic three-quarter top-down facing lower right. EXACT layout: 4 equal columns by 2 equal rows, no text or grid lines. Canvas 1536 x 768, each cell 384 x 384. ROW 1: four successive distinct walking frames (alternating short legs, subtle compression, complete cyclic motion). ROW 2: four successive death frames: fractured coal, breaking apart, fading ember, fallen fragments. All 8 drawings entirely in their own cells, centered x in cell and SAME feet baseline at local y=330; all frames keep same body scale and design; minimum 20px margin. No ground, cast shadows, decorative scenery, dust clouds outside cells. Background must be genuinely alpha-transparent. DO NOT draw a checkerboard to represent transparency. If genuine transparency cannot be produced, use ONLY a uniform solid chroma-key magenta #FF00FF background everywhere outside sprites (not gray/white/checkerboard), and no magenta anywhere on the creature. No panels/borders/labels/numbers.
```

### guard-v2.png

```text
Create a PRODUCTION PIXEL SPRITE ATLAS, not concept art, for Furnace Guard in a top-down survivor game. Six equal COLUMNS and six equal ROWS, square canvas 2048x2048, each cell same size. Character: stout heavy dark iron armored dwarf automaton with thick obvious front breastplate, blazing orange chest furnace, one massive black-steel forging hammer with brown handle. Detailed crisp retro pixel art black outlines and limited rusty brown/iron gray/orange palette, three-quarter view facing down-right. Same character in EVERY frame. ROW1: idle breathing, FOUR frames then TWO EMPTY cells. ROW2: walking cycle SIX distinct consecutive frames, alternate heavy boots. ROW3: locked-direction hammer charge FOUR frames then TWO EMPTY cells, lift hammer overhead. ROW4: hammer strike SIX frames, hammer comes down; FOURTH frame has hammer on ground, then pull back. ROW5: recovery THREE frames then THREE EMPTY cells, stand straight after stroke. ROW6: death SIX frames, furnace dims, knees buckle and falls into broken armor. All characters centered in respective cells, body scale constant, feet baseline at local 85% cell height; raised hammer fully within cell, at least 7% cell margins. True alpha transparent background, absolutely NO drawn checkerboard; if transparency cannot be produced use uniform #FF00FF chroma-key magenta and no magenta in character. No shadows, ground, panels, labels, numerals, borders, unrelated sparks or hit circles.
```

### worker-v2.png

```text
Generate a production sprite atlas for FIRE CARRIER enemy, a squat mechanical dwarf courier wearing brown leather apron and brass helmet, gray goggles glowing pale amber, carrying a large distinct wood-and-iron strapped explosive barrel on back with bright orange short fuse. Detailed hard-edged retro pixel art with black outlines, three-quarter top-down facing down-right, same character proportion/equipment throughout. Grid EXACTLY SIX equal columns by FOUR equal rows, canvas 2048x1366. ROW1: SIX frames consecutive walking cycle, barrel sways slightly and boots alternate. ROW2: FOUR sequential ignition frames, halt, reach for fuse, light fuse, withdraw; last TWO cells EMPTY. ROW3: FOUR fear/shaking-before-explosion loop frames, body trembling and lit fuse flickering; last TWO cells EMPTY. ROW4: FOUR death frames, collapse and lose grip on barrel, barrel visibly falls and courier lies fallen; last TWO cells EMPTY. Fixed body scale all cells, feet aligned to same local baseline 85% cell height, centered x; at least 6% clear margins, everything entirely inside its cell. Genuinely alpha-transparent background. No checkerboard drawing. If actual transparency impossible, only uniform solid #FF00FF background and no magenta on sprite. No text, labels, panel boundaries, ground shadows, explosion, scenery.
```

### tyrant-locomotion-v2.png

```text
Use case: stylized-concept. Asset type: actual production transparent pixel sprite animation atlas for Godot, NOT concept art. Subject: Furnace Tyrant, huge dwarf-built furnace golem, rounded broad rusty orange shoulder shells riveted over black-steel joint armor, a small round black helmet with a glowing slit, two round massive black steel fists, short heavy iron boots, a hinged rectangular furnace chest with three glowing orange vertical grille slots, paired upright soot-black exhaust pipes behind shoulders. No weapon. Rich crisp retro pixel art, dark black outlines, three-quarter top-down facing down-right. Every frame has same armor, furnace, pipes and fists and body proportions. Real alpha transparent background. ABSOLUTELY DO NOT DRAW A CHECKERBOARD. If genuine alpha cannot be produced use only uniformly solid #FF00FF. NO attached smoke/plumes above pipes, ground, glow halos, scenery, text, labels, borders, or grid lines. All sprites fully inside respective cells with 8% padding and same boots baseline 85% cell height. FOUR equal columns x FOUR equal rows, square 2048x2048. ROW1: idle breathing poses1..4. ROW2: idle poses5..6 first TWO cells only, last TWO cells EMPTY. ROW3: walking poses1..4, heavy alternating boots and weight shift. ROW4: walking poses5..8, completes gait. No attached smoke. All pipes and fists cleanly within cells.
```

### tyrant-punch-v2.png

```text
Use case: stylized-concept. Asset type: actual production transparent pixel sprite animation atlas for Godot, NOT concept art. Subject: Furnace Tyrant, huge dwarf-built furnace golem, rounded broad rusty orange shoulder shells riveted over black-steel joint armor, a small round black helmet with a glowing slit, two round massive black steel fists, short heavy iron boots, a hinged rectangular furnace chest with three glowing orange vertical grille slots, paired upright soot-black exhaust pipes behind shoulders. No weapon. Rich crisp retro pixel art, dark black outlines, three-quarter top-down facing down-right. Every frame has same armor, furnace, pipes and fists and body proportions. Real alpha transparent background. ABSOLUTELY DO NOT DRAW A CHECKERBOARD. If genuine alpha cannot be produced use only uniformly solid #FF00FF. NO attached smoke/plumes above pipes, ground, glow halos, scenery, text, labels, borders, or grid lines. All sprites fully inside respective cells with 8% padding and same boots baseline 85% cell height. SIX equal columns x THREE equal rows, 2048x1024 canvas. ROW1: SIX charging poses, right fist slowly raised from lowered position to above shoulder. ROW2: SIX slam poses, fist descends, FOURTH pose contacts floor with compressed body, fifth/sixth retract. ROW3: FOUR recovery poses, stand back into idle, last TWO cells EMPTY.
```

### tyrant-furnace-v2.png

```text
Use case: stylized-concept. Asset type: actual production transparent pixel sprite animation atlas for Godot, NOT concept art. Subject: Furnace Tyrant, huge dwarf-built furnace golem, rounded broad rusty orange shoulder shells riveted over black-steel joint armor, a small round black helmet with a glowing slit, two round massive black steel fists, short heavy iron boots, a hinged rectangular furnace chest with three glowing orange vertical grille slots, paired upright soot-black exhaust pipes behind shoulders. No weapon. Rich crisp retro pixel art, dark black outlines, three-quarter top-down facing down-right. Every frame has same armor, furnace, pipes and fists and body proportions. Real alpha transparent background. ABSOLUTELY DO NOT DRAW A CHECKERBOARD. If genuine alpha cannot be produced use only uniformly solid #FF00FF. NO attached smoke/plumes above pipes, ground, glow halos, scenery, text, labels, borders, or grid lines. All sprites fully inside respective cells with 8% padding and same boots baseline 85% cell height. SIX equal columns x FOUR equal rows, 2048x1366 canvas. ROW1: FIVE furnace door opening poses, grille panels swing apart exposing orange core, last cell EMPTY. ROW2: SIX fixed-direction flame-posture poses, door open and leaning forward, NO actual flame outside body. ROW3: FOUR furnace door closing poses, last TWO cells EMPTY. ROW4: SIX slag-throw poses, fist cocks back then swings forward and opens; FIFTH pose is release with hand outstretched, no actual projectile.
```

### tyrant-states-v2.png

```text
Use case: stylized-concept. Asset type: actual production transparent pixel sprite animation atlas for Godot, NOT concept art. Subject: Furnace Tyrant, huge dwarf-built furnace golem, rounded broad rusty orange shoulder shells riveted over black-steel joint armor, a small round black helmet with a glowing slit, two round massive black steel fists, short heavy iron boots, a hinged rectangular furnace chest with three glowing orange vertical grille slots, paired upright soot-black exhaust pipes behind shoulders. No weapon. Rich crisp retro pixel art, dark black outlines, three-quarter top-down facing down-right. Every frame has same armor, furnace, pipes and fists and body proportions. Real alpha transparent background. ABSOLUTELY DO NOT DRAW A CHECKERBOARD. If genuine alpha cannot be produced use only uniformly solid #FF00FF. NO attached smoke/plumes above pipes, ground, glow halos, scenery, text, labels, borders, or grid lines. All sprites fully inside respective cells with 8% padding and same boots baseline 85% cell height. SIX equal columns x FOUR equal rows, 2048x1366 canvas. ROW1: SIX overheat trembling poses, door open and bright core, limp fists, NO attached steam. ROW2: SIX phase transition poses, armor seam cracks briefly flare orange then settle. ROW3: SIX death poses1..6, furnace flickers, golem staggers, knees buckle, kneels and falls. ROW4: first FOUR cells death poses7..10, lying collapsed, furnace progressively darkens to completely cold black, last TWO cells EMPTY.
```
