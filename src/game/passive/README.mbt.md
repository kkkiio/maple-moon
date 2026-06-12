# Passive Skill System

被动技能系统，实现追加攻击（Final Attack）等被动效果。

## 架构

使用 ECS 事件队列模式：

1. **CombatSystem** 在攻击命中后生成 `HitEvent` 并入队
2. **PassiveSystem** 每帧消费事件队列并构造 `PassiveContext`
3. **FinalAttackPassive** 检查条件并触发追加攻击

## 关键设计

- **防止递归**：`HitSource::UserInput` vs `HitSource::Passive(Int)`
- **武器匹配**：`SWORD_FA_FIGHTER` 只在 `SWORD_1H` 攻击时触发
- **概率判定**：使用 `stats.prop` 字段（*100 表示百分比）
- **上下文注入**：通过 `PassiveContext` 注入共享随机源、角色查询和追加攻击触发接口

## 使用

在 game_scene 中注册终极剑技能：

```moonbit nocheck
// 注册终极剑
let fa_skill = @combat_system.load_skill_move(
  @skill.SkillId::SWORD_FA_FIGHTER.int_value(),
  bullet_module,
)
@combat_system.register_move(fa_skill)
```

在游戏主循环中调用 passive_system：

```moonbit nocheck
.add_system(@passive.passive_system, system_name="passive")
```
