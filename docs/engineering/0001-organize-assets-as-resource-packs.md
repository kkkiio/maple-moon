# Organize Assets as DLC-style Resource Packs

## Context

Maple Moon 运行时消费 Aseprite JSON/PNG、Tiled TMJ/TSJ、LDtk、NX 导出 JSON、
图片、音频和数据表。这些格式需要共享一套稳定的资源地址，同时允许 base、DLC
和 patch 保存在相互隔离的目录中。

业务代码直接使用 `assets/...` 会绑定开发仓库布局。使用 `dlc_name://...` 会把
资源所属 pack 泄漏给调用方。Tiled、LDtk 和 Aseprite 中的相对引用还要求 loader
始终保留声明文件所在的虚拟目录。

## Decision

### 1. `res://` 是公开的资源地址

游戏代码、数据表和日志使用 `res://`：

```text
res://Mob/1210102.img/mx.json
res://Map/Map1/100000000.img.mx.json
res://Map/tiles/100000000.img.tmj
res://Skill/231.img/animations/skill__2311001.json
```

顶层 domain 沿用 NX 文件 stem 的大小写，比如 `Map`、`Mob`、`Npc`、
`Character`、`Item`、`Skill`、`Effect`、`Etc`、`Sound` 和 `UI`。Maple Moon
自有资源用 `Data`、`Quest` 和 `String`。

`res://` 地址去掉 scheme 后得到用于 pack 内查找的路径：

```text
res://Mob/1210102.img/mx.json  resource address
Mob/1210102.img/mx.json        ResourceKey
```

`ResourceKey` 是去掉 scheme 后的路径。它不包含 `assets/`、pack 名称、主机绝对
路径或网络 URL，也不会提前解析成某个 pack 的物理文件路径。

### 2. 按 pack 优先级把 `res://` 解析为物理路径

`assets/` 的第一层子目录就是 resource pack。base、DLC 和 patch 内部使用完全相同的
目录布局；`source_assets/` 按 pack ID 镜像存放可编辑源文件：

```text
maple-moon/
├── assets/
│   ├── base/                       base runtime pack
│   │   ├── Map/
│   │   ├── Mob/
│   │   └── UI/
│   ├── dlc-elnath/                 DLC runtime pack
│   │   ├── Map/
│   │   ├── Mob/
│   │   └── Sound/
│   └── patch-1/                    patch runtime pack
└── source_assets/
    ├── base/                       base editable sources
    ├── dlc-elnath/                 DLC editable sources
    └── patch-1/                    patch editable sources
```

`assets/` 和 `source_assets/` 的直接子目录名是 pack ID。pack ID 用于安装、启用和
诊断，不进入业务资源地址。当前游戏内容写入 `base`；新增 DLC 时增加新的同级
目录，不改动 `base` 的物理资源树。

每个运行 pack 根目录包含一个 `pack.json`，其中 `files` 是该 pack 提供的全部
ResourceKey 精确列表：

```json
{
  "schema": 1,
  "id": "base",
  "files": [
    "Map/Map1/100000000.img.mx.json",
    "Mob/0100100.img/mx.json"
  ]
}
```

`files` 只包含文件，不包含目录、glob、hash 和 `pack.json` 自身。它适合随资源一起
提交和分发；Git 已经负责版本差异，因此不增加 lock 文件。

`@res` 挂载时读取所有 manifest，按从低到高的 pack 优先级合成 ResourceKey 索引。
后挂载 pack 的同名 key 覆盖先挂载 pack。比如下面两个文件对应同一个 `res://`
地址，DLC 中的会成为最终索引项：

```text
assets/base/Mob/0100100.img/mx.json
assets/dlc-elnath/Mob/0100100.img/mx.json   ← 优先级更高，命中
→ 物理路径: assets/dlc-elnath/Mob/0100100.img/mx.json
```

需要注意：`@res` 只解析入口 `res://` 地址。manifest 不记录资源内部引用；导出的
JSON、TMJ、TSJ 和 LDtk 文件继续使用相对路径。Selene 拿到物理路径后，文件内部的
相对引用（TMJ→TSJ→图片）基于该物理路径解析，不会跨 pack 回退。因此 DLC 中
替换某个文件时，它引用的子资源也必须一并放入同一个 pack——每个 pack 是自包含的。

缺失 key 直接产生资源错误。`@res` 不搜索未挂载目录，也不回退到开发仓库的其他路径。

`source_assets/` 不进入玩家分发。

### 3. Selene loader 解析 Tiled 和 LDtk 的相对引用

资源格式保留普通相对路径：

```text
Map/Map1/100000000.img.mx.json
  + ../tiles/100000000.img.tmj
  = Map/tiles/100000000.img.tmj

Map/tiles/100000000.img.tmj
  + ../tilesets/tile_grassySoil.tsj
  = Map/tilesets/tile_grassySoil.tsj
```

Maple Moon 不预读或改写 Tiled、LDtk 文件中的路径。`@res` 只把入口
`res://...` 解析为 pack 内的物理路径，然后直接调用 Selene loader：

```text
@res.load_tiled_map("res://Map/tiles/100000000.img.tmj")
  → resolve to "assets/base/Map/tiles/100000000.img.tmj"
  → @tiled.load_tiled_map("assets/base/Map/tiles/100000000.img.tmj")
```

