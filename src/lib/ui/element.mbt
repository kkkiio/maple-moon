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
pub(open) trait Widget {
  /// declarative ui interface
  render(Self) -> RenderSpec
}

///|
pub(all) struct RenderSpec {
  render_elements : Array[RenderElement]
}

///|
pub(open) trait RenderUnit: ToJson + @graphics.Drawable {
  update(Self) -> Unit
}

///|
pub(all) enum RenderElement {
  Static(&RenderUnit)
  Interactable(&RenderUnit, InteractiveArea)
} derive(ToJson)

///|
pub(all) struct InteractiveArea {
  bounds : @struct.Rectangle[Int]
  on_click : () -> Unit
  on_double_click : () -> Unit // send after on_click
  state : Ref[ButtonState]
}

///|
pub impl ToJson for InteractiveArea with to_json(self) -> Json {
  { "bounds": self.bounds.to_json() }
}

///|
pub impl ToJson for RenderSpec with to_json(self) -> Json {
  { "render_elements": self.render_elements.to_json() }
}

///|
pub(all) struct Hooks {
  ui_model : UIModel
  on_state_changed : () -> Unit
}

///|
pub fn Hooks::default() -> Hooks {
  {
    ui_model: UIModel::new(Point::default(), Point::default()),
    on_state_changed: fn() {  },
  }
}

///|
pub fn on_state_changed(self : Hooks) -> Unit {
  (self.on_state_changed)()
}

///|
type EffectHook[T] Ref[T?]

///|
pub fn[T] EffectHook::new() -> EffectHook[T] {
  Ref::new(None)
}

///|
pub fn[T : Eq] use_effect(
  self : EffectHook[T],
  key : T,
  f : () -> Unit
) -> Unit {
  match self.val {
    Some(k) => if k == key { return }
    None => ()
  }
  self.val = Some(key)
  f()
}

///|
pub(open) trait UIElementDescriptor {
  const_type() -> UIElementType
  const_toggled() -> Bool
  const_focused() -> Bool
}

///|
pub(all) struct Element {
  key : UIElementType
  ui_model : UIModel
  object : &Widget
  toggle_active : () -> Unit
  on_close : () -> Unit
  runtime_state : Ref[RuntimeState?]
}

///|
struct RuntimeState {
  render_units : Array[&RenderUnit]
  interactables : Array[InteractiveArea]
}

///|
pub fn[T : Widget] Element::new(
  make_element : (Hooks) -> T,
  key : UIElementType,
  toggle_active? : () -> Unit,
  on_close? : () -> Unit
) -> Element {
  let runtime_state = Ref::new(None)
  let ui_model = UIModel::new(Point::default(), Point::default())
  let hooks = { ui_model, on_state_changed: fn() { runtime_state.val = None } }
  let object = make_element(hooks)
  {
    key,
    ui_model,
    object,
    toggle_active: toggle_active.or(fn() { ui_model.toggle_active() }),
    on_close: on_close.or(fn() {  }),
    runtime_state,
  }
}

///|
pub fn Element::get_ui_model(self : Element) -> UIModel {
  self.ui_model
}

///|
pub fn Element::draw(self : Element) -> Unit {
  let pos = self.get_ui_model().position
  for ru in self.use_drawables() {
    ru.draw(@graphics.DrawArgument::new(pos~))
  }
}

///|
pub fn Element::update(self : Element) -> Unit {
  for ru in self.use_updateables() {
    ru.update()
  }
}

