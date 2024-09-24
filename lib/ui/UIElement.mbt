typealias Sprite = @graphics.Sprite

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
} derive(Eq, Compare)

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

pub fn int_value(self : UIElementType) -> Int {
  match self {
    UI_ELEMENT_NONE => 0
    START => 1
    LOGIN => 2
    TOS => 3
    GENDER => 4
    WORLD_SELECT => 5
    REGION => 6
    UI_ELEMENT_CHAR_SELECT => 7
    LOGIN_WAIT => 8
    UI_ELEMENT_RACE_SELECT => 9
    CLASS_CREATION => 10
    SOFT_KEYBOARD => 11
    LOGIN_NOTICE => 12
    LOGIN_NOTICE_CONFIRM => 13
    STATUS_MESSENGER => 14
    STATUS_BAR => 15
    CHAT_BAR => 16
    BUFF_LIST => 17
    NOTICE => 18
    NPC_TALK => 19
    SHOP => 20
    STATS_INFO => 21
    ITEM_INVENTORY => 22
    EQUIP_INVENTORY => 23
    SKILL_BOOK => 24
    QUEST_LOG => 25
    WORLD_MAP => 26
    USER_LIST => 27
    MINI_MAP => 28
    CHANNEL => 29
    CHAT => 30
    CHAT_RANK => 31
    JOYPAD => 32
    EVENT => 33
    KEY_CONFIG => 34
    OPTION_MENU => 35
    QUIT => 36
    CHAR_INFO => 37
    CASHSHOP => 38
    GAUGE_BOSS => 39
    NOTIFICATION => 40
    TRADE => 41
  }
}

pub fn hash(self : UIElementType) -> Int {
  self.int_value()
}

pub fn hash_combine(self : UIElementType, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

pub trait UIElement {
  get_ui_element_base(Self) -> UIElementBase
  send_cursor(Self, Bool, Point[Int]) -> CursorState
  send_key(Self, Int, Bool, Bool) -> Unit
  get_type(Self) -> UIElementType
  is_in_range(Self, Point[Int]) -> Bool
  toggle_active(Self) -> Unit
  remove_cursor(Self) -> Unit
  draw(Self, Double) -> Unit
  update(Self) -> Unit
}

pub trait UIElementDescriptor {
  const_type() -> UIElementType
  const_toggled() -> Bool
  const_focused() -> Bool
}

pub struct UIElementBase {
  sprites : Array[Sprite]
  mut position : Point[Int]
  mut dimension : Point[Int]
  mut active : Bool
}

pub fn UIElementBase::new(
  p : Point[Int],
  d : Point[Int],
  ~active : Bool = true
) -> UIElementBase {
  { position: p, dimension: d, active, sprites: [] }
}

pub fn UIElementBase::default() -> UIElementBase {
  UIElementBase::new(Point::default(), Point::default())
}

pub fn draw(self : UIElementBase, alpha : Double) -> Unit {
  self.sprites.each(fn(sprite) { sprite.draw(self.position, alpha) })
}

pub fn update(self : UIElementBase) -> Unit {
  self.sprites.each(fn(sprite) { sprite.update() |> ignore })
}

pub fn makeactive(self : UIElementBase) -> Unit {
  self.active = true
}

pub fn deactivate(self : UIElementBase) -> Unit {
  self.active = false
}

pub fn is_active(self : UIElementBase) -> Bool {
  self.active
}

pub fn toggle_active(self : UIElementBase) -> Unit {
  if self.active {
    self.deactivate()
  } else {
    self.makeactive()
  }
}

pub fn is_in_range(self : UIElementBase, cursorpos : Point[Int]) -> Bool {
  let bounds = @struct.Rectangle::new(
    self.position,
    self.position + self.dimension,
  )
  bounds.contains(cursorpos)
}
