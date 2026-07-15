# Utils

通用小工具包，提供计数、双向映射、默认值映射、时间辅助、字符串辅助等基础能力。

约束：

- `BiMap(...)`、`Counter(...)`、`DefaultMap(...)` 使用 `Map` 存储键，因此键类型需要满足 `Eq + Hash`。
- 这些工具不负责业务语义校验；调用方应在业务 package 内处理非法状态。

## 使用示例

```moonbit nocheck
let counter : @utils.Counter[String, Int] = Counter()
counter["mob"] = counter["mob"] + 1

let defaults : @utils.DefaultMap[String, Int] = DefaultMap(fn() { 0 })
inspect(defaults["missing"], content="0")

let map : @utils.BiMap[String, Int] = BiMap()
map.set("warrior", 100)
inspect(map.get_forward("warrior"), content="Some(100)")
```
