///|
typealias Mapping = @keyboard.Mapping

///|
pub(all) struct Keyboard {
  keymap : Map[String, Mapping]
  maple_keys : Map[Int, Mapping]
  // text_actions : Map[String, @keyboard.ActionId]
  key_state : Map[Int, Bool]
}

///|
pub fn Keyboard::default() -> Keyboard {
  let keymap = Map::new()
  keymap.set(
    @keyboard.arrowLeft,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::LEFT.int_value(),
    ),
  )
  keymap.set(
    @keyboard.arrowRight,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::RIGHT.int_value(),
    ),
  )
  keymap.set(
    @keyboard.arrowUp,
    Mapping::new(@keyboard.KeyType::ACTION, @keyboard.ActionId::UP.int_value()),
  )
  keymap.set(
    @keyboard.arrowDown,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::DOWN.int_value(),
    ),
  )
  keymap.set(
    @keyboard.enter,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::RETURN.int_value(),
    ),
  )
  keymap.set(
    @keyboard.numpadEnter,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::RETURN.int_value(),
    ),
  )
  keymap.set(
    @keyboard.tab,
    Mapping::new(@keyboard.KeyType::ACTION, @keyboard.ActionId::TAB.int_value()),
  )
  keymap.set(
    @keyboard.space,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::JUMP.int_value(),
    ),
  )
  keymap.set(
    @keyboard.keyX,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::ATTACK.int_value(),
    ),
  )
  keymap.set(
    @keyboard.keyC,
    Mapping::new(
      @keyboard.KeyType::ACTION,
      @keyboard.ActionId::PICKUP.int_value(),
    ),
  )
  keymap.set(
    @keyboard.keyI,
    Mapping::new(@keyboard.KeyType::MENU, @keyboard.ActionId::ITEMS.int_value()),
  )
  keymap.set(
    @keyboard.keyO,
    Mapping::new(
      @keyboard.KeyType::MENU,
      @keyboard.ActionId::SKILLS.int_value(),
    ),
  )
  keymap.set(
    @keyboard.keyE,
    Mapping::new(@keyboard.KeyType::MENU, @keyboard.ActionId::STATS.int_value()),
  )
  keymap.set(
    @keyboard.keyA,
    Mapping::new(
      @keyboard.KeyType::SKILL,
      @skill.SkillId::MAGIC_CLAW.int_value(),
    ),
  )
  let text_actions = Map::new()
  text_actions.set(@keyboard.backspace, @keyboard.ActionId::BACK)
  text_actions.set(@keyboard.enter, @keyboard.ActionId::RETURN)
  text_actions.set(@keyboard.numpadEnter, @keyboard.ActionId::RETURN)
  text_actions.set(@keyboard.space, @keyboard.ActionId::SPACE)
  text_actions.set(@keyboard.tab, @keyboard.ActionId::TAB)
  text_actions.set(@keyboard.escape, @keyboard.ActionId::ESCAPE)
  text_actions.set(@keyboard.home, @keyboard.ActionId::HOME)
  text_actions.set(@keyboard.end, @keyboard.ActionId::END)
  text_actions.set(@keyboard.delete, @keyboard.ActionId::DELETE)
  {
    keymap,
    maple_keys: Map::new(),
    // text_actions, 
    key_state: Map::new(),
  }
}

///|
pub fn get_maplekeys(self : Keyboard) -> Map[Int, Mapping] {
  self.maple_keys
}

///|
pub fn get_ctrl_action(
  self : Keyboard,
  keycode : String
) -> @keyboard.ActionId? {
  // match keycode {
  //   @keyboard.keyC => @keyboard.ActionId::COPY
  //   @keyboard.keyV => @keyboard.ActionId::PASTE
  //   _ => @keyboard.ActionId::LENGTH
  // }
  if keycode == @keyboard.keyC {
    Some(@keyboard.ActionId::COPY)
  } else if keycode == @keyboard.keyV {
    Some(@keyboard.ActionId::PASTE)
  } else {
    None
  }
}

