# 资源管线（Asset Pipeline）

本文档描述 Maple Moon 资源从 NX、Aseprite 和 Tiled 到 `res://` 的组织、导出与
校验流程。运行时寻址与 pack 优先级见
`docs/engineering/0001-organize-assets-as-resource-packs.md`。

## 总览

```text
源数据                         运行时输出                  运行时地址
──────────────────────────────────────────────────────────────────────────
NX *.nx                     → mx/json/tmj/tsj/png/audio → res://<Domain>/...
Aseprite *.aseprite         → json + png spritesheet    → res://<Domain>/...
Tiled TMX/TSX 或编辑操作     → tmj + tsj                 → res://Map/...
Maple Moon 自有数据          → tsv/json/audio            → res://Data/... 等
```

职责边界：

- `../nx_maple_res` 保存原始 `.nx` 输入并实现 NX 导出工具；
- `assets/<pack-id>/` 保存可直接挂载和分发的运行 resource pack；
- `source_assets/<pack-id>/` 镜像各 pack 中需要版本控制的可编辑源文件；
- `src/engine/res` 负责 `res://` 解析、pack 优先级查找和格式 loader；
- Selene 负责从物理路径加载 bytes 并解码为平台资源；

## 一、目录边界

```text
maple-moon/
├── assets/
│   ├── base/                   base runtime pack
│   │   ├── pack.json           精确列出 pack 内全部运行文件
│   │   ├── Character/
│   │   ├── Data/
│   │   ├── Effect/
│   │   ├── Etc/
│   │   ├── Item/
│   │   ├── Map/
│   │   ├── Mob/
│   │   ├── Npc/
│   │   ├── Quest/
│   │   ├── Skill/
│   │   ├── Sound/
│   │   ├── String/
│   │   └── UI/
│   ├── dlc-elnath/             DLC runtime pack
│   │   ├── Map/
│   │   ├── Mob/
│   │   └── Sound/
│   └── patch-1/                patch runtime pack
└── source_assets/
    ├── base/                   base editable sources
    ├── dlc-elnath/             DLC editable sources
    └── patch-1/                patch editable sources
```

顶层 domain 沿用对应 NX 文件的 stem 大小写。NX 根节点通常没有名字，所以用
文件 stem 作为稳定的命名空间；domain 内部继续保留有意义的 NX node 层级：

```text
Map.nx : Map/Map1/100000000.img → res://Map/Map1/100000000.img.mx.json
Map.nx : Back/grassySoil.img     → res://Map/Back/grassySoil.img/...
Mob.nx : 0100100.img             → res://Mob/0100100.img/...
Npc.nx : 0002100.img             → res://Npc/0002100.img/...
```

Maple Moon 自有 domain 用 `Data`、`Quest` 和 `String`。运行资源不走全局的
`images/`、`spritesheets/`、`portal/` 这类共享目录；图片和 spritesheet 放在拥有
它们的 domain 闭包里。

## 二、运行资源与编辑源文件

### Aseprite

`.aseprite` 只出现在 `source_assets/<pack-id>/`，导出的 JSON/PNG 只出现在
`assets/<pack-id>/`。两棵目录镜像 pack ID、domain 和资源相对位置：

```text
source_assets/base/Mob/0100100.img/animations/stand.aseprite
assets/base/Mob/0100100.img/animations/stand.json
assets/base/Mob/0100100.img/animations/stand.png
```

Aseprite JSON 使用相对路径引用同目录 PNG。运行时从 JSON 的 `res://` 地址解析
spritesheet：

```moonbit nocheck
AnimationLoader::load(
  "res://Mob/0100100.img/animations/stand.json",
)
```

### Tiled

TMJ/TSJ 是当前编辑和运行共同使用的格式，因此保存在对应 pack 的
`assets/<pack-id>/Map/`。TMJ 引用外部 TSJ，TSJ 引用图片，全部使用普通相对路径：

```text
assets/base/Map/tiles/100000000.img.tmj
assets/base/Map/tilesets/tile_grassySoil.tsj
assets/base/Map/images/<bitmap>.png
```

如果以后保留单独的 TMX/TSX 编辑源文件，它们进入对应的
`source_assets/<pack-id>/Map/`，TMJ/TSJ 仍进入镜像的 `assets/<pack-id>/Map/`。

### NX

原始输入位于：

```text
../nx_maple_res/assets/<Domain>.nx
```

运行时只提交导出后的完整资源闭包。根据资源语义选择输出格式：

- playable map：TMJ、TSJ、图片和 map metadata；
- Mob/Npc/Effect/Skill 动画：结构化 JSON 与 Aseprite JSON/PNG；
- Character paper-doll：保留锚点、z、stance 和 bitmap 引用的结构化 JSON；
- String/Etc/Quest/Data：JSON 或 TSV 数据；
- Sound：音频文件及必要索引。

