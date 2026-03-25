# Console

通用调试控制台（与业务模块解耦）。

`console` package 只提供注册机制与全局绑定，不直接依赖 `ms` 游戏模块。

## Public API

- `register_state_section`
- `register_ui_provider`
- `register_command`
- `install`

## Runtime Globals

调用 `@console.install()` 后会挂载：

```js
globalThis.render_game_to_text();
$console.help();
$console.ui.list();
$console.ui.click("select_char.new_character");
await $console.step(20);
$console.cmd("meso", "1000000");
$console.cmd("item", "1302007", "1");
$console.cmd("warp", "100000000", "0");
```
