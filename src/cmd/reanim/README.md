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

- `--match <pattern>`: 按路径过滤（例如 `BasicEff.img/Teleport`）
- `--bitmaps-dir <path>`: 指定 bitmaps 目录（默认：`<input-dir>/bitmaps`）
- `--spritesheet-dir <path>`: 指定 spritesheets 目录（仅用于 Spritesheet 模式）
- `--layer <name>`: 指定嵌套层级名称（用于处理 Weapon 等嵌套资源，例如 `weapon`）

### 模式自动检测

工具会自动根据输入 JSON 的内容检测模式：

1. **Spritesheet 模式**: 当检测到 `__i` 引用时（引用 spritesheet 中的图片）。
2. **Bitmap 模式**: 当检测到 `__b` 引用时（引用 `bitmaps/` 目录下的图片）。

### 单帧资源支持

工具现已支持处理非动画序列的单帧资源（如 `info.icon`），它们会被自动识别并转换为独立的图片文件（例如 `..._info_icon.png`）。

### 示例 1: Spritesheet 模式 (普通 Mob)

处理 `1210100.img.json`，使用 `__i` 引用。

```bash
node target/js/release/build/cmd/reanim/reanim.js \
  .local/r2/Mob/1210100.img.json \
  assets/mob \
  --spritesheet-dir .local/r2/spritesheets/Mob
```

### 示例 2: Spritesheet 模式 (Weapon 资源)

处理 `01302000.img.json`，指定 `--layer weapon` 以解析嵌套的帧数据。

```bash
node target/js/release/build/cmd/reanim/reanim.js \
  .local/r2/Character/Weapon/01302000.img.json \
  assets/character/weapon \
  --spritesheet-dir .local/r2/Character/Weapon/spritesheets \
  --layer weapon
```

这将自动处理：

- 嵌套在 `weapon` 对象下的动画帧
- `info` 节点下的单帧图标 (`icon`, `iconRaw`)

### 示例 2: Bitmap 模式

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
