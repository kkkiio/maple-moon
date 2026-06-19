---
name: project-change-verification
description: 在完成 Maple Moon 代码或资源改动后执行一致性校验：运行 `moon info`，检查 public API 与 README.mbt.md 是否同步，并在改动影响运行时代码、资源、Web 入口、构建配置或用户要求地图/资源/浏览器验证时，委托 `$maple-cli` 执行浏览器客户端验证。
---

# Project Change Verification

在代码或资源改动后，按以下流程执行并汇报。不要用 fallback 兼容逻辑掩盖失败；发现问题时直接报告阻塞点、失败输出和残留风险。

## 1. 收集改动范围

在仓库根目录执行：

```bash
git status --short
git diff --name-only
```

重点识别：

- MoonBit package 是否受影响。
- `pkg.generated.mbti` 是否变化。
- 对应 package 的 `README.mbt.md` 是否需要同步。
- 是否需要委托 `$maple-cli` 做运行时验证。

## 2. 运行 `moon info`

执行：

```bash
moon info
```

如果 `moon info` 失败，先报告阻塞点；仍继续完成能做的 API、README、Maple CLI 触发判断。

## 3. 校验 public API

对每个受影响 package：

1. 查看 `pkg.generated.mbti` 是否新增、删除或修改 public symbol/signature。
2. 判断变化是否符合本次需求。
3. 明确列出意外变化、breaking change 或不该暴露的 symbol。

推荐命令：

```bash
git diff -- '**/pkg.generated.mbti'
rg -n "pub " <affected-package-path>
```

如果 diff 只是 `moon info` 产生的无意义末尾空行，要说明不是 API 变化，并在合适时去掉噪音。

## 4. 校验 README.mbt.md 同步

对每个 API 或行为变化的非 main package，检查对应 `README.mbt.md`：

1. 是否仍描述旧签名或旧行为。
2. 示例代码是否与当前 API 一致。
3. 是否至少保留一个最小可用示例。

Main package 使用 `README.md`；不要要求它提供 `README.mbt.md`。

## 5. Maple CLI Runtime Verification Delegation

这是条件可选步骤，不是随意跳过。

### 必须执行

满足任一条件时执行：

- 修改了 MoonBit 运行时代码：`src/engine/**`、`src/game/**`、`src/apps/game_web/**`、`src/cmd/**`。
- 修改了运行资源：`assets/**`。
- 修改了 Web 入口或构建/加载路径：`index.html`、`moon.mod`、`moon.pkg`、`vite.config.mjs`、`package*.json`、`justfile`。
- 用户明确要求验证地图、资源加载或浏览器运行状态。

### 可以跳过

仅在以下情况跳过，并必须汇报原因：

- 纯文档改动，且不影响资源或运行流程。
- 只改 README、ADR、注释，且没有代码或资源行为变化。
- 本地缺少 Chrome、Node native `WebSocket`、Vite 无法启动等外部前置条件。报告为 `blocked/skipped with reason`，不要静默跳过。

### 委托规则

- 触发时使用 `$maple-cli` 执行浏览器客户端验证。
- 默认场景是 Victoria/Henesys：map id `100000000`，portal id `0`。
- 如果改动能明确映射到具体地图资源，要求 `$maple-cli` 优先验证对应 map id。
- 如果多个地图资源被改动，最多选择 3 个代表地图，并说明选择依据。
- 不在本 skill 中维护具体 CLI 参数、debug 命令或排障命令；这些细节属于 `$maple-cli`。

## 6. 输出结论

汇报必须包含：

1. `moon info` 是否通过。
2. public API 检查结论：新增、删除、签名变化，或明确“无变化”。
3. README 同步结论：已同步、无需同步，或缺失路径。
4. Maple CLI 验证结论：
   - 是否触发。
   - 是否已委托 `$maple-cli`。
   - 验证了哪些 map id / portal id。
   - `maple wait-ready` / `maple cmd warp` / `maple network --failed` / `maple logs --level error` 等命令是否通过。
   - 是否存在 failed network 或 browser console error。
   - 若跳过，给出具体原因。
5. 残留风险：例如快照测试失败、外部服务缺失、资源闭包仍不确定等。

Maple CLI 验证不替代 `just check`、`just fmt`、`just test`、`just build`；它是资源与浏览器运行时补充验证。
