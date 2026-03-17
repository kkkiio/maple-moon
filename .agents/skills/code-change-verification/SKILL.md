---
name: code-change-verification
description: 在完成 MoonBit 代码修改后执行一致性校验：运行 `moon info`，检查暴露的 public symbol/API 是否符合预期，并核对受影响 package 的 `README.mbt.md` 是否同步更新。用于重构、改签名、增删 public API、或任何可能影响对外接口与文档的改动。
---

# Code Change Verification

在代码改动后，按以下固定流程执行并汇报。

## 1. 收集改动范围

先识别本次改动涉及哪些 package 与文档：

```bash
git status --short
git diff --name-only
```

重点关注：

- `pkg.generated.mbti` 是否变化
- 对应 package 的 `README.mbt.md`

## 2. 运行 `moon info`

在仓库根目录执行：

```bash
moon info
```

如果 `moon info` 失败，先报告阻塞点，不跳过后续核对结论。

## 3. 校验 public symbol/API

对每个受影响 package，确认对外接口是否与预期一致：

1. 查看 `pkg.generated.mbti` 是否出现新增/删除/改签名。
2. 与本次需求目标比对：
- 应该暴露的符号是否已暴露。
- 不应变化的 API 是否被意外改动。
- 改动是否是预期破坏性变更（breaking change）。
3. 若发现不一致，明确指出文件与符号名。

推荐命令：

```bash
git diff -- src/lib/**/pkg.generated.mbti
rg -n "pub " src/lib/<package>
```

## 4. 校验 README.mbt.md 同步

对每个 API 或行为发生变化的 package，检查 `README.mbt.md`：

1. 是否仍描述旧签名/旧行为。
2. 示例代码是否与当前 API 一致（尤其 `set_context`、构造函数参数、返回类型）。
3. 至少保留一个最小可用示例（按项目约定使用 `mbt check` 或 `moonbit nocheck`）。

若 README 未同步，直接补齐并在结果中列出修改路径。

## 5. 输出结论

汇报必须包含：

1. 执行结果：`moon info` 是否通过。
2. API 校验结论：预期变更/意外变更列表。
3. README 同步结论：哪些 package 已同步，哪些仍缺失。
4. 风险项：若存在 breaking change 或文档漂移，明确给出文件路径与符号。

除非用户明确要求，不做 fallback 兼容逻辑；发现问题优先暴露并说明。
