# capture_app

用于在 Node.js 测试环境中驱动 `selene` 渲染循环并做 PNG 快照断言。

## 快照断言

- `@capture_app.snapshot(path)`:
  保持原有行为，按 PNG bytes / 像素一致性做断言。
- `@capture_app.snapshot(path, expect="...")`:
  仅在快照更新模式下触发语义校验（`UPDATE_CANVAS_SNAPS=true` 或首次生成快照文件）。
  会调用 OpenRouter 的 `google/gemini-3.1-flash-lite-preview`，判断截图是否符合 `expect` 描述。

语义校验需要 `OPENROUTER_API_KEY` 环境变量；缺失时测试会失败。

```mbt nocheck
@capture_app.snapshot("src/test/example/__snapshot__/demo.png")

@capture_app.snapshot(
  "src/test/example/__snapshot__/demo.png",
  expect="A panel with title text is visible at top-left.",
)
```
