///|
typealias Point[T] = @struct.Point[T]

///|
pub(all) enum UIElementType {
  UI_ELEMENT_NONE
  START
  LOGIN
  TOS
  GENDER
  WORLD_SELECT
  REGION
  UI_ELEMENT_CHAR_SELECT
  LOGIN_WAIT
  UI_ELEMENT_RACE_SELECT
  CLASS_CREATION
  SOFT_KEYBOARD
  LOGIN_NOTICE
  LOGIN_NOTICE_CONFIRM
  STATUS_MESSENGER
  STATUS_BAR
  CHAT_BAR
  BUFF_LIST
  NOTICE
  NPC_TALK
  SHOP
  STATS_INFO
  ITEM_INVENTORY
  EQUIP_INVENTORY
  SKILL_BOOK
  QUEST_LOG
  WORLD_MAP
  USER_LIST
  MINI_MAP
  CHANNEL
  CHAT
  CHAT_RANK
  JOYPAD
  EVENT
  KEY_CONFIG
  OPTION_MENU
  QUIT
  CHAR_INFO
  CASHSHOP
  GAUGE_BOSS
  NOTIFICATION
  TRADE
} derive(Eq, Compare, Hash)

///|
pub let all_types : FixedArray[UIElementType] = [
  UI_ELEMENT_NONE,
  START,
  LOGIN,
  TOS,
  GENDER,
  WORLD_SELECT,
  REGION,
  UI_ELEMENT_CHAR_SELECT,
  LOGIN_WAIT,
  UI_ELEMENT_RACE_SELECT,
  CLASS_CREATION,
  SOFT_KEYBOARD,
  LOGIN_NOTICE,
  LOGIN_NOTICE_CONFIRM,
  STATUS_MESSENGER,
  STATUS_BAR,
  CHAT_BAR,
  BUFF_LIST,
  NOTICE,
  NPC_TALK,
  SHOP,
  STATS_INFO,
  ITEM_INVENTORY,
  EQUIP_INVENTORY,
  SKILL_BOOK,
  QUEST_LOG,
  WORLD_MAP,
  USER_LIST,
  MINI_MAP,
  CHANNEL,
  CHAT,
  CHAT_RANK,
  JOYPAD,
  EVENT,
  KEY_CONFIG,
  OPTION_MENU,
  QUIT,
  CHAR_INFO,
  CASHSHOP,
  GAUGE_BOSS,
  NOTIFICATION,
  TRADE,
]

///|
pub(open) trait UIElement {
  get_ui_model(Self) -> UIModel
  send_key(Self, Int, Bool, Bool) -> Unit
  remove_cursor(Self) -> Unit
  render(Self) -> RenderSpec
}

///|
pub(all) struct RenderSpec {
  render_units : Array[&RenderUnit]
}

///|
pub(open) trait Drawable {
  draw(Self, @struct.Point[Int]) -> Unit
}

///|
pub(open) trait RenderUnit: ToJson + Drawable {
  update(Self) -> Unit
  get_interactive_area(Self) -> InteractiveArea?
}

///|
pub(all) struct InteractiveArea {
  bounds : @struct.Rectangle[Int]
  on_click : () -> Unit
  state : Ref[ButtonState]
}

///|
pub impl ToJson for RenderSpec with to_json(self) -> Json {
  { "render_units": self.render_units.to_json() }
}

///|
pub(all) struct Hooks {
  on_state_changed : () -> Unit
  mut on_double_click : (Point[Int]) -> Unit
}

///|
pub fn Hooks::default() -> Hooks {
  { on_state_changed: fn() {  }, on_double_click: fn(_p) {  } }
}

///|
pub(open) trait UIElementDescriptor {
  const_type() -> UIElementType
  const_toggled() -> Bool
  const_focused() -> Bool
}

///|
pub(all) struct Element {
  object : &UIElement
  key : UIElementType
  doubleclick : (Point[Int]) -> Unit
  toggle_active : () -> Unit
  on_close : () -> Unit
  runtime_state : Ref[RenderSpec?]
}

///|
pub fn Element::new[T : UIElement](
  make_element : (Hooks) -> T,
  key : UIElementType,
  toggle_active? : () -> Unit,
  on_close? : () -> Unit
) -> Element {
  let runtime_state = Ref::new(None)
  let hooks = {
    on_state_changed: fn() { runtime_state.val = None },
    on_double_click: fn(_p) {  },
  }
  let object = make_element(hooks)
  {
    object,
    key,
    doubleclick: hooks.on_double_click,
    toggle_active: toggle_active.or(fn() {
      object.get_ui_model().toggle_active()
    }),
    on_close: on_close.or(fn() {  }),
    runtime_state,
  }
}

