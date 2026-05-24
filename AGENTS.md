# AGENTS.md

## 目标

这个项目的目的是学习图形学、游戏引擎、游戏开发.

使用 `moonbit`, 一个现代的类 `Rust` 带 GC 的编程语言.

使用 `selene`, 非常新且小巧的 2D 游戏引擎, 便于学习. 缺少功能时, 先停下, 对比其他现代游戏引擎的实现, 提出改进方案.

## Policies & Mandatory Rules

### Mandatory Skill Usage

#### `$resource-processing-workflow`

缺少资源时使用. 可以导出 aseprite, tiled 资源, 以及以 JSON 格式导出 nx 资源.

#### `$snapshot-test`

项目主要用快照测试验证逻辑和画面, 使用该 skill 编写和执行测试.

#### `$verify-web-game`

使用该 skill 验证修改后的游戏.

### Package README

每个 `package` 下都写 `README.mbt.md`, 说明包的职责和使用方法.

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

### 只写黑盒测试

`*_test.mbt` 文件是黑盒测试. 不写 helper 函数.

不允许写 `_for_test` 的 public symbol.

### Effectless new

`new` 函数不要带`async`, 如果需要异步初始化, 使用 `load` 作为函数名.

## Project Structure

### Repo Structure & Important Files

- `docs/`: 游戏策划文档.
- `adrs/`: 架构决策记录.
- `src/lib/ms`: 游戏模块源码.
- `src/test/`: 集成测试用例.
- `assets/`: 资源文件.
- `.env.test`: 测试环境配置文件. 包含 API Key 等敏感信息.
- `src/lib/local_server/`: 本地服务器实现.
- `src/lib/ms/server_proto/`: 客户端与(本地)服务器通信的协议定义.
- `src/lib/console/`: 游戏调试控制台, agent 调试时使用.
- `src/test/local_loader/`: 本地测试资源加载器. 路径处理跟正式资源完全一致, 只是加载方式变成从本地文件读取.

### Agents Core Runtime Guidelines

- `src/apps/game/game.mbt` 是游戏运行的入口, 负责注册 game systems.

## Operation Guide

### Testing & Automated Checks

修改完 moonbit 代码后, 执行编译命令, 确保页面能读到最新 js 内容:

```bash
moon check
moon fmt
moon info
moon build --release
```

执行 `moon test` 前先加载测试环境变量，避免 `selene-webgpu` 在 Node.js 下因缺少 DOM 报错：

```bash
# 在仓库根目录执行
source scripts/test-env.sh && moon test
```

## Utilities & Tips

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

使用 selene 的 `@sprite.Sprite` 渲染画面. 游戏的渲染层级比较多, z index 集中放在 `src/lib/graphics/z_index.mbt` 里管理.

`@entity.Entity` 不要保存到单个对象`struct`里, 而是保存到全局容器里.

### 资源

local server 是可以异步读取资源的.
客户端则要保证先 preload 资源, 避免`async`污染游戏逻辑代码.
