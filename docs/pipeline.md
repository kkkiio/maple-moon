# 资源管线 (Asset Pipeline)

本文档描述 Maple Moon 中所有游戏资源的来源、处理流程、导出格式和运行时加载方式。

## 总览

```
源格式                 导出/转换                运行时格式              加载 API
────────────────────────────────────────────────────────────────────────────
Aseprite .aseprite  →  Aseprite 导出  →  .json + .png spritesheet  →  require_json / require_image
Tiled .tmx          →  Tiled 导出     →  .tmj + .tsj              →  require_json
NX 容器              →  提取工具       →  .img.json                →  require_json + json_navigate
```

## 一、精灵与动画 — Aseprite

### 源格式

- **工具**：Aseprite（精灵/像素动画编辑器）
- **源文件**：`.aseprite`，存放在对应资源的 `animations/` 子目录下，例如：
  ```
  assets/Skill/231.img/animations/skill__2311001.aseprite
  assets/UI/Basic.img/Cursor/cursor.aseprite
  ```

### 导出格式

从 Aseprite 导出两个文件：
1. **Spritesheet PNG**：所有帧拼接成一张大图
2. **JSON 描述文件**：记录每帧在 spritesheet 中的矩形位置、时长、锚点

这两个文件通常放在同一个目录下，JSON 中通过相对路径引用 PNG。

### 导出步骤

在 Aseprite 中打开 `.aseprite` 文件后：
1. File → Export Sprite Sheet
2. Output 标签：选择输出目录，勾选 "JSON Data"
3. Layout 标签：选择合适的排列方式（通常 `Horizontal strip` 或 `Packed`）
4. 导出，得到 `.json` 和 `.png` 两个文件

> 项目目前用 `$resource-processing-workflow` skill 自动化此流程。缺少资源时优先使用该 skill。

### 运行时加载

```mbt
// 加载动画 JSON，内部会解析 spritesheet 引用并自行加载 PNG
AnimationLoader::load("assets/Skill/231.img/animations/skill__2311001.json")
```

根据 ADR 0001，`AnimationLoader` 内部直接调用 `require_json` 和 `require_image`，不再经过统一的 loader 抽象层。

---

## 二、地图 — Tiled

### 源格式

- **工具**：Tiled（瓦片地图编辑器）
- **源文件**：`.tmx`（Tiled 原生 XML 格式）
- **瓦片集**：`.tsx`（Tiled Tileset 定义）

### 导出格式

导出为 Tiled JSON 格式：
- `.tmj`：Tiled Map JSON（地图的层、对象、属性）
- `.tsj`：Tiled Tileset JSON（瓦片集定义）

### 导出步骤

在 Tiled 中：
1. Map → Map Properties → 确保使用正确的 tileset 引用
2. File → Export As → 选择 JSON 格式（`.tmj` / `.tsj`）

### 运行时加载

```mbt
// 直接按文件路径加载
require_json("assets/Map/tiles/100000000.img.tmj")
```

地图可能进一步引用 tileset `.tsj` 文件和图片资源，由游戏代码自行解析和加载。

---

## 三、原版数据 — NX 容器

### 源格式

- **来源**：原始 MapleStory 客户端数据文件（NX 格式）
- **提取后格式**：`.img.json` — 将 NX 容器节点树序列化为 JSON

### 目录组织

```
assets/
  Npc/          ← .img.json 文件 + 对应的帧图片
  Skill/        ← .img.json 文件 + 对应动画的 .aseprite 源文件和导出
  Item/         ← .img.json 文件（消耗品、装备等）
  Quest/        ← .img.json 文件
  Mob/          ← .img.json 文件
  String/       ← .img.json 文件（文本表）
  Effect/       ← .img.json 文件
  UI/           ← .img.json 文件 + UI sprite
```

每个 `.img.json` 是一个独立的 JSON 文件，内部是树形结构，用路径导航到具体节点。

### 资源结构示例

