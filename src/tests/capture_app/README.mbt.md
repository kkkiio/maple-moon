# capture_app

用于对 `selene` 后端离屏渲染产出的 PNG bytes 做快照断言。

测试调用 `@capture_app.capture_after_frames` 产出 `FrameCaptureArtifact`，再把需要
检查的 PNG bytes 传给 `snapshot`。

`capture_after_frames` 基于 Selene 的 `OffscreenCapture` graphics test API：
它会初始化 WebGPU runtime，等待已 preload 的渲染资源 ready，挂载 capture plugin，
启动 `app.run()`，并在严格帧数上返回截图 artifact。

## 快照断言

- `@capture_app.snapshot(path, png, visual_desc="...")`:
  对比 PNG bytes 与磁盘快照。`visual_desc` 仅保留为调用侧描述参数，不触发外部 AI 校验。
  当 `UPDATE_CANVAS_SNAPS=true` 或快照文件不存在时写入快照；不一致时写入 `.wrong.png` 并让测试失败。

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
  visual_desc="A panel with title text is visible at top-left.",
)
```

## WebGPU 测试

渲染快照测试使用 WebGPU 后端和 Headless Chrome wrapper。默认命令会自动扫描
`src/tests` 下调用 `@capture_app.snapshot(` 的测试包：

```bash
npm run test:webgpu
node scripts/moon-webgpu-test.mjs --list
```

需要只跑某个包时，显式传入路径：

```bash
npm run test:webgpu -- src/tests/<feature>_test
```
