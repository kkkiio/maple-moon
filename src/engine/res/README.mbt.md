# Res

`res` 是 Maple Moon 的资源边界。它把稳定的 `res://<Domain>/...` 地址映射到
已挂载 resource pack 中的物理路径，并集中提供 JSON、文本、图片、Aseprite 与
Tiled 入口 loader。游戏 package 不应知道 pack ID、安装位置或仓库中的
`assets/` 布局。

## 挂载与优先级

pack 按从低到高的优先级配置；后面的 pack 只能覆盖其 manifest
`overrides` 中显式声明的同名 key：

```moonbit nocheck
try! @res.configure_packs([
  ("base", "/opt/maple-moon/packs/base"),
  ("dlc-elnath", "/opt/maple-moon/packs/dlc-elnath"),
  ("patch-1", "/opt/maple-moon/packs/patch-1"),
])
```

每个根目录必须包含 schema 2 的 `pack.json`。`files` 是 pack 提供的精确
ResourceKey 列表；未列出的物理文件不会进入 VFS：

```json
{
  "schema": 2,
  "id": "base",
  "overrides": [],
  "files": ["Data/shops.tsv", "UI/UIWindow2.img/Quest/quest_info.json"]
}
```

`@game_app.base_app()` 默认挂载仓库和发行包使用的 `assets/base` 与
`assets/dlc-victoria`。自定义启动器把
实际安装根目录传给 `base_app(resource_packs=...)`，业务资源地址无需变化。

## 加载边界

普通 loader 使用可抛错 API，把地址非法、资源缺失和解码错误交给 system 处理：

```moonbit nocheck
let source = try! @res.load_text("res://Data/shops.tsv")
let quest = try! @res.load_json("res://Quest/QuestInfo.img.json")
ignore(source)
ignore(quest)
```

预定义且不可缺失的运行资源使用显式 require API：

```moonbit nocheck
let cursor = @res.require_image(
  "res://UI/Basic.img/Cursor/cursor_animation.png",
)
let strings = @res.require_json("res://String/Skill.img.json")
ignore(cursor)
ignore(strings)
```

`require_path`、`require_json` 和 `require_image` 是允许终止程序的边界。底层解析和
加载函数继续传播 `ResourceLoadError`。

## 动画资源边界

`AnimationLoader` 与 `compile_nx_animation` 只把资源编译为 `SpriteClip`。它包含
图片、atlas layout、clip handle、锚点和帧元数据，不创建播放 graph、node 或
player。消费它的怪物、NPC、特效或 UI controller 决定 graph 拓扑、循环策略和
状态切换；固定视觉直接调用 `SpriteClip::sprite()` 使用首帧。

```moonbit nocheck
let loaded = try! @res.AnimationLoader().load(
  "res://Mob/0100101.img/animations/move.json",
)
let move_clip = try! loaded.clip("move")
let initial_sprite = move_clip.sprite()
ignore(initial_sprite)
```

## Pack 内相对引用

入口地址先选择获胜 pack，再把物理路径交给格式 loader。声明文件中的普通相对
引用始终固定在同一个 pack：

```moonbit nocheck
let mx = try! @res.resolve("res://Map/Map1/100000000.img.mx.json")
let tiled = try! @res.resolve_ref(mx, "../tiles/100000000.img.tmj")
ignore(tiled)
```

因此 patch 替换 TMJ、Aseprite JSON 或其他入口文件时，也必须携带它引用的完整
TSJ、图片或 spritesheet 闭包。显式 `res://` 引用会重新执行全局 pack 查找。
NX 导出 JSON 中的 `__i` 也保持相对路径；`load_json` 根据该 JSON 的获胜物理路径
解析图片引用。Tiled/LDtk 文件直接交给 Selene，不会经过这层 JSON 处理。

## 运行资源与编辑源文件

`assets/<pack-id>/` 只包含运行文件；`.aseprite` 等编辑源文件位于镜像的
`source_assets/<pack-id>/`，不会挂载或进入玩家分发。完整目录与导出约定见
`docs/pipeline.md`。