```
assets/Skill/231.img.json           ← 技能 231 的数据容器
assets/Skill/231.img/               ← 该技能关联的资源目录
  animations/
    skill__2311001.aseprite          ← 源文件
    skill__2311001.json              ← Aseprite 导出 JSON
    skill__2311001.png               ← Aseprite 导出 spritesheet
```

### 运行时加载

```mbt
// 加载容器文件，然后导航到具体节点
let container = require_json("assets/Skill/231.img.json")
let skill_data = json_navigate(container, ["2311001", "level", "1"])
```

根据 ADR 0001，`json_navigate` 用于在 `.img.json` 容器内部沿路径导航到具体数据节点。

### 独立导出的 JSON

部分数据已从 NX 容器中导出为独立 JSON 文件，直接按文件路径加载：

```mbt
require_json("assets/Item/Consume/2000000.json")  // 红药水
```

---

## 四、其他资源类型

### 图片

- **独立图片**：`.png`，通过 `require_image` 加载
- 存放于 `assets/images/`（默认被 `.gitignore`，按需 `git add --force`）
- 也存放于 `assets/spritesheets/` 各子目录下

### 音效 / 背景音乐

- `.mp3` / `.ogg` 文件，存放于 `assets/sound/`
- 该目录默认被 `.gitignore` 忽略

### UI 资源

- UI sprite 在 `assets/UI/` 下，`.img.json` 描述 UI 布局，`.aseprite` / `.png` 提供视觉素材
- UI spritesheet 在 `assets/spritesheets/UI/` 下

---

## 五、assets/ 目录结构速查

```
assets/
  Character/              ← 角色外观（身体、发型、脸、装备等）
    Afterimage/           ← 残影特效
    Body/ Coat/ Face/ Hair/ Longcoat/ Pants/ Shield/ Shoes/ weapon/
  data/                   ← 游戏数据表
  Effect/                 ← 特效数据
  Etc/                    ← 杂项
  images/                 ← 独立图片（.gitignore 默认忽略）
    Item/ Map/ Npc/ Skill/ UI/
  Item/                   ← 道具数据（Cash/ Consume/ Etc/ Install/ Pet/ Special）
  Map/                    ← 地图数据
    Map/ WorldMap/
  map001/                 ← 地图 001 资源
    back/
  minimap/                ← 小地图图片（.gitignore）
  mob/                    ← 怪物数据
  Npc/                    ← NPC 数据（.img.json，.gitignore）
  portal/                 ← 传送门图片
  Quest/                  ← 任务数据（.gitignore）
  Skill/                  ← 技能数据
  sound/                  ← 音频文件（.gitignore）
  spritesheets/           ← 导出的 spritesheet（部分 .gitignore）
    Item/ Map/ Mob/ UI/
  String/                 ← 文本字符串数据
  UI/                     ← UI 布局和素材
```

---

## 六、版本控制策略

详见 `docs/adr/0004-iterative-runtime-resource-commits.md`。

**核心原则**：大资源目录默认 `.gitignore`，只按需提交运行和测试所需的最小闭包。

### 被忽略的目录

```
assets/images           assets/spritesheets/Map  assets/spritesheets/UI
assets/Map              assets/map               assets/map001
assets/minimap          assets/sound             assets/Quest
assets/Npc
```

### 提交资源的步骤

当测试或运行时路径需要某个被忽略目录下的资源时：

```bash
# 1. 确认需要哪些文件（JSON 引用的图片、spritesheet、tileset 等）
# 2. 用 --force 显式添加最小闭包
git add --force assets/Npc/2041000.img.json
git add --force assets/Npc/2041000.img/
git add --force assets/spritesheets/Npc/2041000.img/

# 3. 确保所有引用的资源都存在（不做半成品提交）
# 4. 提交
```

**提交检查清单**：
- [ ] 主 JSON 数据已包含
- [ ] JSON 引用的图片/PNG 都已包含
- [ ] 对应的 `.aseprite` 源文件已包含（如适用）
- [ ] 不存在"图片缺失"的半成品状态
- [ ] 快照测试通过
