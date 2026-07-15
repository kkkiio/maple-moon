# LRU Cache

提供一个轻量的容量限制缓存。内部使用 `Map` 保存条目，并通过删除后重新插入来维持最近访问顺序。

约束：

- `Cache::new` 的键类型需要满足 `Eq + Hash`。
- `capacity` 必须为正数；传入非正数会触发 `abort`。
- 缓存只做容量淘汰，不负责资源生命周期释放。

## 使用示例

```moonbit nocheck
let cache : @lru_cache.Cache[String, Int] = Cache(2)
cache.set("a", 1)
cache.set("b", 2)
inspect(cache.get("a"), content="Some(1)")
cache.set("c", 3)
```