///|
pub fn Element::send_cursor(
  self : Element,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> CursorState {
  send_cursor_to_areas(
    self.use_interactables(),
    self.get_ui_model().position,
    pressed,
    cursorpos,
  )
}

///|
pub fn Element::is_in_interactive_area(
  self : Element,
  cursorpos : Point[Int]
) -> Bool {
  let areas = self.use_interactables()
  let container_pos = self.get_ui_model().position
  let matches = areas.filter(fn(area) { // WARN: performance
    area.bounds.shift(container_pos).contains(cursorpos)
  })
  matches.head() is Some(_)
}

///|
pub fn Element::doubleclick(self : Element, pos : @struct.Point[Int]) -> Bool {
  let areas = self.use_interactables()
  let container_pos = self.get_ui_model().position
  let matches = areas.filter(fn(area) {
    area.bounds.shift(container_pos).contains(pos)
  }) // WARN: performance
  let mut clicked = false
  for area in matches {
    (area.on_double_click)()
    clicked = true
  }
  clicked
}

///|
fn use_runtime_state(self : Element) -> RuntimeState {
  match self.runtime_state.val {
    Some(rs) => rs
    None => {
      let rs = self.object.render()
      let render_units = rs.render_elements
        .iter()
        .map(fn(re) {
          match re {
            RenderElement::Static(ru) => ru
            RenderElement::Interactable(ru, _) => ru
          }
        })
        .to_array()
      let interactables = rs.render_elements
        .iter()
        .filter_map(fn(re) {
          match re {
            RenderElement::Interactable(_, ia) => Some(ia)
            RenderElement::Static(_) => None
          }
        })
        .to_array()
      let rs = { render_units, interactables }
      self.runtime_state.val = Some(rs)
      rs
    }
  }
}

///|
fn use_drawables(self : Element) -> Iter[&@graphics.Drawable] {
  self.use_runtime_state().render_units.iter().map(fn(ru) { ru })
}

///|
fn use_interactables(self : Element) -> Iter[InteractiveArea] {
  self.use_runtime_state().interactables.iter()
}

///|
fn use_updateables(self : Element) -> Iter[&RenderUnit] {
  self.use_runtime_state().render_units.iter()
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
pub fn UIModel::is_active(self : UIModel) -> Bool {
  self.active
}

///|
pub fn UIModel::toggle_active(self : UIModel) -> Unit {
  if self.active {
    self.deactivate()
  } else {
    self.makeactive()
  }
}

///|
struct StaticUI[T] {
  drawable : T
  args : @graphics.DrawArgument
}

///|
pub fn[T] StaticUI::new(
  text : T,
  pos~ : Point[Int] = Point::default(), // relative to the parent
  stretch~ : Point[Int] = Point::default()
) -> StaticUI[T] {
  { drawable: text, args: @graphics.DrawArgument::new_ex(pos~, stretch~) }
}

///|
pub fn[T] StaticUI::new_ex(
  text : T,
  args~ : @graphics.DrawArgument = @graphics.DrawArgument::default()
) -> StaticUI[T] {
  { drawable: text, args }
}

///|
pub impl[T : @graphics.Drawable] @graphics.Drawable for StaticUI[T] with draw(
  self,
  args
) -> Unit {
  self.drawable.draw(args.merge(self.args))
}

///|
pub impl[T : @graphics.Drawable + ToJson] RenderUnit for StaticUI[T] with update(
  self
) -> Unit {
  ignore(self)
}

///|
pub impl[T : ToJson] ToJson for StaticUI[T] with to_json(self) -> Json {
  { "drawable": self.drawable.to_json(), "args": self.args.to_json() }
}

///|
pub(all) type SpriteUI @graphics.Sprite

///|
pub impl @graphics.Drawable for SpriteUI with draw(self, args) -> Unit {
  self._.draw(args.pos, 0)
}

///|
pub impl RenderUnit for SpriteUI with update(self) -> Unit {
  self._.update() |> ignore
}

///|
pub impl ToJson for SpriteUI with to_json(self) -> Json {
  self._.to_json()
}

///|
pub(all) type TextureTextUI @graphics.TextureText derive(ToJson)

///|
pub impl @graphics.Drawable for TextureTextUI with draw(self, args) -> Unit {
  self._.draw(args) |> ignore
}

///|
pub(all) type TextureUI @graphics.Texture derive(ToJson)

///|
pub impl @graphics.Drawable for TextureUI with draw(self, args) -> Unit {
  self._.draw(args)
}

///|
pub(all) type TextUI @graphics.Text derive(ToJson)

///|
pub impl @graphics.Drawable for TextUI with draw(self, args) -> Unit {
  self._.draw(args.pos)
}

///|
type OffsetedUnit[T] (T, Point[Int]) derive(ToJson)

///|
pub fn[T] OffsetedUnit::new(unit : T, pos : Point[Int]) -> OffsetedUnit[T] {
  (unit, pos)
}

///|
pub fn OffsetedUnit::offset_element(
  element : RenderElement,
  pos : Point[Int]
) -> RenderElement {
  match element {
    RenderElement::Static(ru) =>
      RenderElement::Static(OffsetedUnit::new(ru, pos))
    RenderElement::Interactable(ru, ia) =>
      RenderElement::Interactable(OffsetedUnit::new(ru, pos), ia)
  }
}

///|
pub impl[T : @graphics.Drawable] @graphics.Drawable for OffsetedUnit[T] with draw(
  self,
  args
) -> Unit {
  self.0.draw(args.add_pos(self.1))
}

///|
pub impl[T : RenderUnit] RenderUnit for OffsetedUnit[T] with update(self) -> Unit {
  self.0.update()
}

///|
type StaticUnit[T] T derive(ToJson)

///|
pub fn[T] StaticUnit::new(unit : T) -> StaticUnit[T] {
  unit
}

///|
pub impl[T : @graphics.Drawable] @graphics.Drawable for StaticUnit[T] with draw(
  self,
  args
) -> Unit {
  self._.draw(args)
}

///|
pub impl[T : @graphics.Drawable] RenderUnit for StaticUnit[T] with update(self) -> Unit {
  ignore(self)
}
