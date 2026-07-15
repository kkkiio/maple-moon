# capture_app

用于对 `selene` native raylib 后端离屏渲染产出的 PNG bytes 做快照断言。

测试调用 `@capture_app.capture_after_frames` 产出 `FrameCaptureArtifact`，再把需要
检查的 PNG bytes 传给 `snapshot`。

`capture_after_frames` 会复用测试进程内的 hidden raylib window 提供 OpenGL context，
调用 `App::run_frames_capture` 跑固定帧数，并只返回目标帧的截图 artifact。

## 快照断言

- `@capture_app.snapshot(path, png)`:
  对比 PNG bytes 与磁盘快照。当 `UPDATE_GRAPHICS_SNAPS=true` 或快照文件不存在时写入快照；
  不一致时写入 `.wrong.png` 并让测试失败。

  **注意**：`UPDATE_GRAPHICS_SNAPS=true` 仅用于新增测试的首次 baseline 写入，或经人眼确认 `.wrong.png` 正确的预期视觉变化。严禁用该变量消除未诊断的 pixel mismatch。

```mbt nocheck
let capture = @capture_app.capture_after_frames(
  app,
  3,
  width=800,
  height=600,
  raw_delta=0.016,
)
@capture_app.snapshot(
  "src/graphics_test/__snapshot__/example/demo.png",
  capture.png,
)
```

## 迁移约束

目录重构时，`__snapshot__/` 下的 PNG baseline 必须原样移动到新路径，不得使用 `UPDATE_GRAPHICS_SNAPS=true` 重新生成。迁移完成后必须在不设该变量的情况下复跑所有测试确认通过。

## Native 图形测试

渲染快照测试使用 native raylib 后端。运行 `src/graphics_test` 包：

```bash
npm test
just test
```

需要更新 PNG baseline 时：

```bash
MOONBIT_NEW_NATIVE=1 UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --diagnostic-limit 200 src/graphics_test
```
