pub struct Mapping {
  t : @KeyType.Id
  action : Int
} derive(Eq, Compare)

pub fn Mapping::new(in_type : @KeyType.Id, in_action : Int) -> Mapping {
  { t: in_type, action: in_action }
}

pub struct Keyboard {
  keymap : Map[String, Mapping]
  maple_keys : Map[Int, Mapping]
  // text_actions : Map[String, @KeyAction.Id]
  key_state : Map[Int, Bool]
}

pub fn Keyboard::default() -> Keyboard {
  let keymap = Map::new()
  keymap.set(
    @kb.arrowLeft,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::LEFT.int_value()),
  )
  keymap.set(
    @kb.arrowRight,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::RIGHT.int_value()),
  )
  keymap.set(
    @kb.arrowUp,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::UP.int_value()),
  )
  keymap.set(
    @kb.arrowDown,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::DOWN.int_value()),
  )
  keymap.set(
    @kb.enter,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::RETURN.int_value()),
  )
  keymap.set(
    @kb.numpadEnter,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::RETURN.int_value()),
  )
  keymap.set(
    @kb.tab,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::TAB.int_value()),
  )
  keymap.set(
    @kb.space,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::JUMP.int_value()),
  )
  keymap.set(
    @kb.keyX,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::ATTACK.int_value()),
  )
  keymap.set(
    @kb.keyC,
    Mapping::new(@KeyType.Id::ACTION, @KeyAction.Id::PICKUP.int_value()),
  )
  keymap.set(
    @kb.keyI,
    Mapping::new(@KeyType.Id::MENU, @KeyAction.Id::ITEMS.int_value()),
  )
  keymap.set(
    @kb.keyO,
    Mapping::new(@KeyType.Id::MENU, @KeyAction.Id::SKILLS.int_value()),
  )
  keymap.set(
    @kb.keyA,
    Mapping::new(@KeyType.Id::SKILL, @skill.SkillId::MAGIC_CLAW.int_value()),
  )
  let text_actions = Map::new()
  text_actions.set(@kb.backspace, @KeyAction.Id::BACK)
  text_actions.set(@kb.enter, @KeyAction.Id::RETURN)
  text_actions.set(@kb.numpadEnter, @KeyAction.Id::RETURN)
  text_actions.set(@kb.space, @KeyAction.Id::SPACE)
  text_actions.set(@kb.tab, @KeyAction.Id::TAB)
  text_actions.set(@kb.escape, @KeyAction.Id::ESCAPE)
  text_actions.set(@kb.home, @KeyAction.Id::HOME)
  text_actions.set(@kb.end, @KeyAction.Id::END)
  text_actions.set(@kb.delete, @KeyAction.Id::DELETE)
  {
    keymap,
    maple_keys: Map::new(),
    // text_actions, 
    key_state: Map::new(),
  }
}

pub fn get_maplekeys(self : Keyboard) -> Map[Int, Mapping] {
  self.maple_keys
}

pub fn get_ctrl_action(self : Keyboard, keycode : String) -> @KeyAction.Id? {
  // match keycode {
  //   @kb.keyC => @KeyAction.Id::COPY
  //   @kb.keyV => @KeyAction.Id::PASTE
  //   _ => @KeyAction.Id::LENGTH
  // }
  if keycode == @kb.keyC {
    Some(@KeyAction.Id::COPY)
  } else if keycode == @kb.keyV {
    Some(@KeyAction.Id::PASTE)
  } else {
    None
  }
}

pub fn assign(self : Keyboard, key : Int, tid : Int, action : Int) -> Unit {
  match @KeyType.get_type_by_id(tid) {
    @KeyType.Id::NONE => ()
    _ as type_ => {
      let mapping = Mapping::new(type_, action)
      self.keymap.set(keytable[key], mapping)
      self.maple_keys.set(key, mapping)
    }
  }
}

pub fn remove(self : Keyboard, key : Int) -> Unit {
  let mapping = Mapping::new(@KeyType.Id::NONE, 0)
  self.keymap.set(keytable[key], mapping)
  self.maple_keys.set(key, mapping)
}

