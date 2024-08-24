enum UILoginButtons {
  BT_LOGIN
  BT_REGISTER
  BT_HOMEPAGE
  BT_PASSLOST
  BT_IDLOST
  BT_SAVEID
  BT_QUIT
} derive(Eq, Compare)

pub fn int_value(self : UILoginButtons) -> Int {
  match self {
    BT_LOGIN => 0
    BT_REGISTER => 1
    BT_HOMEPAGE => 2
    BT_PASSLOST => 3
    BT_IDLOST => 4
    BT_SAVEID => 5
    BT_QUIT => 6
  }
}

pub fn UILoginButtons::from_int(i : Int) -> UILoginButtons? {
  match i {
    0 => BT_LOGIN |> Some
    1 => BT_REGISTER |> Some
    2 => BT_HOMEPAGE |> Some
    3 => BT_PASSLOST |> Some
    4 => BT_IDLOST |> Some
    5 => BT_SAVEID |> Some
    6 => BT_QUIT |> Some
    _ => None
  }
}

enum LoginStage {
  INIT
  START_SEND
  LOGIN_SEND
}

struct UILogin {
  base : UIElementBase
  buttons : UIButtons
  // mut version : Text
  // mut account : Textfield
  // mut password : Textfield
  // mut accountbg : Texture
  // mut passwordbg : Texture
  // mut checkbox : BoolPair[Texture]
  mut saveid : Bool
  mut login_stage : LoginStage
}

let map001_loader = @resource.map001_loader

let map_pretty_loader = @resource.map_pretty_loader

