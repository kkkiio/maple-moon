# keymap

`keymap` 是 Maple Moon 的逻辑输入边界。游戏代码只查询 `Action`，物理设备绑定由
Selene `input_action` 同时保持激活，因此键盘、任意已连接手柄和未来的触摸虚拟按键
可以共同驱动同一个动作。

逻辑动作分为三组：

- `BASIC`：移动、跳跃、攻击和交互。
- `QUICK_SLOT`：四个紧凑的技能/物品槽；槽位内容与物理按键分离。
- `UI`：取消、切换页签和打开面板。

`InputMethod` 记录最近一次有意义的输入，只用于按键提示、焦点策略和震动路由。它不
关闭其他设备。按键会立即切换设备；摇杆需要先回到 `0.25` 内，再跨过 `0.55` 才会
切换，避免漂移或一直推住的摇杆抢回当前设备。触摸处于活动中时，浏览器生成的兼容
鼠标事件不会把设备切回键鼠。

Gameplay 查询由一组具名 modal owner 共同门控，UI 查询始终可用。这个门控位于
`keymap` 查询边界，所以 Update 和 FixedUpdate 中的直接查询遵守同一规则。

映射、快捷槽、modal owner、当前输入设备和设备切换的迟滞状态都归当前 ECS `World`
所有。无 `world` 参数的查询与配置 API 通过 `require_current_world` 定位运行时；
`input_method_system(world)` 使用调度器传入的 World。模块只保留一个输入设备变更事件
总线，Selene `Events` 会将同一总线的队列和 reader cursor 按 World 隔离。因此测试、
预览场景和并行 App 可以安装不同映射，不会共享快捷槽或 UI 门控状态。

默认物理映射由 `default_keymap` 定义并由 `game_scene` 安装；默认快捷槽内容属于职业
配置，继续由 `game_scene` 持有和安装。

## 可执行示例

```mbt check
///|
test "install device-neutral bindings" {
  let jump = @keymap.Action::BASIC(@keymap.BasicActionId::JUMP)
  let mapping : @keymap.Keymap = Map([
    (
      jump,
      [
        @input_action.InputBinding::Key(@inputs.Code::Space),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::South,
        ),
      ],
    ),
  ])
  @keymap.set_keymap(mapping)
  inspect(@keymap.get_bindings(mapping, jump).length(), content="2")
}

///|
test "configure compact quick slots" {
  @keymap.set_quick_slots(
    Map([
      (@keymap.QuickSlotId::SLOT_1, @keymap.QuickSlotContent::Skill(3101005)),
      (@keymap.QuickSlotId::SLOT_2, @keymap.QuickSlotContent::Item(2000000)),
    ]),
  )
  debug_inspect(
    @keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_1),
    content="Some(Skill(3101005))",
  )
}

///|
test "modal owners compose" {
  @keymap.set_gameplay_input_suppressed("inventory", true)
  @keymap.set_gameplay_input_suppressed("npc_talk", true)
  inspect(@keymap.gameplay_input_enabled(), content="false")
  @keymap.set_gameplay_input_suppressed("inventory", false)
  inspect(@keymap.gameplay_input_enabled(), content="false")
  @keymap.set_gameplay_input_suppressed("npc_talk", false)
  inspect(@keymap.gameplay_input_enabled(), content="true")
}
```
