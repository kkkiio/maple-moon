///|
pub(all) struct Keyboard {
  keymap : Map[KeyCode, Mapping]
  maple_keys : Map[MsKey, Mapping]
  key_state : Map[Int, Bool]
}

///|
pub fn Keyboard::new(keymap : Map[String, Mapping]) -> Keyboard {
  { keymap, maple_keys: Map::new(), key_state: Map::new() }
}

///|
pub fn get_maplekeys(self : Keyboard) -> Map[MsKey, Mapping] {
  self.maple_keys
}

///|
pub fn assign(self : Keyboard, key : MsKey, mapping : Mapping) -> Unit {
  self.keymap.set(mskey_to_keycode(key), mapping)
  self.maple_keys.set(key, mapping)
}

///|
pub fn remove(self : Keyboard, key : MsKey) -> Unit {
  self.keymap.remove(mskey_to_keycode(key))
  self.maple_keys.remove(key)
}

///|
pub fn get_mapping(self : Keyboard, keycode : KeyCode) -> Mapping? {
  self.keymap.get(keycode)
}

///|
pub fn get_mapping_by_ms_key(self : Keyboard, key : MsKey) -> Mapping? {
  self.maple_keys.get(key)
}

///|
fn mskey_to_keycode(key : MsKey) -> KeyCode {
  ms_key_keycode_table.get_forward(key).unwrap()
}

///|
let ms_key_keycode_table : @utils.BiMap[MsKey, KeyCode] = @utils.BiMap::from_array([
    (MsKey::NUM0, digit0),
    (MsKey::NUM1, digit1),
    (MsKey::NUM2, digit2),
    (MsKey::NUM3, digit3),
    (MsKey::NUM4, digit4),
    (MsKey::NUM5, digit5),
    (MsKey::NUM6, digit6),
    (MsKey::NUM7, digit7),
    (MsKey::NUM8, digit8),
    (MsKey::NUM9, digit9),
    (MsKey::MINUS, minus),
    (MsKey::EQUAL, equal),
    (MsKey::Q, keyQ),
    (MsKey::W, keyW),
    (MsKey::E, keyE),
    (MsKey::R, keyR),
    (MsKey::T, keyT),
    (MsKey::Y, keyY),
    (MsKey::U, keyU),
    (MsKey::I, keyI),
    (MsKey::O, keyO),
    (MsKey::P, keyP),
    (MsKey::LEFT_BRACKET, bracketLeft),
    (MsKey::RIGHT_BRACKET, bracketRight),
    (MsKey::LEFT_CONTROL, controlLeft),
    (MsKey::A, keyA),
    (MsKey::S, keyS),
    (MsKey::D, keyD),
    (MsKey::F, keyF),
    (MsKey::G, keyG),
    (MsKey::H, keyH),
    (MsKey::J, keyJ),
    (MsKey::K, keyK),
    (MsKey::L, keyL),
    (MsKey::SEMICOLON, semicolon),
    (MsKey::APOSTROPHE, quote),
    (MsKey::GRAVE_ACCENT, backquote),
    (MsKey::LEFT_SHIFT, shiftLeft),
    (MsKey::BACKSLASH, backslash),
    (MsKey::Z, keyZ),
    (MsKey::X, keyX),
    (MsKey::C, keyC),
    (MsKey::V, keyV),
    (MsKey::B, keyB),
    (MsKey::N, keyN),
    (MsKey::M, keyM),
    (MsKey::COMMA, comma),
    (MsKey::PERIOD, period),
    (MsKey::LEFT_ALT, altLeft),
    (MsKey::SPACE, space),
    (MsKey::F1, f1),
    (MsKey::F2, f2),
    (MsKey::F3, f3),
    (MsKey::F4, f4),
    (MsKey::F5, f5),
    (MsKey::F6, f6),
    (MsKey::F7, f7),
    (MsKey::F8, f8),
    (MsKey::F9, f9),
    (MsKey::F10, f10),
    (MsKey::F11, f11),
    (MsKey::F12, f12),
    (MsKey::HOME, home),
    (MsKey::PAGE_UP, pageUp),
    (MsKey::END, end),
    (MsKey::PAGE_DOWN, pageDown),
    (MsKey::INSERT, insert),
    (MsKey::DELETE, delete),
    (MsKey::ESCAPE, escape),
    (MsKey::RIGHT_CONTROL, controlRight),
    (MsKey::RIGHT_SHIFT, shiftRight),
    (MsKey::RIGHT_ALT, altRight),
    (MsKey::SCROLL_LOCK, scrollLock),
  ],
)
