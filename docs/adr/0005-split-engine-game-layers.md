# ADR 0005: Split Engine and Game Layers

Date: 2026-06-12

Status: Accepted, implemented

## Context

Before this decision, `src/lib/` contained two kinds of code:

- **引擎/框架层**：`game_app`、`game_server`、`graphics`、`ui`、`resource`、`local_server`、`console`、`log`、`utils` 等
- **游戏层**：`lib/ms/` 下的 ~50 个子包，对应 MapleStory 游戏逻辑

两层都放在 `lib/` 下，视觉上平级，但语义上有明确的上下依赖关系（引擎不应依赖游戏）。当时已经存在违规：`lib/resource`（引擎）→ `lib/ms/res_types`（游戏）。

## Decision

将 `lib/` 拆分为两个平级目录：

```
src/
  apps/                     ← 不变
  engine/                   ← 引擎/框架层
    game_app/ game_server/ game_scene/ game_state/
    graphics/ ui/ local_server/ resource/ console/
    log/ utils/ io_service/ randx/ fsx/ lazy/
    legacy_types/ data_sheet/ indexed_db/
  game/                     ← 游戏逻辑（原 lib/ms/ 的内容）
    combat_system/ monster/ character/ skill/
    inventory/ quest/ map/ physics/
    ...  (~50 个子包)
  tests/                    ← 不变
```

分层规则：

- `src/engine/` 内的包**禁止** import `src/game/` 内的包
- `src/game/` 内的包可以 import `src/engine/` 和 `src/game/` 内的其他包

## Migration

1. `git mv src/lib src/engine`
2. 从 `engine/` 中移出 `ms/`：`git mv src/engine/ms src/game`
3. 全局替换 import 路径：`KKKIIO/maple-moon/lib/` → `KKKIIO/maple-moon/engine/`，`KKKIIO/maple-moon/lib/ms/` → `KKKIIO/maple-moon/game/`
4. 处理 `res_types`：`lib/resource` import 了 `lib/ms/res_types`。方案：将 `res_types` 提升到 `engine/res_types`，或将其内容合并到 `engine/resource/` 中
5. 更新 `AGENTS.md` 中的目录描述
6. 全部测试通过后合并

## Consequences

- 分层规则由目录结构强制执行，新人在 `engine/` 下写代码时不会意外 import 游戏逻辑
- 所有 import 路径变更，是一次性全局改动
- `engine/` 和 `game/` 平级，比 `lib/ms` 嵌套更清晰地表达了"引擎不依赖游戏"
- 未来如果抽象出通用引擎组件，可以直接将 `engine/` 下的包提取为独立仓库

## Alternatives Considered

- **方案 A：只把 `ms/` 改名为 `gameplay/`**。改动小，但不解决分层模糊问题，引擎和游戏仍然同在 `lib/` 下
- **方案 C：保持现状，只靠文档约束依赖方向**。零改动成本，但编译器不 enforce 规则，依赖方向随时间推移会逐渐退化
