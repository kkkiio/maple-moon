# capture_app

用于在 Node.js 测试环境中驱动 `selene` 渲染循环并做 PNG 快照断言。

## 快照断言

- `@capture_app.snapshot(path, visual_desc="...")`:
  仅在快照更新模式下触发语义校验（`UPDATE_CANVAS_SNAPS=true` 或首次生成快照文件）。
  会调用视觉模型判断截图是否符合 `visual_desc` 描述；不满足预期时测试失败。

语义校验需要 `OPENROUTER_API_KEY` 环境变量；缺失时测试会失败。

```mbt nocheck
@capture_app.snapshot(
  "src/test/example/__snapshot__/demo.png",
  visual_desc="A panel with title text is visible at top-left.",
)
```