pub fn UILogin::new() -> UILogin {
  let obj = {
    base: UIElementBase::new(Point::new(0, 0), Point::new(800, 600)),
    buttons: UIButtons::default(),
    saveid: false,
    login_stage: INIT,
  }
  // version: Text::new(),
  // account: Textfield::new(),
  // password: Textfield::new(),
  // accountbg: Texture::new(),
  // passwordbg: Texture::new(),
  // checkbox: BoolPair::new(Texture::new(), Texture::new()),
  // Music("BgmUI.img/Title").play()

  // let version_text = Configuration::get().get_version()
  // obj.version = Text::new(Text::Font::A11M, Text::Alignment::LEFT, Color::Name::LEMONGRASS, "Ver. " + version_text)

  let map001_loader = map001_loader()
  let map = map001_loader.load_res(["Back", "login.img"])
  let back = map["back"]
  let ani = map["ani"]
  let ui_loader = ui_loader()
  let title = ui_loader.load_res(["Login.img", "Title"])
  let common = ui_loader.load_res(["Login.img", "Common"])
  let map_pretty_loader = map_pretty_loader()
  let prettyLogo = map_pretty_loader.load_res(
    ["Back", "login.img", "ani", "16"],
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      back["11"],
      DrawArgument::from_point(Point::new(400, 300)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      ani["17"],
      DrawArgument::from_point(Point::new(129, 283)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      ani["18"],
      DrawArgument::from_point(Point::new(306, 252)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      ani["19"],
      DrawArgument::from_point(Point::new(379, 207)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      back["35"],
      DrawArgument::from_point(Point::new(399, 260)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      prettyLogo,
      DrawArgument::from_point(Point::new(394, 173)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      title["signboard"],
      DrawArgument::from_point(Point::new(391, 330)),
    ),
  )
  obj.base.sprites.push(
    new_sprite_from_node(
      common["frame"],
      DrawArgument::from_point(Point::new(400, 300)),
    ),
  )
  // obj.base.buttons[UILoginButtons::BT_LOGIN.int_value()] = MapleButton::new(
  //   title["BtLogin"],
  //   Point::new(454, 279),
  // )
  // obj.base.buttons[UILoginButtons::BT_SAVEID.int_value()] = MapleButton::new(
  //   title["BtLoginIDSave"],
  //   Point::new(303, 332),
  // )
  // obj.base.buttons[UILoginButtons::BT_IDLOST.int_value()] = MapleButton::new(
  //   title["BtLoginIDLost"],
  //   Point::new(375, 332),
  // )
  // obj.base.buttons[UILoginButtons::BT_PASSLOST.int_value()] = MapleButton::new(
  //   title["BtPasswdLost"],
  //   Point::new(447, 332),
  // )
  // obj.base.buttons[UILoginButtons::BT_REGISTER.int_value()] = MapleButton::new(
  //   title["BtNew"],
  //   Point::new(291, 352),
  // )
  // obj.base.buttons[UILoginButtons::BT_HOMEPAGE.int_value()] = MapleButton::new(
  //   title["BtHomePage"],
  //   Point::new(363, 352),
  // )
  // obj.base.buttons[UILoginButtons::BT_QUIT.int_value()] = MapleButton::new(
  //   title["BtQuit"],
  //   Point::new(435, 352),
  // )

  // obj.checkbox[false] = title["check"]["0"]
  // obj.checkbox[true] = title["check"]["1"]

  // obj.account = Textfield::new(Text::Font::A13M, Text::Alignment::LEFT, Color::Name::WHITE, Rectangle[IntPoint[Int](296, 279), Point[Int](446, 303)), 12)
  // obj.account.set_key_callback(KeyAction::Id::TAB, || {
  //   obj.account.set_state(Textfield::State::NORMAL)
  //   obj.password.set_state(Textfield::State::FOCUSED)
  // })
  // obj.account.set_enter_callback(|| obj.login())
  // obj.accountbg = title["ID"]

  // obj.password = Textfield::new(Text::Font::A13M, Text::Alignment::LEFT, Color::Name::WHITE, Rectangle[IntPoint[Int](296, 305), Point[Int](446, 329)), 12)
  // obj.password.set_key_callback(KeyAction::Id::TAB, || {
  //   obj.account.set_state(Textfield::State::FOCUSED)
  //   obj.password.set_state(Textfield::State::NORMAL)
  // })
  // obj.password.set_enter_callback(|| obj.login())
  // obj.password.set_cryptchar('*')
  // obj.passwordbg = title["PW"]

  // obj.saveid = Setting[SaveLogin]::get().load()
  // if obj.saveid {
  //   obj.account.change_text(Setting[DefaultAccount]::get().load())
  //   obj.password.set_state(Textfield::State::FOCUSED)
  // } else {
  //   obj.account.set_state(Textfield::State::FOCUSED)
  // }

  obj
}

pub fn get_ui_element_base(self : UILogin) -> UIElementBase {
  self.base
}

pub fn draw(self : UILogin, alpha : Double) -> Unit {
  self.base.draw(alpha)

  // self.version.draw(self.position + Point[Int](707, 1))
  // self.account.draw(self.position)
  // self.password.draw(self.position)

  // if self.account.get_state() == Textfield::State::NORMAL && self.account.empty() {
  //   self.accountbg.draw(DrawArgument(self.position + Point[Int](291, 279)))
  // }

  // if self.password.get_state() == Textfield::State::NORMAL && self.password.empty() {
  //   self.passwordbg.draw(DrawArgument(self.position + Point[Int](291, 305)))
  // }

  // self.checkbox[self.saveid].draw(DrawArgument(self.position + Point[Int](291, 335)))
}

pub fn update(self : UILogin) -> Unit {
  self.base.update()
  let p = @net.PacketProcessor::get()
  match p.get_status() {
    READY =>
      match self.login_stage {
        INIT => {
          fn_login_start()
          self.login_stage = START_SEND
        }
        START_SEND => { // UI::get().emplace(UILoginWait::new(|| {}))
          // let loginwait = UI::get().get_element[UILoginWait]()
          // if loginwait && loginwait.get().is_active() {
          fn_login("kkkiio", "kkkiio")
          self.login_stage = LOGIN_SEND
        }
        LOGIN_SEND => ()
      }
    OPENED => ()
    CLOSED => {
      p.connect_login()
      self.login_stage = INIT
    }
  }
}

// pub fn login(self : UILogin) -> Unit {
//   // let okhandler = || {
//   //   self.account.set_state(Textfield::State::NORMAL)
//   //   self.password.set_state(Textfield::State::NORMAL)

//   //   if !password_text.empty() {
//   //     self.password.set_state(Textfield::State::FOCUSED)
//   //   } else {
//   //     self.account.set_state(Textfield::State::FOCUSED)
//   //   }
//   // }

//   // UI::get().emplace(UILoginWait::new(okhandler))

//   // let loginwait = UI::get().get_element[UILoginWait]()

//   // if loginwait && loginwait.get().is_active() {
//   //   fn_login(account_text, password_text)
//   // }
// }

pub fn button_pressed(self : UILogin, id : Int) -> ButtonState {
  match UILoginButtons::from_int(id) {
    Some(UILoginButtons::BT_LOGIN) =>
      // self.login()
      ButtonState::NORMAL
    // UILoginButtons::BT_REGISTER | UILoginButtons::BT_HOMEPAGE | UILoginButtons::BT_PASSLOST | UILoginButtons::BT_IDLOST => {
    //   self.open_url(id)
    //   ButtonState::NORMAL
    // }
    Some(UILoginButtons::BT_SAVEID) => {
      self.saveid = self.saveid.not()
      // Setting::get(configSaveLogin).save(self.saveid)
      ButtonState::MOUSEOVER
    }
    Some(UILoginButtons::BT_QUIT) =>
      // UI::get().quit()
      ButtonState::PRESSED
    _ => ButtonState::NORMAL
  }
}

pub fn send_cursor(
  self : UILogin,
  clicked : Bool,
  cursor_pos : Point[Int]
) -> CursorState {
  // match self.account.send_cursor(cursor_pos, clicked) {
  //   Some(new_state) => return new_state
  //   None => ()
  // }
  // match self.password.send_cursor(cursor_pos, clicked) {
  //   Some(new_state) => return new_state
  //   None => ()
  // }
  self.buttons.send_cursor(
    self.base.position,
    fn(bid) { self.button_pressed(bid) },
    clicked,
    cursor_pos,
  )
}

pub fn get_type(self : UILogin) -> UIElementType {
  self |> ignore
  UIElementType::LOGIN
}

pub fn UILogin::const_type() -> UIElementType {
  UIElementType::LOGIN
}

pub fn UILogin::const_focused() -> Bool {
  false
}

pub fn UILogin::const_toggled() -> Bool {
  false
}

pub fn send_key(
  self : UILogin,
  key : Int,
  pressed : Bool,
  repeat : Bool
) -> Unit {

}

pub fn is_active(self : UILogin) -> Bool {
  self.base.is_active()
}

pub fn is_in_range(self : UILogin, pos : Point[Int]) -> Bool {
  self.base.is_in_range(pos)
}

pub fn toggle_active(self : UILogin) -> Unit {
  self.base.toggle_active()
}

pub fn remove_cursor(self : UILogin) -> Unit {
  self.buttons.remove_cursor()
}

pub fn deactivate(self : UILogin) -> Unit {
  self.base.deactivate()
}

fn doubleclick(self : UILogin, point : Point[Int]) -> Unit {

}

fn fn_login_start() -> Unit {
  @login.new_login_start_packet().dispatch()
}

fn fn_login(account : String, password : String) -> Unit {
  @login.new_login_packet(account, password).dispatch()
}
