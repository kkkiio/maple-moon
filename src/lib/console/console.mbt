///|
type StateSectionFn = () -> Json

///|
type UiListFn = () -> Array[String]

///|
type UiClickFn = (String) -> Bool

///|
type CommandHandler = (Array[String]) -> Json

///|
priv struct UiProvider {
  list : UiListFn
  click : UiClickFn
}

///|
let state_sections_ref : Ref[Array[(String, StateSectionFn)]] = Ref::new([])

///|
let ui_providers_ref : Ref[Array[(String, UiProvider)]] = Ref::new([])

///|
let command_handlers_ref : Ref[Array[(String, CommandHandler)]] = Ref::new([])

///|
fn collect_registered_ui_ids() -> Array[String] {
  let ids = []
  for _, entry in ui_providers_ref.val {
    let (_, provider) = entry
    for id in (provider.list)() {
      if not(ids.contains(id)) {
        ids.push(id)
      }
    }
  }
  ids
}

///|
fn click_registered_ui_id(id : String) -> Bool {
  for _, entry in ui_providers_ref.val {
    let (_, provider) = entry
    if (provider.click)(id) {
      return true
    }
  }
  false
}

///|
fn render_registered_game_to_text() -> String {
  let data = Map::new()
  for _, entry in state_sections_ref.val {
    let (name, handler) = entry
    data.set(name, handler())
  }
  data.set("clickable_ids", collect_registered_ui_ids().to_json())
  data.to_json().stringify()
}

///|
fn run_registered_command(name : String, args : Array[String]) -> Json {
  for _, entry in command_handlers_ref.val {
    let (command_name, handler) = entry
    if command_name == name {
      return handler(args)
    }
  }
  { "ok": false, "code": "NOT_FOUND", "message": "command not found: \{name}" }
}

///|
fn run_registered_command_text(name : String, args : Array[String]) -> String {
  run_registered_command(name, args).stringify()
}

///|
extern "js" fn install_debug_bindings(
  list_clickable_ids : () -> Array[String],
  click_ui_id : (String) -> Bool,
  render_game_to_text : () -> String,
  run_command_text : (String, Array[String]) -> String,
) -> Unit =
  #| (
  #|   listClickableIds,
  #|   clickUiId,
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
  #|       return { ids: listClickableIds() };
  #|     },
  #|     click(id) {
  #|       const ok = clickUiId(String(id));
  #|       if (ok) {
  #|         return { ok: true, code: "OK", message: "clicked" };
  #|       }
  #|       return { ok: false, code: "NOT_FOUND", message: `ui id not found: ${id}` };
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
  #|       console.info('$console.ui.click("select_char.new_character")');
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

///|
/// Register one JSON state section used by `render_game_to_text`.
pub fn register_state_section(name : String, handler : StateSectionFn) -> Unit {
  state_sections_ref.val.retain(fn(entry) { entry.0 != name })
  state_sections_ref.val.push((name, handler))
}

///|
/// Register one UI provider for `$console.ui.list()` and `$console.ui.click(id)`.
pub fn register_ui_provider(
  name : String,
  list : UiListFn,
  click : UiClickFn,
) -> Unit {
  ui_providers_ref.val.retain(fn(entry) { entry.0 != name })
  ui_providers_ref.val.push((name, { list, click }))
}

///|
/// Register a command handler used by `$console.cmd(name, ...args)`.
pub fn register_command(name : String, handler : CommandHandler) -> Unit {
  command_handlers_ref.val.retain(fn(entry) { entry.0 != name })
  command_handlers_ref.val.push((name, handler))
}

///|
/// Install `$console` and `render_game_to_text` onto `globalThis`.
pub fn install() -> Unit {
  install_debug_bindings(
    collect_registered_ui_ids, click_registered_ui_id, render_registered_game_to_text,
    run_registered_command_text,
  )
}
