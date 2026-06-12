# Skill Cast System

`skill_cast` 负责**施法流程与时序**。

核心职责:

- 施法入口：`use_move`。
- move 注册与查询：`register_move` / `get_skill_move` / `load_skill_move`。
- 施法前置编排：选择 `SpecialMove`、角色状态与武器前置检查、禁止施法返回。
- 施法触发时调用 `combat_system` 执行战斗结算。

对外 API:

- `move_map`
- `register_move`
- `get_skill_move`
- `load_skill_move`
- `use_move`
- `check_attack_type`
- `can_use_regular_attack`

与 `combat_system` 的边界:

- `skill_cast` 负责“何时、能否、以何种动作发起施法”。
- `combat_system` 负责“攻击规则与结算真相”。
- `skill_cast` 不计算伤害公式，不执行命中结算。

## 接入示例

```moonbit nocheck
let move = await @skill_cast.load_skill_move(1001004)
@skill_cast.register_move(move)

// 运行时触发
@skill_cast.use_move(player, 1001004)
```
