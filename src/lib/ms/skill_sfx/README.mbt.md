# Skill SFX

技能音效管理模块。

职责：

- 把技能 ID 映射成当前项目的技能音效资源路径
- 播放 `Use` / `Hit` 两类短音效
- 提供仅测试使用的事件读取能力，便于黑盒测试断言音效时序

当前固定路径规则：

- `assets/sound/Skill.img/<skill_id>/Use.mp3`
- `assets/sound/Skill.img/<skill_id>/Hit.mp3`

当前不做资源存在性预检查，不做 manifest，也不做多目标 `Hit` 去重。

## 接入示例

```moonbit nocheck
@skill_sfx.play_skill_use(1001004)
@skill_sfx.play_skill_hit(1001004)
```
