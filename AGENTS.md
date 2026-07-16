# AGENTS.md

这个项目的目的是学习图形学、游戏引擎、游戏开发. 使用 [MoonBit](https://www.moonbitlang.com/), 一个现代的类 Rust 带 GC 的编程语言. 使用 [Selene](https://github.com/kkkiio/selene), 非常新且小巧的 2D 游戏引擎. 缺少功能时, 先停下, 对比其他现代游戏引擎的实现, 提出改进方案.

## Domain Language

- **Resource pack** — 包含 `pack.json` 清单、可按优先级挂载的一组运行资源.
- **`res://` address** — 与资源包物理目录解耦的公开资源地址.
- **Graphics snapshot** — 由 native raylib backend 捕获并与 PNG baseline 逐像素比较的视觉回归结果.
- **Playtest bot** — 通过 `game_debug` 和 `BotController` 执行场景脚本的自动化玩家.

## Policies & Mandatory Rules

### Mandatory Skill Usage

#### `$write-snapshot-test`

新增或修改数据/图片快照测试时, 使用该 skill 编写测试. 只执行已有测试或排查失败时无需使用该 skill; 遵循 Testing & Automated Checks.

### Package README

Main package 使用 `README.md`, 避免 MoonBit main package 把 `README.mbt.md` 当作 blackbox test 输入并产生 warning.

非 main package 使用 `README.mbt.md`, 说明包的职责和使用方法，并让文档示例继续参与 MoonBit 检查.

### Doc comments

所有 public symbol 都要写 Doc comments, 包括:

- `pub fn`. 写功能描述, 说明边缘情况, 并附带 `Example`.

````moonbit
///|
/// Get the largest element of a non-empty `Array`.
///
/// # Example
/// ```moonbit
/// inspect(my_maximum([1,2,3,4,5,6]), content="6")
/// ```
///
/// # Panics
/// Panics if the `xs` is empty.
pub fn[T : Compare] my_maximum(xs : Array[T]) -> T {
  ...
}
````

- `pub enum`. 尽量给每个 variant 加注释.
- `pub struct`. 如果允许外部构造时(`pub(all)`), 所有字段都要加注释.

### 禁止 fallback

除非明确要求, 否则不写 fallback 逻辑, 避免干扰问题排查. 可以在函数返回值后加 `raise` 关键词, 让错误继续往上传播.

MoonBit 允许 `test` 直接传播错误, 用 `fail` 函数抛出错误.

### 错误处理边界

写底层或基础函数时, 不要直接 `abort`/`panic`/`unwrap`, 除非函数名已经明确表达必须成功, 例如 `require_*` 或 `must_*`.

加载预定义且不可缺失的资源时, 优先在 `res` package 使用显式 require API, 例如 `@res.require_json(url)`. 地址使用 `res://` 而非物理路径.

写普通 `load`/`parse`/`from_*` 函数时, 使用 `raise` 和 `fail` 把错误往上传递, 直到 system 函数或明确的 require 边界. 在 system 函数里带上业务上下文记录日志, 再决定 `abort`.

不要写 `option.unwrap_or(abort(...))` 或 `result.unwrap_or(panic(...))`; `unwrap_or` 的 fallback 会先求值. 需要延迟终止时, 使用 `unwrap_or_else(fn() { abort(...) })`, 或直接写 `match`.

### 只写黑盒测试

`*_test.mbt` 文件是黑盒测试. 不写 helper 函数.

不允许写 `_for_test` 的 public symbol.

### Effectless new

`new` 函数不要带`async`, 如果需要异步初始化, 使用 `load` 作为函数名.

### 文档与代码的关系

文档描述项目**应当**处于的状态，代码是实现。两者不一致时，以文档为准——要么补代码，要么更新文档。

## Project Structure Guide

### Repo Structure & Important Files

```
├── playtests/               ← AI 编写的 bot 场景脚本 (纯 JS, 不参与 MoonBit 编译)
├── gdd.md                     ← 一页纸设计文档
├── docs/
│   ├── specs/                 ← 功能规格
│   ├── narrative/             ← 叙事素材
│   ├── tuning/                ← 数值参数
│   ├── engineering/           ← 当前工程决策（living docs，不记录状态或迁移历史）
│   └── pipeline.md            ← 资源管线
├── src/
│   ├── apps/
│   │   ├── game_web/          ← WebGPU/JS 入口, 日常开发
│   │   ├── game_native/       ← raylib/native 入口, 玩家本地游玩
│   │   └── game_debug/        ← WebGPU/JS 入口, bot 验证专用 (含 BotController)
│   ├── engine/                ← 引擎/框架层 (含测试基础设施)
│   │   ├── game_app/          ← 共享运行时, 注册 systems
│   │   ├── bot_controller/    ← Playtest Bot 运行时 (输入注入, action 管理, globalThis.__bot)
│   │   ├── game_server/       ← 服务器通信 (正式实现)
│   │   ├── mock_server/       ← game_server 的测试替身 (virtual package)
│   │   ├── capture_app/       ← 快照断言与 mock server 状态管理
│   │   ├── game_scene/        ← 场景管理
│   │   ├── game_state/        ← 状态管理
│   │   ├── graphics/          ← 图形工具 (z_index)
│   │   ├── ui/                ← 可复用的 UI 原语
│   │   ├── local_server/      ← 本地服务器
│   │   ├── res/               ← 资源加载 (res:// 入口、VFS、格式 loader)
│   │   ├── console/           ← 调试控制台
│   │   └── log/ utils/ io_service/ randx/ fsx/ lazy/
│   ├── game/                  ← MapleStory 游戏逻辑
│   │   ├── combat_system/     ← 战斗主逻辑
│   │   ├── combat_proto/      ← 战斗数据结构
│   │   ├── damage/            ← 伤害计算
│   │   ├── hit_detection/     ← 命中判定
│   │   ├── regular_attack/    ← 普通攻击
│   │   ├── skill/             ← 技能数据
│   │   ├── skill_cast/        ← 技能施放
│   │   ├── skill_sfx/         ← 技能特效
│   │   ├── passive/           ← 被动技能
│   │   ├── buff/              ← Buff
│   │   ├── bullet/            ← 投射物
│   │   ├── vfx/ vfx_skill/ vfx_afterimage/
│   │   ├── character/ char_look/ char_stance/ char_stats/
│   │   ├── character_body/ character_presentation/
│   │   ├── monster/ npc/ pet/ player/
│   │   ├── map/ map_object/ physics/ controller/ transform2d/
│   │   ├── inventory/ equip/ item/ quest/ drop/
│   │   ├── clothing/ weapon/ job/ res_types/
│   │   ├── animation/ bgm/ camera/ cursor/ logic_fps/
│   │   ├── maple_stat/ markup_text/ server_proto/
│   │   └── ui/                ← 游戏画面 (背包、商店、NPC 对话等)
│   ├── graphics_test/         ← 图形快照测试 (视觉回归, 一个 package)
│   └── cmd/                   ← 命令行工具（MoonBit native target）
│       ├── maple/             ← native CLI (maple start / cmd / logs / bot ...)
│       └── mapled/            ← native CDP daemon (Chrome 控制, 注入, 采集)
├── assets/                    ← 运行资源 (按 resource pack 组织)
│   └── base/                  ← base pack (当前 Victoria Island 运行闭包)
└── source_assets/             ← 编辑源文件 (.aseprite 等，不入 VFS，不分发)
    └── base/                  ← 与 assets/base/ 镜像
```

### Assets Structure

游戏代码使用 `res://` 地址访问资源，不写 `assets/` 物理路径。`assets/` 按 resource
pack 组织，当前只有 `base` pack（Victoria Island 闭包）。`source_assets/` 镜像存放
`.aseprite` 等编辑源文件，不入 VFS、不进入分发。

```text
assets/
└── base/
    ├── Character/             ← 角色身体、发型、脸型、装备、afterimage
    ├── Data/                  ← 游戏数据表 (tsv/json)
    ├── Effect/                ← 特效数据
    ├── Etc/                   ← 杂项
    ├── Item/                  ← 道具数据与图片
    ├── Map/                   ← Tiled TMJ/TSJ、tileset 与地图图片
    ├── Mob/                   ← 怪物 mx.json 与 aseprite 动画闭包
    ├── Npc/                   ← NPC mx.json 与 aseprite 动画闭包
    ├── Quest/                 ← 任务数据
    ├── Skill/                 ← 技能数据与动画
    ├── Sound/                 ← BGM/SFX 音频
    ├── String/                ← NX String JSON
    └── UI/                    ← UI 布局与素材

source_assets/
└── base/
    └── (与 assets/base/ 镜像的 .aseprite 等源文件)
```

运行资源与编辑源文件分离的详细约定见 `docs/pipeline.md`，寻址与挂载见
`docs/engineering/0001-organize-assets-as-resource-packs.md`。

服务端和客户端尽量读同一份资源。只有一方完全用不到的数据才拆开；资源缺口优先
通过补齐现代闭包解决。

## Operation Guide

### Testing & Automated Checks

完整回归优先推送分支并通过面向 `main` 的 PR 使用远程 GitHub Actions `CI` 工作流执行，减少本地 CPU、GPU、内存和磁盘占用。仅在需要快速反馈或定位远程失败时按需执行本地检查；合入前以远程 CI 的全量回归结果为准。

#### Snapshot Test Rules

- 使用 `@debug.debug_inspect` 或 `json_inspect` 生成数据快照, 不手写 `content`.
- 在每个图形快照测试中先执行数据快照, 再执行 `@capture_app.snapshot` 图片快照.
- 观察贴近被测行为的稳定领域状态. 排除 entity ID、指针、runtime handle、偶然集合顺序和无关瞬时状态.
- 不直接 inspect 全局 sprites/entities registry. 仅当精确数量本身是稳定且可解释的行为时才观察数量.
- 固定图形测试的画布尺寸、UI 位置、输入和帧推进次数. 使用测试文件路径和测试函数名描述场景, 不传入已废弃的 `visual_desc`.
- 把工具生成的 baseline 当作待审查结果. 检查数据 diff 和 PNG 内容符合测试意图后再接受.
- 仅在新增测试且没有 baseline PNG 时使用 `UPDATE_GRAPHICS_SNAPS=true`. 已有测试发生 pixel mismatch 时, 先检查 `.wrong.png`；仅在确认视觉变化符合预期后更新 baseline.

需要在本地执行完整回归时, 使用与远程 CI 相同的命令:

```bash
just check
just fmt
just test
just build
```

`just check` 覆盖 JS 与 native target, 但只做类型检查, 不进入 native C 编译/链接.

`.mbti` 文件是 MoonBit 生成的包接口摘要, 记录 public API 签名, 供依赖包和文档示例检查使用.

`moon info` 可能会更新 `pkg.generated.mbti` 的文件末尾空行. 这类纯空行 diff 是生成器输出, 不要回滚或清理; 只需要检查 public API 是否有语义变化.

`just test` 运行所有 native target 测试，包括普通逻辑测试、数据测试和 native raylib 图形快照测试:

```bash
moon test --target native --no-parallelize --deny-warn --warn-list=-28-79-82 --diagnostic-limit 200
```

native raylib 图形测试共享进程级窗口与 OpenGL context，必须使用
`--no-parallelize` 顺序执行，避免测试之间并发 clear/draw/capture.

PNG 快照更新使用 `UPDATE_GRAPHICS_SNAPS=true`; MoonBit inspect 快照更新继续使用 `moon test --update`.

`UPDATE_GRAPHICS_SNAPS=true` 只用于更新图形快照 PNG. Moon 的 path 参数不会递归父目录下的子 package；所有图形快照测试都在 `src/graphics_test/` 一个 package 内（迁移完成后），更新命令见 `just update-graphics-snaps`。

目录重构时，`__snapshot__/` 下的 27 张 PNG baseline 必须原样移动到新路径对应的子目录，不得用 `UPDATE_GRAPHICS_SNAPS=true` 重新生成。迁移完成后必须在无该变量的情况下复跑确认全部通过。

不要在日常开发中直接执行裸 `moon test`, 因为它会同时考虑不必要的 target/backend. 使用 `just test` 跑 native 测试全集；图形快照测试需要单独调试时，显式指定 native target 和测试 package path.

不要把全仓 `moon test --target js` 当作默认流程. 画面测试使用 native raylib backend; JS target 用于 Web 入口，`src/cmd/maple` 与 `src/cmd/mapled` 使用 native target.

需要直接执行某个 JS target MoonBit 测试时, 显式指定 JS target 和测试路径：

```bash
# 在仓库根目录执行
moon test --target js --deny-warn --diagnostic-limit 200 <path>
```

日常构建只构建 Web 入口:

```bash
just build
```

只有需要玩家游玩或分发 native 版本时, 才构建 native 入口:

```bash
just build-native
```

### Utilities & Tips

#### `moon.work` 本地工作区

优先检查项目根目录有没有`moon.work`文件, 如果有, 分析依赖库代码时, 要用`moon.work`里配置的相对路径, 而不是`.mooncakes`.

#### 使用 Js 模块

用 MoonBit 的 `#module` attribute 声明 JavaScript 后端的依赖模块.

在 cjs 格式中, 它被解释为 require, 而在 esm 格式中, 它被解释为 import.

```mbt
#module("node:fs")
pub fn write_file_sync(file : String, data : String) = "writeFileSync"
```

#### 解析 nx 资源

nx 资源以 JSON 格式存储. 导入到游戏时, 可以定义 MoonBit `struct` , 并实现 `FromJson` 接口来解析数据.
这些 struct 类型以 `Nx` 开头, 例如 `NxTexture` .

#### JSON Match Pattern

处理 JSON 数据时, 优先用模式匹配, 而不是 `Object::get` 等方法.

```mbt
match json {
  { "version": "1.0.0", "import": [..] as imports, .. } => ...
  { "version": Number(i, ..), "import": Array(imports), .. } => ...
  ...
}
```

#### JSON Literal

moonbit 支持 JSON 语法构造 `JSON` 类型的数据:

```mbt
let v : Json = {
  "version": "1.0.0",
  "import": ["import1", "import2"],
}
```

#### String

moonbit 的 `String` 是 UTF-16 编码的, API 为了考虑性能, 默认返回 UTF-16 code unit 数据:

- `s[i]` 返回的是 UTF-16 code unit.
- `s[i:j]` slice operator 被禁用, `s.charcodes(start = i, end = j)` 返回的是 UTF-16 code unit `StringView`.

为了正确处理 unicode 字符, 使用:

- `str.iter()` 遍历字符.
- `match` 匹配子串.

```mbt
match path {
  [.. "/route/", .. sub_path] => {// equivalent to ['/', 'r', 'o', 'u', 't', 'e', '/', ..]
    ... // sub_path 匹配 /route/ 后面的所有内容
  }
}
```

- `=~` 正则匹配

```mbt
const REGEX_IDENT_START = re"[A-Za-z_]"
const REGEX_IDENT_CONT = re"[A-Za-z0-9_]*"
test {
  let input = " let_name = 42 "
  if (input =~ (
      (REGEX_IDENT_START + REGEX_IDENT_CONT) as ident,
      before=head,
      after=tail
    )) {
    assert_true(head is " ")
    assert_true(ident is "let_name")
    assert_true(tail is " = 42 ")
  } else {
    fail("expected identifier")
  }

  if ("abc" =~ (re"b", before~, after~)) {
    assert_true(before is "a")
    assert_true(after is "c")
  } else {
    fail("expected middle match")
  }

  let source : StringView = "abc"
  if (source =~ (re"." as ch, after=rest)) {
    assert_eq(ch, 'a')
    assert_true(rest is "bc")
  } else {
    fail("expected leading char")
  }

  assert_true("zabc!" =~ re"abc")
  assert_true(!("zabc!" =~ re"^abc"))
}
```

#### Sprite

使用 selene 的 `@sprite.Sprite` 渲染画面. 游戏的渲染层级比较多, z index 集中放在 `src/engine/graphics/z_index.mbt` 里管理.

`@entity.Entity` 不要保存到单个对象`struct`里, 而是保存到全局容器里.

#### 资源

游戏代码通过 `res://` 地址访问资源，不写 `assets/` 物理路径。`@res` package 负责
解析 `res://`、挂载 resource pack、交给 Selene loader。

local server 可以异步读取资源。客户端要保证先 preload，避免 `async` 污染游戏
逻辑代码。

提交资源时运行产物进 `assets/base/`，编辑源文件（`.aseprite` 等）进镜像的
`source_assets/base/`。不提交引用图片缺失的半成品导出 JSON。
