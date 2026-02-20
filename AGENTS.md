# AGENTS 指南

## 目标

这个项目的目的是学习图形学、游戏引擎、游戏开发。

使用 `moonbit` , 一个现代的类 `Rust` 带 GC 的编程语言。

使用 `selene` , 非常新且小巧的 2D 游戏引擎, 便于学习。缺少功能时，先要对比其他现代游戏引擎的实现，再提出改进方案。

## 验证

修改完 moonbit 代码后, 执行编译命令, 确保页面能读到最新 js 内容:

```bash
moon build --release
```

moon 默认告警比较多, 主动修正代码减少告警.

只写黑盒测试.

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

### 如何写渲染快照测试

参考 `src/test/char_look_test/stand1_test.mbt` 的结构，推荐流程：

1. 在 `src/test/<feature>_test/` 下新建 blackbox test 包，并复用 `capture_backend` override。
2. 用 `@capture_app.init_app(...)` 初始化测试 App，挂上 `@plugins.default_plugin` 和被测系统。
3. 测试里直接读取本地 `assets/...json`，并传给游戏模块解析；不要为了测试去改正式资源加载链路（例如 `src/lib/resource/load.mbt`）。
4. 让“测试注入”和“正式流程”复用同一份解析函数，避免双份解析逻辑。
5. 固定画布尺寸、UI 位置、输入和帧推进次数，保证快照稳定可复现。
6. 调用 `@capture_app.snapshot(".../__snapshot__/xxx.png")` 产出或比对 PNG。
7. 每次(重新)生成图片, 都要查看生成的快照图片, 确保与预期一致.

## Coding Style

### 文档/注释

所有 public 函数/类型/变量都要写接口注释.

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

### 禁止 fallback

除非必要, 否则不要写 fallback 逻辑, 干扰问题排查. 可以在函数返回值后加`raise`关键词, 让错误继续往上传播.

### Sprite

使用 selene 的 `@sprite.Sprite` 渲染画面. 游戏的渲染层级比较多, z index 集中放在 `src/lib/graphics/z_index.mbt` 里管理.

### 资源

资源放在 `./assets` 目录下, 目前还没提交到 git 仓库, 暂时用 `.gitignore` 忽略了, 等资源格式和组织方式确定/稳定后, 再提交到 git 仓库.

详情阅读 [builtin_resource_loaders.mbt](src/lib/resource/builtin_resource_loaders.mbt) 和 [AGENTS.md](src/lib/resource/AGENTS.md).

### 地图资源

地图资源通常位于 `assets/map/mapX/YYYYYYY.img.json`, 结构参考[文档](./src/lib/ms/map/README.mbt.md).

### 解析 nx 资源

nx 资源以 JSON 格式存储. 导入到游戏时, 可以定义 MoonBit struct , 并实现 `FromJson` 接口来解析数据.
这些 struct 类型以 `Nx` 开头, 例如 `NxTexture` .
