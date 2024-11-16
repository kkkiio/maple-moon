pub enum UIElementType {
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

pub(open) trait UIElement {
  get_ui_model(Self) -> UIModel
  send_cursor(Self, Bool, Point[Int]) -> CursorState
  send_key(Self, Int, Bool, Bool) -> Unit
  remove_cursor(Self) -> Unit
  draw(Self, Double) -> Unit
  update(Self) -> Unit
}

pub(open) trait UIElementDescriptor {
  const_type() -> UIElementType
  const_toggled() -> Bool
  const_focused() -> Bool
}

pub struct Element {
  object : UIElement
  key : UIElementType
  doubleclick : ((Point[Int]) -> Unit)?
  toggle_active : () -> Unit
  on_close : () -> Unit
}

pub fn Element::new(
  object : UIElement,
  key : UIElementType,
  ~doubleclick? : (Point[Int]) -> Unit,
  ~toggle_active? : () -> Unit,
  ~on_close? : () -> Unit
) -> Element {
  {
    object,
    key,
    doubleclick,
    toggle_active: toggle_active.or(
      fn() { object.get_ui_model().toggle_active() },
    ),
    on_close: on_close.or(fn() {  }),
  }
}

pub struct UIModel {
  mut position : Point[Int]
  mut dimension : Point[Int]
  mut active : Bool
}

pub fn UIModel::new(
  position : Point[Int],
  dimension : Point[Int],
  ~active : Bool = true
) -> UIModel {
  { position, dimension, active }
}

pub fn draw_sprites(
  sprites : Iter[@graphics.Sprite],
  position : Point[Int],
  alpha : Double
) -> Unit {
  sprites.each(fn(sprite) { sprite.draw(position, alpha) })
}

pub fn update_sprites(sprites : Iter[@graphics.Sprite]) -> Unit {
  sprites.each(fn(sprite) { sprite.update() |> ignore })
}

pub fn makeactive(self : UIModel) -> Unit {
  self.active = true
}

pub fn deactivate(self : UIModel) -> Unit {
  self.active = false
}

pub fn is_active(self : UIModel) -> Bool {
  self.active
}

pub fn toggle_active(self : UIModel) -> Unit {
  if self.active {
    self.deactivate()
  } else {
    self.makeactive()
  }
}

pub fn is_in_range(self : UIModel, cursorpos : Point[Int]) -> Bool {
  let bounds = @struct.Rectangle::new(
    self.position,
    self.position + self.dimension,
  )
  bounds.contains(cursorpos)
}
