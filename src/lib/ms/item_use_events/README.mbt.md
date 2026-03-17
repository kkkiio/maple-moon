# item_use_events

负责缓存“使用背包槽位”的短生命周期意图事件。

- `inventory` 侧只负责入队。
- 上层系统（如 `equip_system`）每帧 `drain` 并消费。
- 队列在 `drain` 后自动清空，不保留历史。

## 示例

```moonbit nocheck
@item_use_events.push_intent(
  TryEquip(type_id=EQUIP, slot_no=1, item_id=1302000),
)

for intent in @item_use_events.drain_intents() {
  match intent {
    TryEquip(..) => ...
    TryUse(..) => ...
  }
}
```
