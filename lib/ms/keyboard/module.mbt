///|
struct Module {
  keyboard : Keyboard
  keymap_callbacks : Array[KeymapWatcher]
  network : @net.Network
}

///|
typealias KeymapWatcher = (Map[String, Mapping]) -> Unit

///|
pub fn Module::new(
  default_keymap : Map[String, Mapping],
  network : @net.Network
) -> Module {
  let keyboard = Keyboard::new(default_keymap)
  { keyboard, keymap_callbacks: Array::new(), network }
}

///|
pub fn Module::get_keyboard(self : Module) -> Keyboard {
  self.keyboard
}

///|
pub fn Module::on_keymap_change(
  self : Module,
  callback : KeymapWatcher
) -> Unit {
  self.keymap_callbacks.push(callback)
}

// Helper to notify all callbacks
///|
fn notify_keymap_change(
  self : Module,
  new_keymap : Map[String, Mapping]
) -> Unit {
  for callback in self.keymap_callbacks {
    callback(new_keymap)
  }
}

///|
pub fn Module::make_handlers(
  self : Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(@net.KEYMAP, fn(recv) { parse_keymap!(recv) }, fn(
      mappings : Array[(Int, Int)]
    ) {
      // Update keyboard with new mappings
      for i, mapping in mappings {
        guard MsKey::from_int(i) is Some(ms_key) else { // TODO: handle unknown key
          continue
        }
        if mapping.0 != 0 {
          let kt = KeyType::from_int(mapping.0).unwrap() // TODO: handle error
          self.keyboard.assign(ms_key, kt, mapping.1)
        } else {
          self.keyboard.remove(ms_key)
        }
      }
      // Notify watchers of change
      self.notify_keymap_change(self.keyboard.keymap)
    }),
  ]
  |> Map::from_array
}