///|
pub fn get_ui_model(self : Element) -> UIModel {
  self.object.get_ui_model()
}

///|
pub fn draw(self : Element) -> Unit {
  let pos = self.get_ui_model().position
  for ru in self.use_runtime_state().render_units {
    ru.draw(pos)
  }
}

///|
pub fn update(self : Element) -> Unit {
  let rs = self.use_runtime_state()
  for ru in rs.render_units {
    ru.update()
  }
}

///|
pub fn send_cursor(
  self : Element,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> CursorState {
  let rs = self.use_runtime_state()
  send_cursor_to_areas(
    rs.render_units.iter().map_option(fn(ru) { ru.get_interactive_area() }),
    self.get_ui_model().position,
    pressed,
    cursorpos,
  )
}

///|
fn use_runtime_state(self : Element) -> RenderSpec {
  match self.runtime_state.val {
    Some(rs) => rs
    None => {
      let render_state = self.object.render()
      self.runtime_state.val = Some(render_state)
      render_state
    }
  }
}

///|
pub(all) struct UIModel {
  mut position : Point[Int]
  mut dimension : Point[Int]
  mut active : Bool
}

///|
pub fn UIModel::new(
  position : Point[Int],
  dimension : Point[Int],
  active~ : Bool = true
) -> UIModel {
  { position, dimension, active }
}

///|
pub fn draw_sprites(
  sprites : Iter[@graphics.Sprite],
  position : Point[Int],
  alpha : Double
) -> Unit {
  sprites.each(fn(sprite) { sprite.draw(position, alpha) })
}

///|
pub fn update_sprites(sprites : Iter[@graphics.Sprite]) -> Unit {
  sprites.each(fn(sprite) { sprite.update() |> ignore })
}

///|
pub fn makeactive(self : UIModel) -> Unit {
  self.active = true
}

///|
pub fn deactivate(self : UIModel) -> Unit {
  self.active = false
}

///|
pub fn is_active(self : UIModel) -> Bool {
  self.active
}

///|
pub fn toggle_active(self : UIModel) -> Unit {
  if self.active {
    self.deactivate()
  } else {
    self.makeactive()
  }
}

///|
pub fn is_in_range(self : UIModel, cursorpos : Point[Int]) -> Bool {
  let bounds = @struct.Rectangle::new(
    self.position,
    self.position + self.dimension,
  )
  bounds.contains(cursorpos)
}

///|
struct StaticUI[T] {
  drawable : T
  pos : Point[Int]
}

///|
pub fn StaticUI::new[T](
  text : T,
  pos~ : Point[Int] = Point::default()
) -> StaticUI[T] {
  { drawable: text, pos }
}

///|
pub impl[T : Drawable] Drawable for StaticUI[T] with draw(self, pos) -> Unit {
  self.drawable.draw(pos + self.pos)
}

///|
pub impl[T : Drawable + ToJson] RenderUnit for StaticUI[T] with update(self) -> Unit {
  ignore(self)
}

///|
pub impl[T : Drawable + ToJson] RenderUnit for StaticUI[T] with get_interactive_area(
  self
) -> InteractiveArea? {
  ignore(self)
  None
}

///|
pub impl[T : ToJson] ToJson for StaticUI[T] with to_json(self) -> Json {
  { "drawable": self.drawable.to_json(), "pos": self.pos.to_json() }
}

///|
pub(all) type SpriteUI @graphics.Sprite

///|
pub impl Drawable for SpriteUI with draw(self, pos) -> Unit {
  self._.draw(pos, 0)
}

///|
pub impl RenderUnit for SpriteUI with update(self) -> Unit {
  self._.update() |> ignore
}

///|
pub impl RenderUnit for SpriteUI with get_interactive_area(self) -> InteractiveArea? {
  self |> ignore
  None
}

///|
pub impl ToJson for SpriteUI with to_json(self) -> Json { self._.to_json() }

///|
pub(all) type TextureTextUI @graphics.TextureText derive(ToJson)

///|
pub impl Drawable for TextureTextUI with draw(self, position) -> Unit {
  self._.draw(@graphics.DrawArgument::new(position~)) |> ignore
}

///|
pub(all) type TextureUI @graphics.Texture derive(ToJson)

///|
pub impl Drawable for TextureUI with draw(self, position) -> Unit {
  self._.draw(@graphics.DrawArgument::new(position~))
}

///|
pub(all) type TextUI @graphics.Text derive(ToJson)

///|
pub impl Drawable for TextUI with draw(self, position) -> Unit {
  self._.draw(position)
}
