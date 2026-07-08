# markup_text

负责解析 Maple 对话文本中的通用标记（颜色、粗体、下划线、引用标签等），并提供引用名称解析。

## 运行时约束

- 进入游戏场景后，应先调用 `@markup_text.preload_reference_data()` 预加载字符串资源。
- 渲染阶段只允许调用 `resolve_*` 读取已加载数据；未预加载会抛错。

## API

```moonbit nocheck
@markup_text.preload_reference_data()
if !(@markup_text.is_reference_data_ready()) {
  fail("reference data is not ready")
}

let npc_name = @markup_text.resolve_npc_name("1012101"[:])
let mob_name = @markup_text.resolve_mob_name("2220100"[:])
let map_name = @markup_text.resolve_map_name("105040300"[:])
let item_name = @markup_text.resolve_item_name("4031006"[:])
```

`Style` 会跟踪颜色、粗体和下划线状态，供 HTML 输出或游戏内富文本渲染复用。

## 错误行为

- `resolve_*` 在以下情况会 `raise`：
  - 未预加载引用数据。
  - id 非法。
  - 路径或名称字段不存在。
- 不提供 fallback，避免掩盖资源问题。
