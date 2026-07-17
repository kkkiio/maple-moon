# 资源管线（Asset Pipeline）

本文档描述资源从源格式到运行产物的转换流程。运行时寻址与 pack 挂载见
`docs/engineering/0001-organize-assets-as-resource-packs.md`。

## 一、资源格式

### 输入 → 输出对照

| 源格式 | 来源 | 输出格式 | 运行时地址示例 |
|---|---|---|---|
| `.nx`（NX 归档） | `../nx_maple_res/assets/` | `.mx.json` / `.json` / `.png` / `.tmj` / `.tsj` | `res://Mob/0100100.img/mx.json` |
| `.aseprite` | `source_assets/<pack>/` | `.json` + `.png`（spritesheet） | `res://Mob/0100100.img/animation.json` |
| `.tmj` / `.tsj`（Tiled） | 直接放入 `assets/<pack>/` | 自身即为运行格式 | `res://Map/tiles/100000000.img.tmj` |
| 自有数据（TSV / JSON） | 手写 | 自身即为运行格式 | `res://Data/...` / `res://Quest/...` |

### 各格式说明

**NX** — 一种遗留资源归档格式。通过 `nx_maple_res` 工具按 NX node 层级导出为
结构化 JSON、Tiled TMJ/TSJ、图片和音频。顶层 domain（`Map`、`Mob`、`Npc` 等）
沿用 NX 文件 stem 的大小写。

**Aseprite** — 像素动画编辑源文件（`.aseprite`）。导出为一份描述帧的 JSON 和一张
spritesheet PNG，放在同目录。JSON 内部使用相对路径引用 PNG。

**Tiled** — 地图编辑格式。TMJ/TSJ 既作编辑格式也作运行格式，直接放在 `assets/`。
TMJ 内部以相对路径引用 TSJ，TSJ 再引用图片。

**自有数据** — TSV 或 JSON，不经过导出工具，直接手写放入 `assets/`。当前主要有
`Data/`、`Quest/` 和 `String/`。

## 二、Resource Pack 组织

### 概念

一个 resource pack（简称 pack）是一组运行资源的自包含目录。`assets/` 的第一层子
目录就是 pack：

```text
assets/
├── base/               ← 必选公共包（角色、UI、技能、通用系统）
├── dlc-victoria/       ← 内置的 Victoria Island 内容包
├── skin-summer/        ← 夏日皮肤
├── skin-halloween/     ← 万圣节皮肤
├── dlc-elnath/         ← 艾纳斯大陆扩展（Map、Mob、Npc、Sound）
└── ...                  ← 更多大陆或皮肤扩展
```

每个 pack 根目录包含 `pack.json`，列出该 pack 提供的全部文件。pack 内部使用统一
的 domain 目录布局（`Character/`、`Map/`、`Mob/` 等），不写 pack 名称。

### Pack 类型

| 类型 | 前缀 | 内容 | 示例 |
|---|---|---|---|
| 必选公共 | `base` | 角色、UI、技能等跨大陆通用资源 | `base` |
| 大陆扩展 | `dlc-` | 地图、怪物、NPC、区域音效 | `dlc-elnath` |
| 皮肤 | `skin-` | 纯外观覆盖，不涉及玩法数据 | `skin-summer` |

皮肤 pack 只覆盖外观资源（角色外观、UI 皮肤等），不改变游戏逻辑。不挂载
`skin-*` pack 时使用 base/DLC 提供的默认外观。`dlc-*` 和 `skin-*` 是内容约定，
当前 resolver 不根据前缀自动扫描、挂载或验证内容类型。

### 当前 Pack 列表

| Pack | 类型 | 内容 |
|---|---|---|
| `base` | 必选公共 | Character、Data、Effect、Etc、Item、Skill、Sound、String、UI 等 |
| `dlc-victoria` | 大陆扩展 | 维多利亚岛 Map、Mob、Npc、Sound |

标准挂载顺序从低到高为：`base` → 已启用的 `dlc-*` → 已启用的
`skin-*`/补丁。后挂载 pack 遇到同名 ResourceKey 时，必须在自己的
`overrides` 中精确列出该 `res://` 地址；未声明的冲突直接拒绝挂载。

