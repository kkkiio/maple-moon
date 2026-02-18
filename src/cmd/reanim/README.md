# Reanim CLI Tool

Maplestory 资源处理工具。主要用于将原始解包资源（JSON 结构 + 散图/图集引用）转换为游戏运行时更易加载的格式（单张 Unified Spritesheet + 带有坐标偏移的 JSON）。

## 工具目的

原始游戏资源通常存在以下问题，不适合直接在 Web/Runtime 中加载：

1. **文件琐碎**：一个资源文件可能引用几十甚至上百张散图，或者引用多个外部的 Spritesheet。
2. **结构复杂**：存在多层嵌套（如 Character 的 `hairShade` 包含 12 种肤色变体），或者引用关系复杂。
3. **加载低效**：客户端频繁发起 HTTP 请求加载小图会导致性能问题。

**Reanim** 的核心作用是对资源进行 "重组" (Re-animate)：

- **递归搜集 (Recursive Collection)**：自动遍历 JSON 树中的所有节点，搜集所有帧资源（`__i` 或 `__b`），无论它们嵌套在多深的层级下（自动处理 `hairShade`, `weapon`, 多部位动画等）。
- **智能去重 (Deduplication)**：根据源路径或 ID 自动识别重复引用的帧。例如，不同动作可能复用相同的站立帧，或者不同肤色变体引用同一张遮罩图，工具只会打包一份图片数据，显著减小 Spritesheet 体积。
- **合并输出 (Unified Output)**：默认为一个输入的 JSON 资源生成**单张** Spritesheet (`.png`)，并输出更新了引用路径和坐标偏移 (`__off`) 的 JSON 文件。
- **保留源图集 (Keep Source Sheets)**：可选保留原始多个 spritesheet，不重新合图，仅将 `__i: sheet#id` 重写为 `__i: sheet.png` 并写入 `__off: [x, y]`。

## 现状与特性

### 1. 默认模式：Recursive Simple Pack

这是目前推荐的处理方式：

- **保留原尺寸**：不对图片进行 Resize，完整保留原始图片的 `width`, `height` 和 `origin` 锚点信息。
- **水平排列**：所有去重后的唯一帧在生成的 Spritesheet 中水平排列。
- **路径重写**：输出的 JSON 中，原有的引用（如 `path/to/sheet.img#123`）会被重写为指向新生成的 Spritesheet (`base_name.png`)，并附加 `__off` 字段指明该帧在 Spritesheet 中的 X 轴偏移量。

### 2. 遗留模式：Resize Mode (`--resize`)

这是旧版本的逻辑，尝试计算所有帧的统一包围盒，并将帧 Resize 到统一尺寸。

- 通过 `--resize` 或 `-r` 参数开启。
- 主要用于某些需要统一帧尺寸的旧测试用例或特定组件。

### 3. 支持两种源格式

工具会自动根据输入 JSON 的内容检测模式：

- **Spritesheet 模式 (`__i`)**：引用 WZ 导出的 atlas 结构（通常引用 `spritesheets/` 目录下的图集 + 子 ID）。
- **Bitmap 模式 (`__b`)**：引用 raw bitmap ID（引用 `bitmaps/` 目录下的散图 ID）。

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
- `--spritesheet-dir, -s <path>`: 指定 spritesheets 目录（仅用于 `__i` 模式）
- `--resize, -r`: 开启遗留的 Resize 模式（统一帧尺寸）
- `--keep-source-sheets, -k`: 保留源 spritesheet，不合并输出单图，仅写 `__off`
- `--help, -h`: 显示帮助信息

## 示例

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

- 嵌套在 `weapon` 对象下的动画帧 -> 全部打包进 `01302000.img.png`
- 自动去重相同引用的帧

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