`../nx_maple_res/cache/nx_export` 是排查和中间输出目录，不作为 Maple Moon 的长期
运行依赖。

## 三、资源地址与相对引用

游戏代码只用 `res://` 地址，不去碰 `assets/` 物理路径。`res://` 的解析与 pack
优先级见 `docs/engineering/0001-organize-assets-as-resource-packs.md`。

导出文件内部统一使用相对路径，不写 `res://`、pack 名称或 `assets/`：

```text
Mob/0100100.img/mx.json
  + animations/stand.json
  = Mob/0100100.img/animations/stand.json
```

Tiled 和 LDtk 内部的相对引用由 Selene loader 根据入口物理路径自行拼接；Maple
Moon 不预读或改写这两种格式。Aseprite 与 NX JSON 的相对图片引用由 `@res`
根据 JSON 文件所在目录解析。`res://` 只用于游戏代码的公开入口，以及确实需要
重新执行全局 pack 查找的显式跨资源引用。

## 四、Base、DLC 与 patch

base、DLC 和 patch 都是 `assets/` 下的同级目录，内部布局相同。构建 DLC 时只分发
选定的 `assets/<pack-id>/`，对应的 `source_assets/<pack-id>/` 留在开发仓库。
挂载顺序和覆盖语义见 ADR 0001。

资源文件内部不能写 pack 名称、`assets/`、主机绝对路径或网络 URL。

每个 `assets/<pack-id>/pack.json` 精确列出该 pack 的运行文件。它是运行时 VFS
索引，随 pack 提交和分发；它不是导出 lock，不记录 NX 输入、时间戳或 hash。

## 五、导出流程

每个 pack 在 `resource_packs/<pack-id>.selene.json` 保存可审查的导出定义：

```json
{
  "schema": 1,
  "id": "base",
  "runtime_root": "../assets/base",
  "source_root": "../source_assets/base",
  "sources": [
    {
      "nx": "Map.nx",
      "entries": ["Map/Map1/102000001.img"]
    },
    {
      "nx": "Mob.nx",
      "entries": ["Mob/0100100.img"]
    }
  ]
}
```

`nx` 只写 NX 文件名，由 `nx_maple_res` 从自己的 `assets/` 目录解析。`entries`
使用精确 NX node/container 路径，不接受 glob；container 会递归导出。输出根目录
相对于定义文件解析，因此定义不依赖开发者的绝对路径。

缺少 NX 资源时运行：

```bash
cd ../nx_maple_res
moon run --target native cmd/main -- \
  export selene ../maple-moon/resource_packs/base.selene.json
```

命令执行流程：

1. 从 `entries` 生成底层 exporter 的 include 范围，并导出到空 staging；
2. JSON/PNG/TMJ/TSJ 等运行输出复制到 `runtime_root`；
3. `.aseprite` 移入镜像的 `source_root`；
4. 扫描最终运行目录并重建按路径排序的 `pack.json`；
5. 现有 pack 中不属于本次 entries 的手写资源保持不变；删除资源时显式删除文件，
   由 Git 展示变更，下一次导出同步刷新 manifest。

导出定义、运行产物、编辑源文件与 `pack.json` 一起提交。不生成 lock 文件。

查询 NX 节点：

```bash
cd ../nx_maple_res
moon run --target native cmd/main -- info assets/Map.nx 'Map/Map1'
moon run --target native cmd/main -- tree-path assets/Map.nx 'Map/Map1'
```

## 六、完整性校验

资源提交前检查：

- `mx.json` 指向的 TMJ 或 animation JSON 存在；
- TMJ 引用的 TSJ、图片和背景动画存在；
- TSJ 引用的图片存在；
- Aseprite JSON 引用的 PNG 存在；
- `pack.json.files` 与 pack 内运行文件一致，且没有重复路径；
- `assets/<pack-id>/` 中没有 `.aseprite`；
- `source_assets/<pack-id>/` 中的源文件有对应运行输出；
- 路径大小写与 domain 约定一致；
- 所有引用都能规范化为合法 `ResourceKey`；
- loader 缺资源时直接报错，不做 fallback。

代码与资源修改完成后执行：

```bash
just check
just fmt
just test
just build
```

## 七、版本控制边界

进入版本控制：

- 当前 Victoria Island 范围内 `assets/base/` 的完整运行闭包；
- `resource_packs/base.selene.json` 与 `assets/base/pack.json`；
- 与这些运行输出对应的 `source_assets/base/` 编辑源文件；
- 图形快照测试使用的同一份运行资源。

不进入版本控制：

- `../nx_maple_res/assets/*.nx`；
- `../nx_maple_res/cache/nx_export*`；
- Aseprite 临时 manifest、atlas 和诊断日志；
- 当前游戏范围之外的全量导出。

不要用 `.gitignore` 忽略整个 `assets/` 或 `source_assets/`。资源导出与源文件变化
都应在 `git status` 中可见并参与 review。
