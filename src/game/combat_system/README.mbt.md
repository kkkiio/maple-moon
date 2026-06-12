# Combat System

`combat_system` 负责**战斗规则与结算真相**。

核心职责:

- 构建攻击数据并解析技能攻击语义（范围、目标数、伤害段数等）。
- 根据规则执行目标选择、命中判定与伤害结算。
- 计算并产出确定性的战斗结果（伤害、异常状态、命中结果）。
- 输出可被表现层消费的战斗事件数据（例如受击、子弹命中回调所需结果）。

非职责:

- 不负责施法生命周期与输入时序编排（由 `skill_cast` 负责）。
- 不直接管理施法状态机（前摇/开火/后摇）。

已迁出到 `skill_cast` 的能力:

- `use_move`
- `register_move`
- `get_skill_move`
- `load_skill_move`
- `move_map`
- `check_attack_type`
- `can_use_regular_attack`

## 接入示例

```moonbit nocheck
let regular = @combat_system.new_regular_attack(@weapon.Type::SWORD_1H)
@combat_system.register_move(regular)

// 由 skill_cast 在时序层调用
@skill_cast.use_move(player, regular.skill.id)
```
