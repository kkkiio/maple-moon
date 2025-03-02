///|
pub enum MsKey {
  NUM0
  NUM1
  NUM2
  NUM3
  NUM4
  NUM5
  NUM6
  NUM7
  NUM8
  NUM9
  MINUS
  EQUAL
  Q
  W
  E
  R
  T
  Y
  U
  I
  O
  P
  LEFT_BRACKET
  RIGHT_BRACKET
  LEFT_CONTROL
  A
  S
  D
  F
  G
  H
  J
  K
  L
  SEMICOLON
  APOSTROPHE
  GRAVE_ACCENT
  LEFT_SHIFT
  BACKSLASH
  Z
  X
  C
  V
  B
  N
  M
  COMMA
  PERIOD
  LEFT_ALT
  SPACE
  F1
  F2
  F3
  F4
  F5
  F6
  F7
  F8
  F9
  F10
  F11
  F12
  HOME
  PAGE_UP
  END
  PAGE_DOWN
  INSERT
  DELETE
  ESCAPE
  RIGHT_CONTROL
  RIGHT_SHIFT
  RIGHT_ALT
  SCROLL_LOCK
} derive(Hash, Eq)

///|
let ms_key_to_keycode : @utils.BiMap[MsKey, Int] = @utils.BiMap::new()

///|
let ms_key_to_name : @utils.BiMap[MsKey, String] = @utils.BiMap::new()

///|
fn init {
  [
    (NUM0, 2, "NUM0"),
    (NUM1, 3, "NUM1"),
    (NUM2, 4, "NUM2"),
    (NUM3, 5, "NUM3"),
    (NUM4, 6, "NUM4"),
    (NUM5, 7, "NUM5"),
    (NUM6, 8, "NUM6"),
    (NUM7, 9, "NUM7"),
    (NUM8, 10, "NUM8"),
    (NUM9, 11, "NUM9"),
    (MINUS, 12, "MINUS"),
    (EQUAL, 13, "EQUAL"),
    (Q, 16, "Q"),
    (W, 17, "W"),
    (E, 18, "E"),
    (R, 19, "R"),
    (T, 20, "T"),
    (Y, 21, "Y"),
    (U, 22, "U"),
    (I, 23, "I"),
    (O, 24, "O"),
    (P, 25, "P"),
    (LEFT_BRACKET, 26, "LEFT_BRACKET"),
    (RIGHT_BRACKET, 27, "RIGHT_BRACKET"),
    (LEFT_CONTROL, 29, "LEFT_CONTROL"),
    (A, 30, "A"),
    (S, 31, "S"),
    (D, 32, "D"),
    (F, 33, "F"),
    (G, 34, "G"),
    (H, 35, "H"),
    (J, 36, "J"),
    (K, 37, "K"),
    (L, 38, "L"),
    (SEMICOLON, 39, "SEMICOLON"),
    (APOSTROPHE, 40, "APOSTROPHE"),
    (GRAVE_ACCENT, 41, "GRAVE_ACCENT"),
    (LEFT_SHIFT, 42, "LEFT_SHIFT"),
    (BACKSLASH, 43, "BACKSLASH"),
    (Z, 44, "Z"),
    (X, 45, "X"),
    (C, 46, "C"),
    (V, 47, "V"),
    (B, 48, "B"),
    (N, 49, "N"),
    (M, 50, "M"),
    (COMMA, 51, "COMMA"),
    (PERIOD, 52, "PERIOD"),
    (LEFT_ALT, 56, "LEFT_ALT"),
    (SPACE, 57, "SPACE"),
    (F1, 59, "F1"),
    (F2, 60, "F2"),
    (F3, 61, "F3"),
    (F4, 62, "F4"),
    (F5, 63, "F5"),
    (F6, 64, "F6"),
    (F7, 65, "F7"),
    (F8, 66, "F8"),
    (F9, 67, "F9"),
    (F10, 68, "F10"),
    (F11, 69, "F11"),
    (F12, 70, "F12"),
    (HOME, 71, "HOME"),
    (PAGE_UP, 73, "PAGE_UP"),
    (END, 79, "END"),
    (PAGE_DOWN, 81, "PAGE_DOWN"),
    (INSERT, 82, "INSERT"),
    (DELETE, 83, "DELETE"),
    (ESCAPE, 84, "ESCAPE"),
    (RIGHT_CONTROL, 85, "RIGHT_CONTROL"),
    (RIGHT_SHIFT, 86, "RIGHT_SHIFT"),
    (RIGHT_ALT, 87, "RIGHT_ALT"),
    (SCROLL_LOCK, 88, "SCROLL_LOCK"),
  ].each(fn(e) {
    ms_key_to_keycode.set(e.0, e.1)
    ms_key_to_name.set(e.0, e.2)
  })
}

///|
pub fn MsKey::int_value(self : MsKey) -> Int {
  ms_key_to_keycode.get_forward(self).unwrap()
}

///|
pub fn MsKey::from_int(id : Int) -> MsKey? {
  ms_key_to_keycode.get_backward(id)
}

///|
pub impl Show for MsKey with output(self, logger) {
  logger.write_string(ms_key_to_name.get_forward(self).unwrap())
}

///|
pub fn MsKey::from_name(name : String) -> MsKey? {
  ms_key_to_name.get_backward(name)
}

///|
pub fn action_by_id(id : Int) -> MsKey? {
  MsKey::from_int(id)
}
