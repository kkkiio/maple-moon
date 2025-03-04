///|
pub struct KeyMappingJs {
  keycode : String
  kind : String
  action : Int
}

///|
pub fn get_key_mappings(keymap : Map[KeyCode, Mapping]) -> Array[KeyMappingJs] {
  keymap
  .iter()
  .map(fn(e) {
    let (k, v) = e
    { keycode: k, kind: v.t.name(), action: v.action }
  })
  .to_array()
}

///| Watch function that takes a callback to be called when mappings change
pub fn watch_keyboard(
  mod : Module,
  callback : (Array[KeyMappingJs]) -> Unit
) -> Unit {
  // Initial call with current mappings
  callback(get_key_mappings(mod.get_keyboard().keymap))

  // Set up watcher for future changes
  mod.on_keymap_change(fn(new_keymap) { callback(get_key_mappings(new_keymap)) })
}

///| Update key mappings with new values from JS
pub fn update_key_mappings(
  mod : Module,
  mappings : Array[KeyMappingJs]
) -> Unit {
  let update_actions = Array::new()
  for mapping in mappings {
    // Find the MsKey from the keycode
    guard let Some(ms_key) = find_mskey_from_keycode(mapping.keycode) else {
      None => {
        @log.error(
          { "keycode": mapping.keycode },
          "update_key_mappings: key not found",
        )
        continue
      }
    }
    if mapping.kind == "" { // remove mapping
      update_actions.push((ms_key, None))
      continue
    }
    guard let Some(kt) = KeyType::from_name(mapping.kind) else {
      None => {
        @log.error(
          { "kind": mapping.kind },
          "update_key_mappings: key type not found",
        )
        continue
      }
    }
    update_actions.push((ms_key, Some(Mapping::new(kt, mapping.action))))
  }
  // Send changes to server
  mod.packet_processor.send_message(
    ChangeKeymapMessage::new(update_actions),
    log_level=@log.Level::INFO,
  )
}

///| Helper function to find MsKey from keycode
fn find_mskey_from_keycode(keycode : KeyCode) -> MsKey? {
  ms_key_keycode_table.get_backward(keycode)
}