// pub fn get_text_mapping(
//   self : Keyboard,
//   keycode : String,
//   shift : Bool
// ) -> Mapping {
//   if self.text_actions.contains(keycode) {
//     return Mapping::new(
//       @KeyType.Id::ACTION,
//       self.text_actions[keycode].unwrap().int_value(),
//     )
//   }
//     // GLFMKeyCodeComma             = 0x2C,
//     // GLFMKeyCodeMinus             = 0x2D,
//     // GLFMKeyCodePeriod            = 0x2E,
//     // GLFMKeyCodeSlash             = 0x2F,
//     // GLFMKeyCode0                 = 0x30,
//     // GLFMKeyCode1                 = 0x31,
//     // GLFMKeyCode2                 = 0x32,
//     // GLFMKeyCode3                 = 0x33,
//     // GLFMKeyCode4                 = 0x34,
//     // GLFMKeyCode5                 = 0x35,
//     // GLFMKeyCode6                 = 0x36,
//     // GLFMKeyCode7                 = 0x37,
//     // GLFMKeyCode8                 = 0x38,
//     // GLFMKeyCode9                 = 0x39,
//   if keycode == @kb.quote || keycode >= 44 && keycode <= 57 || keycode == 59 || keycode ==
//   61 || keycode >= 91 && keycode <= 93 || keycode == 96 {
//     if shift.not() {
//       return Mapping::new(@KeyType.Id::TEXT, keycode)
//     }
//     return Mapping::new(@KeyType.Id::TEXT, specialtable[keycode - 1])
//   }
//   if keycode >= 33 && keycode <= 126 {
//     if shift {
//       return Mapping::new(@KeyType.Id::TEXT, keycode)
//     }
//     return Mapping::new(@KeyType.Id::TEXT, shifttable[keycode - 1])
//   }

//   // match keycode {
//   //   @kb.arrowLeft| @kb.arrowRight| @kb.arrowUp| @kb.arrowDown => self.keymap[keycode].unwrap()
//   //   _ => Mapping::new(@KeyType.Id::NONE, 0)
//   // }
//   if keycode == @kb.arrowLeft || keycode == @kb.arrowRight || keycode == @kb.arrowUp ||
//   keycode == @kb.arrowDown {
//     return self.keymap[keycode].unwrap()
//   }
//   Mapping::new(@KeyType.Id::NONE, 0)
// }

pub fn get_mapping(self : Keyboard, keycode : String) -> Mapping {
  self.keymap.get(keycode).or(Mapping::new(@KeyType.Id::NONE, 0))
}

pub fn get_maple_mapping(self : Keyboard, key : Int) -> Mapping {
  self.maple_keys.get(key).or(Mapping::new(@KeyType.Id::NONE, 0))
}

let keytable : FixedArray[String] = [
  "", "", @kb.digit0, @kb.digit1, @kb.digit2, @kb.digit3, @kb.digit4, @kb.digit5,
  @kb.digit6, @kb.digit7, @kb.digit8, @kb.digit9, @kb.minus, @kb.equal, "", "", @kb.keyQ,
  @kb.keyW, @kb.keyE, @kb.keyR, @kb.keyT, @kb.keyY, @kb.keyU, @kb.keyI, @kb.keyO,
  @kb.keyP, @kb.bracketLeft, @kb.bracketRight, "", @kb.controlLeft, @kb.keyA, @kb.keyS,
  @kb.keyD, @kb.keyF, @kb.keyG, @kb.keyH, @kb.keyJ, @kb.keyK, @kb.keyL, @kb.semicolon,
  @kb.quote, @kb.backquote, @kb.shiftLeft, @kb.backslash, @kb.keyZ, @kb.keyX, @kb.keyC,
  @kb.keyV, @kb.keyB, @kb.keyN, @kb.keyM, @kb.comma, @kb.period, "", "", "", @kb.altLeft,
  @kb.space, "", @kb.f1, @kb.f2, @kb.f3, @kb.f4, @kb.f5, @kb.f6, @kb.f7, @kb.f8,
  @kb.f9, @kb.f10, @kb.f11, @kb.f12, @kb.home, "", @kb.pageUp, "", "", "", "", "",
  @kb.end, @kb.capsLock, @kb.pageDown, @kb.insert, @kb.delete, @kb.escape, @kb.controlRight,
  @kb.shiftRight, @kb.altRight, @kb.scrollLock,
]

let shifttable : FixedArray[Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 49, 39, 51, 52, 53, 55, 0, 57, 48, 56, 61, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 59, 0, 44, 0, 46, 47, 50, 97, 98, 99, 100, 101, 102, 103,
  104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
  120, 121, 122, 0, 0, 0, 54, 45, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 91, 92, 93, 96,
]

let specialtable : FixedArray[Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 0, 60, 95, 62, 63, 41, 33, 64, 35,
  36, 37, 94, 38, 42, 40, 0, 58, 0, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 123, 124, 125, 0, 0, 126,
]
