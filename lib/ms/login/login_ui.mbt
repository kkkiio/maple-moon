///|
enum UILoginButtons {
  BT_LOGIN
  BT_REGISTER
  BT_HOMEPAGE
  BT_PASSLOST
  BT_IDLOST
  BT_SAVEID
  BT_QUIT
} derive(Eq, Compare)

///|
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

///|
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

///|
struct UILogin {
  base : @ui.UIModel
  sprites : Array[@graphics.Sprite]
  // mut version : Text
  // mut account : Textfield
  // mut password : Textfield
  // mut accountbg : Texture
  // mut passwordbg : Texture
  // mut checkbox : BoolPair[Texture]
  mut saveid : Bool
}

///|
typealias Point[T] = @struct.Point[T]

///|
pub fn UILogin::new(
  mod : Module,
  map : @resource.NxNode,
  pretty_logo : @resource.NxNode
) -> UILogin {
  let back = map["back"]
  let ani = map["ani"]
  let title = @ui.common_ui_loader().load_res(["Login.img", "Title"])
  let common = @ui.common_ui_loader().load_res(["Login.img", "Common"])
  let sprites = [
    @graphics.Sprite::from_resource(
      back["11"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(400, 300)),
    ),
    @graphics.Sprite::from_resource(
      ani["17"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(129, 283)),
    ),
    @graphics.Sprite::from_resource(
      ani["18"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(306, 252)),
    ),
    @graphics.Sprite::from_resource(
      ani["19"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(379, 207)),
    ),
    @graphics.Sprite::from_resource(
      back["35"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(399, 260)),
    ),
    @graphics.Sprite::from_resource(
      pretty_logo,
      state_args=@graphics.DrawArgument::new(pos=Point::new(394, 173)),
    ),
    @graphics.Sprite::from_resource(
      title["signboard"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(391, 330)),
    ),
    @graphics.Sprite::from_resource(
      common["frame"],
      state_args=@graphics.DrawArgument::new(pos=Point::new(400, 300)),
    ),
  ]
  let obj = {
    base: @ui.UIModel::new(Point::new(0, 0), @struct.Point::new(800, 600)),
    sprites,
    saveid: false,
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

  // obj.base.buttons[UILoginButtons::BT_LOGIN.int_value()] = MapleButton::new(
  //   title["BtLogin"],
  //   @struct.Point::new(454, 279),
  // )
  // obj.base.buttons[UILoginButtons::BT_SAVEID.int_value()] = MapleButton::new(
  //   title["BtLoginIDSave"],
  //   @struct.Point::new(303, 332),
  // )
  // obj.base.buttons[UILoginButtons::BT_IDLOST.int_value()] = MapleButton::new(
  //   title["BtLoginIDLost"],
  //   @struct.Point::new(375, 332),
  // )
  // obj.base.buttons[UILoginButtons::BT_PASSLOST.int_value()] = MapleButton::new(
  //   title["BtPasswdLost"],
  //   @struct.Point::new(447, 332),
  // )
  // obj.base.buttons[UILoginButtons::BT_REGISTER.int_value()] = MapleButton::new(
  //   title["BtNew"],
  //   @struct.Point::new(291, 352),
  // )
  // obj.base.buttons[UILoginButtons::BT_HOMEPAGE.int_value()] = MapleButton::new(
  //   title["BtHomePage"],
  //   @struct.Point::new(363, 352),
  // )
  // obj.base.buttons[UILoginButtons::BT_QUIT.int_value()] = MapleButton::new(
  //   title["BtQuit"],
  //   @struct.Point::new(435, 352),
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
  mod.login("kkkiio", "kkkiio") // TODO: allow select account
  obj
}

///|
pub fn get_ui_model(self : UILogin) -> @ui.UIModel {
  self.base
}

///|
impl @ui.Widget for UILogin with render(self) -> @ui.RenderSpec {
  let sprites = self.sprites
  {
    render_elements: sprites.map(fn(sprite) {
      @ui.SpriteUI(sprite) |> @ui.RenderElement::Static
    }),
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

///|
pub fn button_pressed(self : UILogin, id : Int) -> @ui.ButtonState {
  match UILoginButtons::from_int(id) {
    Some(UILoginButtons::BT_LOGIN) =>
      // self.login()
      @ui.ButtonState::NORMAL
    // UILoginButtons::BT_REGISTER | UILoginButtons::BT_HOMEPAGE | UILoginButtons::BT_PASSLOST | UILoginButtons::BT_IDLOST => {
    //   self.open_url(id)
    //   ButtonState::NORMAL
    // }
    Some(UILoginButtons::BT_SAVEID) => {
      self.saveid = not(self.saveid)
      // Setting::get(configSaveLogin).save(self.saveid)
      @ui.ButtonState::MOUSEOVER
    }
    Some(UILoginButtons::BT_QUIT) =>
      // UI::get().quit()
      @ui.ButtonState::PRESSED
    _ => @ui.ButtonState::NORMAL
  }
}

///|
pub fn UILogin::const_type() -> @ui.UIElementType {
  @ui.UIElementType::LOGIN
}

///|
pub fn UILogin::const_focused() -> Bool {
  false
}

///|
pub fn UILogin::const_toggled() -> Bool {
  false
}

///|
pub fn send_key(
  self : UILogin,
  key : Int,
  pressed : Bool,
  repeat : Bool
) -> Unit {

}

///|
pub fn is_active(self : UILogin) -> Bool {
  self.base.is_active()
}

///|
pub fn remove_cursor(self : UILogin) -> Unit {

}

///|
pub fn deactivate(self : UILogin) -> Unit {
  self.base.deactivate()
}