每个 pack 必须包含其文件的相对引用闭包。例如 skin 覆盖一份 animation
JSON 时，它引用的 spritesheet 也必须位于同一 skin pack；相对引用不会
回退到 base 的物理目录。

### 编辑源文件

`.aseprite` 等编辑源文件不进入 `assets/`，放在镜像的 `source_assets/<pack>/`：

```text
assets/dlc-victoria/Mob/0100100.img/animation.json
assets/dlc-victoria/Mob/0100100.img/animation.png
source_assets/dlc-victoria/Mob/0100100.img/animation.aseprite
```

TMJ/TSJ 本身就是运行格式，直接放 `assets/`；未来若有单独的编辑源格式再放入
`source_assets/`。

### 导出声明

每个 pack 在 `resource_packs/<pack-id>.pack.json` 中声明导出范围：

```json
{
  "schema": 2,
  "id": "dlc-victoria",
  "overrides": [],
  "compatibility": {
    "nx": [
      {
        "id": "victoria_maps",
        "archive": "Map.nx",
        "resolver": {
          "type": "world_map",
          "path": "Map/WorldMap/WorldMap010.img"
        }
      }
    ],
    "closure": [
      {
        "from": "victoria_maps",
        "include": ["mob", "npc", "bgm"]
      }
    ]
  }
}
```

`compatibility.nx` 是可选的遗留 NX 导入层。未来 pack 可以完全由自制资源构成，
不依赖 NX 输入。

`entries` 声明精确资源；`patterns` 使用 `?`、`*`、`**` glob 选择路径范围。
具名 selector 可以从 WorldMap 权威索引选择地图，`closure.from` 明确引用该 selector
并展开地图实际引用的 Mob、Npc 和 BGM。

## 三、导出流程

### 命令

```bash
cd ../nx_maple_res
moon run --target native cmd/main -- \
  export pack ../maple-moon/resource_packs/base.pack.json

# 仅查看 pattern、resolver 和 closure 的精确展开结果
moon run --target native cmd/main -- \
  export pack ../maple-moon/resource_packs/dlc-victoria.pack.json --explain
```

### 步骤

1. 将 entries、patterns、resolver 和 closure 展开为精确 NX 资源列表
2. 将 NX 节点导出为 JSON/PNG/TMJ/TSJ 等运行格式到临时 staging
3. 校验地图 life、图片等 pack 内引用闭包，缺失时终止导出
4. 依据 `<pack-id>.pack-lock.json` 清理已离开声明范围的旧生成物
5. 写入 `assets/<pack-id>/`，并将 `.aseprite` 写入镜像的 `source_assets/<pack-id>/`
6. 扫描运行目录，重建按路径排序的 `pack.json`

生成物清单只拥有 NX 导出的文件；缩小导出范围会删除旧生成物，手写资源保持不变。

对原始 NX 的缺失元数据、冲突动画名称等遗留瑕疵，在 `nx_maple_res`
的 compatibility transform 阶段统一修复，再写入 staging。游戏项目的 pack
声明只表达内容归属和导出边界，不承载单个 NPC/地图的瑕疵特例。

### 查询 NX 内容

```bash
cd ../nx_maple_res
moon run --target native cmd/main -- info assets/Map.nx 'Map/Map1'
moon run --target native cmd/main -- tree-path assets/Map.nx 'Map/Map1'
```

## 四、文件引用约定

导出文件内部统一使用相对路径，不写 `res://`、pack 名称或 `assets/`：

```text
Mob/0100100.img/mx.json
  + animation.json
  = Mob/0100100.img/animation.json
```

Tiled TMJ/TSJ 内部的相对引用由 Selene loader 根据入口物理路径自行解析。

Aseprite 与 NX JSON 中的相对图片引用由 `@res` 根据 JSON 所在目录解析。

`res://` 只用于游戏代码的公开入口，以及确实需要跨 pack 查找的显式引用。
