---
name: write-snapshot-test
description: 为 Maple Moon 编写数据或图形快照测试。用于新增或修改采用 `@debug.debug_inspect`、`json_inspect`、`@capture_app.snapshot` 的黑盒测试，选择有业务含义的观察对象，并保证数据快照先于图片快照。
---

# Write Snapshot Test

## 编写流程

1. 确定被测行为及最接近的现有黑盒测试。纯逻辑测试放在源码 package；图形测试放在 `src/graphics_test/`。
2. 选择能直接解释该行为的观察对象。
3. 复用相邻测试的 App、plugin、资源挂载和 capture 方式，写出最小完整场景。
4. 运行对应测试，审查生成的数据与图片候选 baseline。

## 选择观察方式

| 原语 | 选择条件 |
|---|---|
| `@debug.debug_inspect(value)` | 值具有稳定、可理解的 `Debug` 表示 |
| `json_inspect(value)` | 值本身是 JSON，或 `ToJson` 表示具有业务含义 |
| `@capture_app.snapshot(path, png)` | 行为需要验证最终渲染输出 |

- 优先观察函数的完整返回值、现有领域对象，或命名清楚且可复用的诊断投影。
- 多个值共同描述一个领域结果时组成一个快照。互不相关的观察值保持独立，不为合并标量、断言或计数器临时构造 JSON object。
- 普通断言只表达能从规格或不变量独立推导出的 expected，不把运行产生的结果抄成断言。
- 多个测试复用 setup 或 capture 代码时，让复用代码返回诊断对象；在每个测试自己的唯一调用点执行 inspect。
- 图形测试优先从 capture metadata 投影实际提交的 sprites/draws，保留资源路径、source/destination rect、layer、颜色、翻转和位置等有解释力的字段。

## 图形测试形状

```moonbit
@debug.debug_inspect(render_parts)
let capture = @capture_app.capture_after_frames(
  app,
  1,
  width=200,
  height=200,
)
@capture_app.snapshot(
  "src/graphics_test/__snapshot__/feature_name/scene.png",
  capture.png,
)
```
