# Skill Package

技能数据管理与加载模块。

## 架构

参考 Item Package 设计，采用两级缓存机制：

- **Bundle Cache**: 按职业分组缓存原始 JSON（如 `0100.img` 包含所有战士技能）
- **Skill Cache**: 单个技能数据缓存

## 使用方式

### 1. 异步加载单个技能

```moonbit nocheck
// 首次加载会从网络获取，后续从缓存读取
let skill_data = await @skill.load_skill(1001004) // 强力攻击
```

### 2. 同步获取已缓存技能

```moonbit nocheck
// 运行时获取，不阻塞
match @skill.get_cached_skill(1001004) {
  Some(data) => { /* use data */ }
  None => { /* skill not loaded yet */ }
}
```

### 3. 批量预加载（推荐）

```moonbit nocheck
// 角色创建时预加载该职业所有技能
let skill_ids = job.get_all_skills()
await @skill.preload_skills(skill_ids)
```

## 与旧代码兼容

`SkillData::load()` 仍然可用，内部使用新的缓存机制：

```moonbit nocheck
// 旧代码无需修改
let data = await @skill.SkillData::load(1001004)
```

## 主要改进

1. **Bundle 级缓存**: 同职业技能共享 bundle 文件，减少网络请求
2. **同步获取接口**: `get_cached_skill()` 支持运行时无阻塞访问
3. **批量预加载**: `preload_skills()` 支持角色创建时预加载
4. **纯数据结构**: `SkillData` 不含闭包，可缓存和测试

## 文件结构

```
skill/
├── data.mbt           # SkillData 结构定义
├── skill_loader.mbt   # 加载逻辑与缓存
├── skill_id.mbt       # 技能 ID 枚举
└── README.mbt.md      # 本文档
```
