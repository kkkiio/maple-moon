# `indexed_db`

一个通用的 JSON Key-Value 存储抽象，当前提供：

- 浏览器 `IndexedDB` 实现。

## 用法

```moonbit nocheck
let db = @indexed_db.open("MyDB", 1, ["characters", "ui_prefs"])

db.save_json("characters", "1", {
  "map_id": 100000000,
})
let loaded = db.load_json("characters", "1")
```
