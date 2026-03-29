///|
type StateSectionFn = () -> Json

///|
type CommandHandler = (Array[String]) -> Json

///|
priv struct UiEntry {
  package_name : String
  ui_name : String
}

///|
let state_sections_ref : Ref[Array[(String, StateSectionFn)]] = Ref::new([])

///|
let command_handlers_ref : Ref[Array[(String, CommandHandler)]] = Ref::new([])

///|
let ui_entries_by_entity_ref : Ref[Map[@entity.Entity, UiEntry]] = Ref::new(
  Map::new(),
)

///|
let ui_entity_by_key_ref : Ref[Map[String, @entity.Entity]] = Ref::new(
  Map::new(),
)

///|
priv enum UiClickInjectionState {
  PressQueued(@selene_math.Vec2D)
  ReleaseQueued(@selene_math.Vec2D)
}

///|
let pending_ui_click_ref : Ref[UiClickInjectionState?] = Ref::new(None)

///|
fn make_ui_key(package_name : String, ui_name : String) -> String {
  "\{package_name}::\{ui_name}"
}

///|
fn remove_ui_entry_by_entity(entity : @entity.Entity) -> Unit {
  match ui_entries_by_entity_ref.val.get(entity) {
    Some(entry) => {
      ui_entries_by_entity_ref.val.remove(entity)
      let key = make_ui_key(entry.package_name, entry.ui_name)
      if ui_entity_by_key_ref.val.get(key) is Some(mapped) && mapped == entity {
        ui_entity_by_key_ref.val.remove(key)
      }
    }
    None => ()
  }
}

///|
fn cleanup_invalid_ui_entities() -> Unit {
  let entities : Array[@entity.Entity] = []
  for entity, _entry in ui_entries_by_entity_ref.val {
    entities.push(entity)
  }
  for entity in entities {
    if !entity.is_alive() || !@selene_ui.global_ui_nodes().contains(entity) {
      remove_ui_entry_by_entity(entity)
    }
  }
}

///|
fn list_ui_entries_json() -> Json {
  cleanup_invalid_ui_entities()
  let entries : Array[Json] = []
  for entity, entry in ui_entries_by_entity_ref.val {
    let rect_json : Json = match @selene_ui.global_ui_nodes().get(entity) {
      Some(global_ui_node) => {
        let rect = global_ui_node.screen_rect
        (
          {
            "x": rect.position[@selene_math.X],
            "y": rect.position[@selene_math.Y],
            "w": rect.size[@selene_math.X],
            "h": rect.size[@selene_math.Y],
          } : Json)
      }
      None => Json::null()
    }
    entries.push({
      "package": entry.package_name,
      "name": entry.ui_name,
      "alive": entity.is_alive(),
      "rect": rect_json,
    })
  }
  entries.to_json()
}

///|
fn list_ui_entries_text() -> String {
  list_ui_entries_json().stringify()
}

///|
fn click_registered_ui_impl(package_name : String, ui_name : String) -> Json {
  cleanup_invalid_ui_entities()
  let key = make_ui_key(package_name, ui_name)
  guard ui_entity_by_key_ref.val.get(key) is Some(entity) else {
    return {
      "ok": false,
      "code": "NOT_FOUND",
      "message": "ui id not found: \{package_name}.\{ui_name}",
    }
  }
  guard @selene_ui.global_ui_nodes().get(entity) is Some(global_ui_node) else {
    remove_ui_entry_by_entity(entity)
    return {
      "ok": false,
      "code": "NOT_FOUND",
      "message": "ui id not found: \{package_name}.\{ui_name}",
    }
  }
  let rect = global_ui_node.screen_rect
  let pos = @selene_math.Vec2D(
    rect.position[@selene_math.X] + rect.size[@selene_math.X] / 2.0,
    rect.position[@selene_math.Y] + rect.size[@selene_math.Y] / 2.0,
  )
  pending_ui_click_ref.val = Some(UiClickInjectionState::PressQueued(pos))
  {
    "ok": true,
    "code": "QUEUED",
    "message": "click queued",
    "package": package_name,
    "name": ui_name,
    "click_pos": { "x": pos[@selene_math.X], "y": pos[@selene_math.Y] },
    "rect": {
      "x": rect.position[@selene_math.X],
      "y": rect.position[@selene_math.Y],
      "w": rect.size[@selene_math.X],
      "h": rect.size[@selene_math.Y],
    },
  }
}

///|
fn click_registered_ui_text(package_name : String, ui_name : String) -> String {
  click_registered_ui_impl(package_name, ui_name).stringify()
}

///|
fn render_registered_game_to_text() -> String {
  let data = Map::new()
  for _, entry in state_sections_ref.val {
    let (name, handler) = entry
    data.set(name, handler())
  }
  data.set("clickable_ui_entries", list_ui_entries_json())
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

///|
/// Register one JSON state section used by `render_game_to_text`.
pub fn register_state_section(name : String, handler : StateSectionFn) -> Unit {
  state_sections_ref.val.retain(fn(entry) { entry.0 != name })
  state_sections_ref.val.push((name, handler))
}

///|
/// Register one UI entity with namespaced debug id `(package_name, ui_name)`.
pub fn register_ui_entity(
  package_name : String,
  ui_name : String,
  entity : @entity.Entity,
) -> Unit {
  remove_ui_entry_by_entity(entity)
  let key = make_ui_key(package_name, ui_name)
  if ui_entity_by_key_ref.val.get(key) is Some(existing_entity) {
    remove_ui_entry_by_entity(existing_entity)
  }
  let entry = { package_name, ui_name }
  ui_entries_by_entity_ref.val.set(entity, entry)
  ui_entity_by_key_ref.val.set(key, entity)
}

///|
/// Unregister one UI entity from debug click mapping.
pub fn unregister_ui_entity(entity : @entity.Entity) -> Unit {
  remove_ui_entry_by_entity(entity)
}

///|
/// Returns registered UI debug entries as JSON array.
pub fn list_ui_entries() -> Json {
  list_ui_entries_json()
}

///|
/// Click one registered UI by namespaced id `(package_name, ui_name)`.
pub fn click_registered_ui(package_name : String, ui_name : String) -> Json {
  click_registered_ui_impl(package_name, ui_name)
}

///|
/// Clears pending console UI click injection.
pub fn clear_input_injection() -> Unit {
  pending_ui_click_ref.val = None
}

///|
/// Applies queued console UI click injection in two frames: press then release.
pub fn console_input_injection_system(_world : @ecs.World) -> Unit {
  match pending_ui_click_ref.val {
    Some(UiClickInjectionState::PressQueued(pos)) => {
      @inputs.mouse.pos = pos
      @inputs.mouse.left_button = true
      pending_ui_click_ref.val = Some(UiClickInjectionState::ReleaseQueued(pos))
    }
    Some(UiClickInjectionState::ReleaseQueued(pos)) => {
      @inputs.mouse.pos = pos
      @inputs.mouse.left_button = false
      pending_ui_click_ref.val = None
    }
    None => ()
  }
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
    list_ui_entries_text, click_registered_ui_text, render_registered_game_to_text,
    run_registered_command_text,
  )
}
