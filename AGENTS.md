# AGENTS.md

这个项目的目的是学习图形学、游戏引擎、游戏开发. 使用 [MoonBit](https://www.moonbitlang.com/), 一个现代的类 Rust 带 GC 的编程语言. 使用 [Selene](https://github.com/Yoorkin/selene), 非常新且小巧的 2D 游戏引擎. 缺少功能时, 先停下, 对比其他现代游戏引擎的实现, 提出改进方案.

## Policies & Mandatory Rules

### Mandatory Skill Usage

#### `$resource-processing-workflow`

缺少资源时使用. 可以导出 aseprite, tiled 资源, 以及以 JSON 格式导出 nx 资源.

#### `$snapshot-test`

项目主要用快照测试验证逻辑和画面, 使用该 skill 编写和执行测试.

#### `$verify-web-game`

使用该 skill 验证修改后的游戏.

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

加载预定义且不可缺失的资源时, 优先在 `resource` package 使用显式 require API, 例如 `require_json(path)`.

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
├── gdd.md                     ← 一页纸设计文档
├── CONTEXT.md                 ← 术语表
├── docs/
│   ├── specs/                 ← 功能规格
│   ├── narrative/             ← 叙事素材
│   ├── tuning/                ← 数值参数
│   ├── adr/                   ← 架构决策记录
│   └── pipeline.md            ← 资源管线
├── src/
│   ├── apps/
│   │   ├── game_web/          ← WebGPU/JS 入口, 日常开发和测试
│   │   └── game_native/       ← raylib/native 入口, 本地游玩
│   ├── engine/                ← 引擎/框架层
│   │   ├── game_app/          ← 共享运行时, 注册 systems
│   │   ├── game_server/       ← 服务器通信
│   │   ├── game_scene/        ← 场景管理
│   │   ├── game_state/        ← 状态管理
│   │   ├── graphics/          ← 图形工具 (z_index)
│   │   ├── ui/                ← 可复用的 UI 原语
│   │   ├── local_server/      ← 本地服务器
│   │   ├── resource/          ← 资源加载
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
│   └── tests/                 ← 集成/快照测试
├── assets/                    ← 资源文件
└── .env.test                  ← 测试环境配置
```

## Operation Guide

### Testing & Automated Checks

修改完 moonbit 代码后, 执行编译命令:

```bash
just check
just fmt
just test
just build
```

`just check` 覆盖 JS 与 native target, 但只做类型检查, 不进入 native C 编译/链接.

`just test` 运行 `scripts/moon-webgpu-test.mjs`, 该脚本自动发现 `src/tests` 下调用 `@capture_app.snapshot(` 的 WebGPU 快照测试包，用 `moon test --target js --build-only` 构建选定测试，再在浏览器环境执行. 可用 `node scripts/moon-webgpu-test.mjs --list` review 自动发现的测试包.

不要在日常开发中直接执行裸 `moon test`, 因为 MoonBit 会生成 native 测试可执行文件, 即使 `src/apps/game_native/` 没有手写测试, 也会触发 raylib/native 编译和链接.

不要把全仓 `moon test --target js` 当作默认流程. 画面测试依赖浏览器侧 `XMLHttpRequest` 和脚本提供的 asset server, 直接在 Node.js 里执行会把资源加载边界变成测试失败.

需要直接执行某个非画面 MoonBit 测试时, 显式指定 JS target 和测试路径，并先加载测试环境变量，避免 `selene-webgpu` 在 Node.js 下因缺少 DOM 报错：

```bash
# 在仓库根目录执行
source scripts/test-env.sh && moon test --target js --deny-warn --diagnostic-limit 200 <path>
```

日常构建只构建 Web 入口:

```bash
just build
```

只有需要玩家游玩或分发 native 版本时, 才构建 native 入口:

```bash
just build-native
```

## Utilities & Tips

### `moon.work` 本地工作区

优先检查项目根目录有没有`moon.work`文件, 如果有, 分析依赖库代码时, 要用`moon.work`里配置的相对路径, 而不是`.mooncakes`.

### 使用 Js 模块

用 MoonBit 的 `#module` attribute 声明 JavaScript 后端的依赖模块.

在 cjs 格式中, 它被解释为 require, 而在 esm 格式中, 它被解释为 import.

```mbt
#module("node:fs")
pub fn write_file_sync(file : String, data : String) = "writeFileSync"
```

### 解析 nx 资源

nx 资源以 JSON 格式存储. 导入到游戏时, 可以定义 MoonBit `struct` , 并实现 `FromJson` 接口来解析数据.
这些 struct 类型以 `Nx` 开头, 例如 `NxTexture` .

### JSON Match Pattern

处理 JSON 数据时, 优先用模式匹配, 而不是 `Object::get` 等方法.

```mbt
match json {
  { "version": "1.0.0", "import": [..] as imports, .. } => ...
  { "version": Number(i, ..), "import": Array(imports), .. } => ...
  ...
}
```

### JSON Literal

moonbit 支持 JSON 语法构造 `JSON` 类型的数据:

```mbt
let v : Json = {
  "version": "1.0.0",
  "import": ["import1", "import2"],
}
```

### String

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

### Sprite

使用 selene 的 `@sprite.Sprite` 渲染画面. 游戏的渲染层级比较多, z index 集中放在 `src/engine/graphics/z_index.mbt` 里管理.

`@entity.Entity` 不要保存到单个对象`struct`里, 而是保存到全局容器里.

### 资源

local server 是可以异步读取资源的.
客户端则要保证先 preload 资源, 避免`async`污染游戏逻辑代码.

大资源根目录默认被 `.gitignore` 忽略. 测试或运行时需要的最小资源闭包要用 `git add --force` 显式纳入，并包含 JSON 引用到的图片、spritesheet、tileset、animation JSON/PNG 和对应 `.aseprite` 源文件. 不提交引用图片缺失的半成品导出 JSON.
