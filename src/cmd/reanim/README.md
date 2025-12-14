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
  <input.json> <spritesheet-dir> <output-dir>
```

**示例**:

```bash
node target/js/release/build/cmd/reanim/reanim.js \
  .local/r2/Mob/1210100.img.json \
  .local/r2/spritesheets/Mob \
  assets/mob
```

## 输入/输出

**输入**:

- 怪物 JSON 文件（如 `.local/r2/Mob/1210100.img.json`）
- Spritesheet 目录（包含 `.json` 和 `.png` 文件）

**输出**:

- 转换后的 JSON（`__i` + `__off` 格式，路径相对于 `assets`）
- 每个动画的 spritesheet 图片

## 示例输出

```
assets/mob/
├── 1210100.img.json      # 转换后的 JSON
├── 1210100.img_die1.png
├── 1210100.img_hit1.png
├── 1210100.img_jump.png
├── 1210100.img_move.png
└── 1210100.img_stand.png
```

**JSON 中的 `__i` 格式**:

```json
{
  "__i": "mob/1210100.img_stand.png",
  "__off": [0, 0]
}
```