Selene 拿到物理路径后自己解析 TMJ、TSJ、LDtk project 和 external level，基于
传入的 source path 拼接相对引用。Maple Moon 这边不预读也不改写这些文件里的
路径——入口 `res://` 地址解析为物理路径后直接交给 Selene loader，剩下的事
Selene 自己搞定。

Aseprite JSON 不走这个流程——Selene 没有 Aseprite loader，它的解析和图片引用
由 `@res` 中的 Maple loader 处理（见 Decision 4）。

### 4. `src/engine/res` 拥有资源边界

现有 `src/engine/resource` 整体改名为 `src/engine/res`，package alias 使用
`@res`。该 package 集中拥有：

- `res://` 入口解析为 pack 内的物理路径（含 `\`→`/`、`.`/`..` 归一化、
  拒绝根目录越界、拒绝绝对路径和 URL）；
- base、DLC、patch manifest 的校验、索引合并与查找优先级；
- `require_json`、`require_image`、`load_text` 等 API——解析 `res://` 后交给
  Selene 或标准 I/O 加载；
- Aseprite animation 和 NX JSON 等 Maple 资源 loader（Selene 不包含 Aseprite
  loader，JSON 解析、图片路径拼接和加载由 `@res` 完成）；
- 将 Tiled/LDtk 入口 `res://` 解析为物理路径后委托给 Selene 的薄适配。

调用形式为：

```moonbit nocheck
@res.require_json("res://Mob/1210102.img/mx.json")
@res.require_image("res://UI/Basic.img/Cursor/cursor.png")
@res.load_tiled_map("res://Map/tiles/100000000.img.tmj")
```

@res 不接管 Selene 的 I/O——路径解析后 Selene 自己读文件、自己解码。物理
隔离的 pack 不会给 Tiled/LDtk 增加任何预处理逻辑。

不保留并行的 `resource` compatibility package。
现有 Maple `tiled_map_loader` 中读取 TMJ、展开外部 TSJ 的重复逻辑应删除；
`mx.json -> tiled_path` 仍属于 Maple metadata 解析，得到入口 key 后交给 Selene。

### 5. 编辑源文件不进入 `assets/`

`assets/<pack-id>/` 只保存运行时资源。`.aseprite` 等编辑源文件放在独立的
`source_assets/<pack-id>/`，保持与运行时 domain 相同的相对目录结构：

```text
assets/base/Mob/1210102.img/animations/stand.json
assets/base/Mob/1210102.img/animations/stand.png
source_assets/base/Mob/1210102.img/animations/stand.aseprite
```

`source_assets/<pack-id>/` 进入版本控制，但不挂载到 `res://`，也不进入玩家分发。
TMJ/TSJ 本身就是当前运行格式，因此继续保存在对应 `assets/<pack-id>/`；未来出现
单独的 TMX/TSX 编辑源文件时再放入镜像的 `source_assets/<pack-id>/`。

### 6. 测试使用相同的资源地址

- 纯逻辑测试直接构造资源数据，例如用 `MobResource` 构造 `Mob`；
- 普通 package 的 resolver/loader 测试用内存 reader 模拟挂载目录中的物理文件；
- 图形快照测试挂载 `assets/base/` 和测试声明的扩展 pack，并使用 raylib platform
  overrides；
- 所有资源测试都从 `res://` 地址进入 `@res`，不直接读取仓库路径。
- resolver 测试使用与正式 pack 相同的 `pack.json`，未声明的物理文件不可见。

## Consequences

- 游戏代码与仓库目录、pack 名称、安装位置和网络 URL 解耦。
- base、DLC 和 patch 可以物理隔离，同时共享稳定的资源地址。
- `pack.json` 提供可审查、可分发的精确文件索引，挂载不需要扫描安装目录。
- Tiled 和 LDtk 继续由 Selene 解析，相对引用通过 pack mount 规则解析到物理路径。
- Native、Web 和测试共享路径规范化和资源入口 API。
- 现有 `assets/...` 调用和 `@resource.*` 引用需要分别迁移到 `res://...` 和
  `@res.*`。

## Alternatives Considered

- **继续使用 `assets/...` 作为业务地址。** 运行协议会绑定开发仓库布局，DLC
  安装位置也会进入调用代码。
- **由 Maple Moon 预解析 Tiled/LDtk 并改写引用。** 会复制 Selene 已有的格式
  loader；路径在 mount 边界规范化已经足够。
- **挂载时扫描 pack 目录。** 目录 pack 可以这样做，归档包和远程包不能依赖目录
  枚举；显式 manifest 也让覆盖关系在提交时可 review。
- **给 manifest 增加 lock 或逐文件 hash。** Git 已经记录开发期内容版本；当前
  目录 pack 只需要寻址索引，未来归档分发需要完整性校验时再在分发层增加签名。
- **让 Tiled/LDtk 的每个相对引用重新经过全局 VFS。** 这会允许入口来自 base、
  外部 TSJ 或图片来自 patch 的半覆盖状态，破坏 pack 自包含约束。入口先解析为
  pack-specific 物理路径，DLC 替换入口文件时需一并放入其引用的子资源。
- **预先合并到额外的 runtime 目录。** 会制造第二棵运行资源树，并增加同步步骤。
- **为每个 DLC 定义 URI scheme。** 内容移动到其他 pack 时会改变业务地址。
- **在 Maple Moon 中分别实现 Native/Web 加载。** 平台 bytes 解码属于 Selene
  backend，Maple Moon 只维护资源地址和 mount 语义。
