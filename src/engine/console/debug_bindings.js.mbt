///|
extern "js" fn install_debug_bindings(
  list_ui_entries_text : () -> String,
  click_ui : (String, String) -> String,
  render_game_to_text : () -> String,
  run_command_text : (String, Array[String]) -> String,
) -> Unit =
  #| (
  #|   listUiEntriesText,
  #|   clickUi,
  #|   renderGameToText,
  #|   runCommandText
  #| ) => {
  #|   const toInt = (value, fallback) => {
  #|     const n = Number(value);
  #|     return Number.isFinite(n) ? Math.trunc(n) : fallback;
  #|   };
  #|
  #|   const ui = {
  #|     list() {
  #|       return JSON.parse(listUiEntriesText());
  #|     },
  #|     click(packageName, uiName) {
  #|       const text = clickUi(String(packageName), String(uiName));
  #|       return JSON.parse(text);
  #|     },
  #|   };
  #|
  #|   async function step(frames = 1) {
  #|     const n = Math.max(1, toInt(frames, 1));
  #|     for (let i = 0; i < n; i += 1) {
  #|       if (typeof window.advanceTime === "function") {
  #|         await window.advanceTime(1000 / 60);
  #|       } else {
  #|         await new Promise((resolve) => requestAnimationFrame(() => resolve()));
  #|       }
  #|     }
  #|   }
  #|
  #|   function cmd(name, ...args) {
  #|     const text = runCommandText(String(name), args.map((it) => String(it)));
  #|     return JSON.parse(text);
  #|   }
  #|
  #|   globalThis.render_game_to_text = renderGameToText;
  #|   globalThis.$console = {
  #|     help() {
  #|       console.info("$console.ui.list()");
  #|       console.info('$console.ui.click("quest_log", "tab.completed")');
  #|       console.info("$console.render_game_to_text()");
  #|       console.info("await $console.step(20)");
  #|       console.info('$console.cmd("meso", "1000000")');
  #|       console.info('$console.cmd("item", "1302007", "1")');
  #|       console.info('$console.cmd("warp", "100000000", "0")');
  #|     },
  #|     ui,
  #|     render_game_to_text: renderGameToText,
  #|     step,
  #|     cmd,
  #|   };
  #| };