///|
pub fn assign(self : Keyboard, key : Int, tid : Int, action : Int) -> Unit {
  match @keyboard.get_type_by_id(tid) {
    @keyboard.KeyType::NONE => ()
    _ as type_ => {
      let mapping = Mapping::new(type_, action)
      self.keymap.set(keytable[key], mapping)
      self.maple_keys.set(key, mapping)
    }
  }
}

///|
pub fn remove(self : Keyboard, key : Int) -> Unit {
  let mapping = Mapping::new(@keyboard.KeyType::NONE, 0)
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
//       @keyboard.Id::ACTION,
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
//   if keycode == @keyboard.quote || keycode >= 44 && keycode <= 57 || keycode == 59 || keycode ==
//   61 || keycode >= 91 && keycode <= 93 || keycode == 96 {
//     if shift.not() {
//       return Mapping::new(@keyboard.Id::TEXT, keycode)
//     }
//     return Mapping::new(@keyboard.Id::TEXT, specialtable[keycode - 1])
//   }
//   if keycode >= 33 && keycode <= 126 {
//     if shift {
//       return Mapping::new(@keyboard.Id::TEXT, keycode)
//     }
//     return Mapping::new(@keyboard.Id::TEXT, shifttable[keycode - 1])
//   }

//   // match keycode {
//   //   @keyboard.arrowLeft| @keyboard.arrowRight| @keyboard.arrowUp| @keyboard.arrowDown => self.keymap[keycode].unwrap()
//   //   _ => Mapping::new(@keyboard.Id::NONE, 0)
//   // }
//   if keycode == @keyboard.arrowLeft || keycode == @keyboard.arrowRight || keycode == @keyboard.arrowUp ||
//   keycode == @keyboard.arrowDown {
//     return self.keymap[keycode].unwrap()
//   }
//   Mapping::new(@keyboard.Id::NONE, 0)
// }

///|
pub fn get_mapping(self : Keyboard, keycode : String) -> Mapping {
  self.keymap.get(keycode).or(Mapping::new(@keyboard.KeyType::NONE, 0))
}

///|
pub fn get_maple_mapping(self : Keyboard, key : Int) -> Mapping {
  self.maple_keys.get(key).or(Mapping::new(@keyboard.KeyType::NONE, 0))
}

///|
let keytable : FixedArray[String] = [
  "", "", @keyboard.digit0, @keyboard.digit1, @keyboard.digit2, @keyboard.digit3,
  @keyboard.digit4, @keyboard.digit5, @keyboard.digit6, @keyboard.digit7, @keyboard.digit8,
  @keyboard.digit9, @keyboard.minus, @keyboard.equal, "", "", @keyboard.keyQ, @keyboard.keyW,
  @keyboard.keyE, @keyboard.keyR, @keyboard.keyT, @keyboard.keyY, @keyboard.keyU,
  @keyboard.keyI, @keyboard.keyO, @keyboard.keyP, @keyboard.bracketLeft, @keyboard.bracketRight,
  "", @keyboard.controlLeft, @keyboard.keyA, @keyboard.keyS, @keyboard.keyD, @keyboard.keyF,
  @keyboard.keyG, @keyboard.keyH, @keyboard.keyJ, @keyboard.keyK, @keyboard.keyL,
  @keyboard.semicolon, @keyboard.quote, @keyboard.backquote, @keyboard.shiftLeft,
  @keyboard.backslash, @keyboard.keyZ, @keyboard.keyX, @keyboard.keyC, @keyboard.keyV,
  @keyboard.keyB, @keyboard.keyN, @keyboard.keyM, @keyboard.comma, @keyboard.period,
  "", "", "", @keyboard.altLeft, @keyboard.space, "", @keyboard.f1, @keyboard.f2,
  @keyboard.f3, @keyboard.f4, @keyboard.f5, @keyboard.f6, @keyboard.f7, @keyboard.f8,
  @keyboard.f9, @keyboard.f10, @keyboard.f11, @keyboard.f12, @keyboard.home, "",
  @keyboard.pageUp, "", "", "", "", "", @keyboard.end, @keyboard.capsLock, @keyboard.pageDown,
  @keyboard.insert, @keyboard.delete, @keyboard.escape, @keyboard.controlRight, @keyboard.shiftRight,
  @keyboard.altRight, @keyboard.scrollLock,
]
