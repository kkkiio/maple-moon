# `ms/inventory_ui`

背包 UI 渲染与交互模块。

## 交互语义（当前）

- 单击槽位：进入激活态（高亮边框）。
- 再次单击同一槽位：触发 `use_item_at_slot` 并清空激活态。
- 单击其他槽位：切换激活态。
- 单击空白 / 切换 tab / 关闭背包 / 场景清理：清空激活态。

## 主要入口

- `init_inventory_ui`
- `bind_inventory`
- `set_inventory_visible`
- `inventory_ui_system`
