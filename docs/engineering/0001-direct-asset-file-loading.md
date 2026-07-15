# Direct Asset File Loading

## Context

Maple Moon 使用三种资源格式：

- **Aseprite 动画**（`.json` + `.png` spritesheet）
- **Tiled 地图**（`.tmj` + `.tsj`）
- **NX 位图动画**（从原版 NX 文件提取的 `.img.json` 容器 + 独立帧）

之前的加载方案模仿 NX 的 `DirResourceLoader`（按第一个 `/` 拆分成 `$name.json` 容器 + 内部导航），并通过 `AsyncLoader` trait / `source` 注册机制统一不同资源类别的加载方式。

在实践中这个抽象层带来了几个问题：

1. **资源格式不统一**：Aseprite、Tiled、NX 三种资源的加载方式差异太大，没有哪种 loader 抽象能有效统一它们。`DirResourceLoader` 的"文件内导航"假设对 Aseprite/Tiled 的独立文件导出不适用。
2. **中间层增加复杂度而不提供价值**：source/registry 机制在资源路径上增加了一层间接映射，排查问题时需要追踪 `"item"` → `CompositeAsyncResourceLoader` → `DirResourceLoader("assets/Item/Consume")` 的链路。
3. **导出格式迁移时的摩擦**：当资源从 NX 容器格式迁移为独立文件时，`DirResourceLoader` 的错误假设导致"找不到文件"的问题。
4. **实际上没有异步**：`AsyncLoader` 名字中的 "Async" 是从早期 Web 版本遗留下来的，native backend 已不再使用。

## Decision

**废弃统一的 loader 抽象层，改为直接按文件路径 + JSON 路径加载资源。**

具体决定：

### 1. 删除 AsyncLoader/AsyncResourceLoader 抽象层

不再有 `AsyncLoader` struct、`AsyncResourceLoader` trait、`DirResourceLoader`、`CompositeAsyncResourceLoader`。这些类型和相关的 source/registry 机制全部删除。

### 2. 使用显式 `assets/...` 路径

所有资源加载直接走 Selene 的 asset API，游戏代码使用 `require_json("assets/foo/bar.json")` 或 `require_image("assets/foo/bar.png")`，路径包含 `.json` 后缀。

### 3. `json_navigate` 处理容器 JSON

对于仍保留 NX 容器格式的 `.img.json` 文件（如 `assets/Skill/MobSkill.img.json`），使用 `json_navigate(path, keys)` 在文件内部导航到具体数据节点。

### 4. AnimationLoader 简化

`AnimationLoader` 不再接受 `AsyncLoader` 参数，内部直接调用 `require_json` 加载动画 JSON、`require_image` 加载图集 PNG。

### 5. 保留原有的 `assets/...` 路径规范

- 不使用 `/assets/...` 前缀
- 三种路径上下文不变：source-relative、file-relative（`mx_animation` 引用）、resolved（`assets/...`）
- `resolve_ref(base, ref)` 保留，用于处理相对引用

### 6. `FileJsonResourceLoader` 作为独立文件加载器

替代 `DirResourceLoader`。对于已导出为独立 JSON 文件的数据源，直接按文件路径加载，不假设"文件内导航"结构。

## Consequences

- 游戏代码中的资源路径一目了然：可以看到具体加载哪个文件、在文件中的哪个路径取数据。
- 排查路径问题时不再需要追踪 loader 注册链路。
- 不同资源类型（Aseprite、Tiled、NX）各自使用最直接的加载方式，不需要适配统一的 loader 接口。
- 测试不再需要 mock loader，直接使用 Selene asset API 即可访问本地文件。
- `AnimationLoader` 的调用方式更简单：`AnimationLoader::load(resolved_path)` 而非先构造实例再调用。

## Alternatives Considered

- **保留 loader 抽象层并修复兼容性**。被拒绝，因为三种资源类型的加载逻辑差异太大，统一抽象不提供实际价值，反而增加了调试和理解成本。
- **引入新的资源类型系统（`AssetPath` 类型等）**。推迟，当前用字符串路径已经能满足需求，类型化路径可以等资源体系更稳定后再设计。
