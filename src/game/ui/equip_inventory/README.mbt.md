# equip_inventory

## equip_inventory_system

消费 `item_use_events` 队列，并在这里执行装备/使用道具请求。

- `TryEquip`: 读取玩家状态、执行 `can_wear_equip` 判定，成功后发 `MoveItemMessage`。
- `TryUse`: 校验槽位后发 `UseItemMessage`。

该包是上层业务编排层，避免把玩家状态判定写回 `inventory`。

```moonbit nocheck
@system.App::new()
.add_system(@equip_inventory.equip_inventory_system, system_name="equip_inventory_system")
```
