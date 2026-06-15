# Console

通用调试控制台（与业务模块解耦）。

`console` package 只提供注册机制与全局绑定，不直接依赖 `ms` 游戏模块。

## Public API

- `register_state_section`
- `register_ui_entity`
- `unregister_ui_entity`
- `list_ui_entries`
- `click_registered_ui`
- `clear_input_injection`
- `console_input_injection_system`
- `register_command`
- `install`

## Integration

`$console.ui.click(...)` 会直接向 Selene UI click event bus 发送注册实体的点击事件。
`console_input_injection_system` 仍可注册到 `First` 调度，用于未来需要模拟指针状态的调试入口。

## Runtime Globals

调用 `@console.install()` 后会挂载：

```js
globalThis.render_game_to_text();
$console.help();
$console.ui.list();
$console.ui.click("quest_log", "tab.completed");
await $console.step(20);
$console.cmd("meso", "1000000");
$console.cmd("item", "1302007", "1");
$console.cmd("warp", "100000000", "0");
```
