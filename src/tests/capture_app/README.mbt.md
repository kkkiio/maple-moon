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

```mbt nocheck
let capture = @capture_app.capture_after_frames(
  app,
  3,
  width=800,
  height=600,
  raw_delta=0.016,
)
@capture_app.snapshot(
  "src/tests/example/__snapshot__/demo.png",
  capture.png,
)
```

## Native 图形测试

渲染快照测试使用 native raylib 后端。默认命令运行 `src/tests` 下的测试包：

```bash
npm test
just test
```

需要更新 PNG baseline 时：

```bash
MOONBIT_NEW_NATIVE=1 UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --diagnostic-limit 200 src/tests/<feature>_test
```
