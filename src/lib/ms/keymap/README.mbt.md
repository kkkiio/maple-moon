# keymap

统一定义输入动作模型（`Action`）与按键映射状态（`Keymap`）的 package。

当前约束是：运行时输入查询统一走 `keymap`（`is_pressed` / `is_just_pressed`），其他模块（例如 `controller` / `player`）只使用 `Action` / `BasicActionId`。

已提供：

- 基础动作枚举 `BasicActionId`（移动/跳跃/攻击/拾取）
- 动作枚举 `Action`（`BASIC` / `SKILL(skill_id)` / `ITEM(item_id)`）
- 映射状态接口 `set_keymap` / `get_keymap`
- 按动作查询接口 `is_pressed` / `is_just_pressed`
- 动作列表接口 `pressed_actions` / `just_pressed_actions`

默认映射由场景侧（`game_scene`）定义并在游戏开始时初始化，`keymap` 不关心默认配置内容。

## 可执行示例

```mbt check
///|
test "set and get keymap" {
  let mapping : @keymap.Keymap = {}
  @keymap.set_keymap(mapping)
  inspect(@keymap.get_keymap() is Some(_), content="true")
}

///|
test "collect actions with empty mapping" {
  let mapping : @keymap.Keymap = {}
  inspect(
    @keymap.get_action(mapping, @inputs.Code::ArrowUp),
    content="None",
  )
}

///|
test "query mapped action" {
  let mapping : @keymap.Keymap = Map::from_array([
    (
      @inputs.Code::ArrowUp,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP),
    ),
  ])
  inspect(
    @keymap.get_action(mapping, @inputs.Code::ArrowUp),
    content=
      "Some(BASIC(MOVE_UP))",
  )
}
```
