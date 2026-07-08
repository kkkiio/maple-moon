# `indexed_db`

一个通用的 JSON Key-Value 存储抽象，当前提供：

- 同步 JSON Key-Value API。
- JS 后端使用 `localStorage` 命名空间保存数据。

## 用法

```moonbit nocheck
let db = @indexed_db.open("MyDB", 1, ["characters", "ui_prefs"])

db.save_json("characters", "1", {
  "map_id": 100000000,
})
let loaded = db.load_json("characters", "1")
```
