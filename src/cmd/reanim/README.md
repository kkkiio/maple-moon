# Reanim CLI Tool

处理游戏动画资源，统一 origin 并生成 spritesheet。

## 功能

1. **动画检测** - 自动识别动画节点（检查 `"0"` key）
2. **统一 Origin** - 基于锚点对齐计算统一尺寸
3. **生成 Spritesheet** - 为每个动画生成水平排列的 spritesheet
4. **转换引用** - `"__i": "path#id"` → `"__i": "rel/path.png"` + `"__off": [x, y]`
5. **相对路径** - `__i` 路径相对于 `assets` 目录，与游戏资源加载器兼容

## 依赖

```bash
npm install sharp
```

## 使用

```bash
moon build --target js
node target/js/release/build/cmd/reanim/reanim.js \
  <input.json> <output-dir> [options]
```

### 选项

- `--match, -m <pattern>`: 按路径过滤（例如 `BasicEff.img/Teleport`）
- `--bitmaps-dir, -b <path>`: 指定 bitmaps 目录（默认：`<input-dir>/bitmaps`）
- `--spritesheet-dir, -s <path>`: 指定 spritesheets 目录（仅用于 Spritesheet 模式）
- `--help, -h`: 显示帮助信息

### 模式自动检测

工具会自动根据输入 JSON 的内容检测模式：

1. **Spritesheet 模式**: 当检测到 `__i` 引用时（引用 spritesheet 中的图片）。
2. **Bitmap 模式**: 当检测到 `__b` 引用时（引用 `bitmaps/` 目录下的图片）。

> **注意**: `__i` 和 `__b` 是互斥的格式。一个 JSON 资源文件只会使用其中一种格式，不会同时出现两种格式。

### 自动结构识别（设计中）

为了去掉 `--layer` 参数并支持更多种类的动画结构，工具采用如下策略自动识别节点类型：

1. **Simple Animation (简单动画)**

   - 特征：节点包含连续的数字 key (`"0"`, `"1"`...)，且 `node["0"]` 本身就是一个帧资源（包含 `__i` 或 `__b`）。
   - 处理：将整个节点视为一个动画序列。
   - 示例：`Mob/1210100.img.json` 中的 `stand`。

2. **Multi-Part Animation (多部位/层级动画)**

   - 特征：节点包含连续的数字 key，但 `node["0"]` **不是**帧资源，而是一个包含多个子节点的容器对象。
   - 处理：遍历 `node["0"]` 的所有子键，检查它们是否为帧资源。对于每个确认是帧资源的子键（例如 `body`, `arm`, `weapon`），提取该层级的所有帧（`node["0"][layer]`, `node["1"][layer]`...）组成一个独立的动画序列。
   - 输出命名：`{base_name}_{action}_{layer}.png` (例如 `00002000_alert_body.png`, `01302000_swingO1_weapon.png`)。
   - 示例：`Character/Body/00002000.img.json` (包含 body, arm 等即多部位)，`Character/Weapon/01302000.img.json` (包含 weapon 即单层级)。

3. **Single Frame (单帧资源)**
   - 特征：节点本身不包含数字序列，但它本身就是一个帧资源。
   - 处理：作为单张图片处理。
   - 示例：`info/icon`。

这种策略能够同时兼容普通怪物动画、角色武器（嵌套在 `weapon` 层）、角色身体（多层嵌套）等多种情况，无需人工指定 `--layer`。

### 示例 1: Spritesheet 模式 (普通 Mob)

处理 `1210100.img.json`，使用 `__i` 引用。

```bash
node target/js/release/build/cmd/reanim/reanim.js \
  .local/r2/Mob/1210100.img.json \
  assets/mob \
  --spritesheet-dir .local/r2/spritesheets/Mob
```

### 示例 2: Spritesheet 模式 (多部位/Weapon 资源)

处理 `01302000.img.json`，工具会自动识别 `weapon` 层。

```bash
node target/js/release/build/cmd/reanim/reanim.js \
  .local/r2/Character/Weapon/01302000.img.json \
  assets/character/weapon \
  --spritesheet-dir .local/r2/Character/Weapon/spritesheets
```

这将自动处理：

- 嵌套在 `weapon` 对象下的动画帧 -> 生成 `..._swingO1_weapon.png`
- `info` 节点下的单帧图标 (`icon`, `iconRaw`) -> 生成 `..._info_icon.png`

### 示例 3: Bitmap 模式

处理 `nx.json` 中的 "Teleport" 动画，使用 `__b` 引用。

```bash
node target/js/release/build/cmd/reanim/reanim.js \
  .local/nx/Effect.nx/nx.json \
  assets/Effect \
  --match "BasicEff.img/Teleport"
```

这会自动：

1. 从 `BasicEff.img/Teleport` 路径提取动画数据
2. 从 `.local/nx/Effect.nx/bitmaps/` 加载对应 ID 的图片
3. 生成 `assets/Effect/BasicEff.img/Teleport.png` 和对应的 JSON

## 输入/输出

**输入**:

- 动画 JSON 文件
- 资源目录（spritesheets 或 bitmaps）

**输出**:

- 转换后的 JSON（`__i` + `__off` 格式，路径相对于 `assets`）
- 每个动画的 spritesheet 图片

## 示例输出 (Bitmap 模式)

```
assets/Effect/
└── BasicEff.img/
    ├── Teleport.json       # 转换后的 JSON
    └── Teleport.png        # 生成的 spritesheet
```
