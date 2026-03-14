# AGENTS.md

## 目标

这个项目的目的是学习图形学、游戏引擎、游戏开发.

使用 `moonbit`, 一个现代的类 `Rust` 带 GC 的编程语言.

使用 `selene`, 非常新且小巧的 2D 游戏引擎, 便于学习. 缺少功能时, 先停下, 对比其他现代游戏引擎的实现, 提出改进方案.

## Project overview

- `docs/` - 游戏策划文档
- `src/lib/ms` - 游戏模块源码
- `src/test/` - 集成测试用例
- `assets/` - 资源文件

## Mandatory skills workflow

- 缺少资源时，使用 `resource-processing-workflow` skill 处理.
- 添加/修改 UI, 画面元素时，使用 `render-snapshot-test-loop` skill 处理.

## 文档

每个 `package` 下都写 `README.mbt.md`, 说明包的职责和使用方法.
更具体的说明写在代码的 Doc comments 里.

## 验证

修改完 moonbit 代码后, 执行编译命令, 确保页面能读到最新 js 内容:

```bash
moon fmt
moon info
moon build --release
```

只写黑盒测试.

执行 `moon test` 前先加载测试环境变量，避免 `selene-canvas` 在 Node.js 下因缺少 DOM 报错：

```bash
# 在仓库根目录执行
source .env.test && moon test
```

### Moonbit 快照测试

使用 `inspect`/`json_inspect` 做快照断言, 不要自己填/修改 `content` 参数, 用 `moon test --update` 更新快照.

### Canvas 快照测试

涉及画面回归时，统一使用 `@capture_app.snapshot(path)` 做图片快照断言.

`@capture_app.snapshot` 的规则:

- 当快照文件不存在，或设置了 `UPDATE_CANVAS_SNAPS=true` 时，写入/更新 PNG 快照。
- 其他情况下，按 PNG bytes 全等比较；不一致则测试失败。

更新图片快照使用:

```bash
UPDATE_CANVAS_SNAPS=true moon test <test-target>
```

`moon test --update` 只用于 MoonBit 官方的 `inspect`/文本快照更新，不用于 canvas PNG 快照更新。

## Coding Style

### 注释

所有 public symbol 都要写 Doc comments, 包括:

- `pub fn`.
- `pub enum`, 尽量给每个 variant 加注释.
- `pub struct`, 如果允许外部构造时(`pub(all)`), 所有字段都要加注释.

Write documentation using `///` comments (started with `///|` to delimit the block code)

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

### 禁止 fallback

除非必要, 否则不要写 fallback 逻辑, 干扰问题排查. 可以在函数返回值后加`raise`关键词, 让错误继续往上传播.

MoonBit 允许 `test` 直接传播错误, 用 `fail` 函数抛出错误.

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

- `lexmatch` 正则匹配

```mbt
test {
  let text = "xxabbbcyy"
  lexmatch text {
    (before, "a" ("b*" as b) "c", after) => {
      inspect(before, content="xx")
      inspect(b, content="bbb")
      inspect(after, content="yy")
    }
    _ => fail("")
  }

  if text lexmatch? ("a" ("b*" as b) "c") && b.length() > 0 {
    inspect(b, content="bbb")
  }

  let keyword = "iff"
  lexmatch keyword with longest {
    ("if|[a-z]*" as ident) => inspect(ident, content="iff")
    _ => fail("")
  }
}
```

### Sprite

使用 selene 的 `@sprite.Sprite` 渲染画面. 游戏的渲染层级比较多, z index 集中放在 `src/lib/graphics/z_index.mbt` 里管理.

`@entity.Entity` 不要保存到单个对象`struct`里, 而是保存到全局容器里.

### 资源

local server 是可以异步读取资源的, 客户端则要保证先 preload 资源, 避免`async`污染游戏逻辑代码.
