type Icon

type TooltipParent

pub enum UIElementType {
  NONE
  START
  LOGIN
  TOS
  GENDER
  WORLD_SELECT
  REGION
  CHAR_SELECT
  LOGIN_WAIT
  RACE_SELECT
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
} derive(Eq, Compare, Debug)

pub let all_types : @immut/sorted_map.Map[UIElementType, Int] = @immut/sorted_map.from_array(
  [
    (NONE, 0),
    (START, 1),
    (LOGIN, 2),
    (TOS, 3),
    (GENDER, 4),
    (WORLD_SELECT, 5),
    (REGION, 6),
    (CHAR_SELECT, 7),
    (LOGIN_WAIT, 8),
    (RACE_SELECT, 9),
    (CLASS_CREATION, 10),
    (SOFT_KEYBOARD, 11),
    (LOGIN_NOTICE, 12),
    (LOGIN_NOTICE_CONFIRM, 13),
    (STATUS_MESSENGER, 14),
    (STATUS_BAR, 15),
    (CHAT_BAR, 16),
    (BUFF_LIST, 17),
    (NOTICE, 18),
    (NPC_TALK, 19),
    (SHOP, 20),
    (STATS_INFO, 21),
    (ITEM_INVENTORY, 22),
    (EQUIP_INVENTORY, 23),
    (SKILL_BOOK, 24),
    (QUEST_LOG, 25),
    (WORLD_MAP, 26),
    (USER_LIST, 27),
    (MINI_MAP, 28),
    (CHANNEL, 29),
    (CHAT, 30),
    (CHAT_RANK, 31),
    (JOYPAD, 32),
    (EVENT, 33),
    (KEY_CONFIG, 34),
    (OPTION_MENU, 35),
    (QUIT, 36),
    (CHAR_INFO, 37),
    (CASHSHOP, 38),
    (GAUGE_BOSS, 39),
    (NOTIFICATION, 40),
    (TRADE, 41),
  ],
)

pub fn int_value(self : UIElementType) -> Int {
  all_types[self].unwrap()
}

fn hash(self : UIElementType) -> Int {
  self.int_value()
}

pub trait UIElement {
  send_cursor(Self, Bool, Point[Int]) -> CursorState
  button_pressed(Self, Int) -> ButtonState
  get_buttons(Self) -> Map[Int, Button]
  get_position(Self) -> Point[Int]
  is_active(Self) -> Bool
  get_type(Self) -> UIElementType
  is_in_range(Self, Point[Int]) -> Bool
}

struct UIElementBase {
  buttons : Map[Int, Button]
  sprites : Array[Sprite]
  position : Point[Int]
  dimension : Point[Int]
  mut active : Bool
}

pub fn UIElementBase::new(
  p : Point[Int],
  d : Point[Int],
  a : Bool
) -> UIElementBase {
  { position: p, dimension: d, active: a, sprites: [], buttons: Map::new() }
}

pub fn UIElementBase::new_with_defaults(
  p : Point[Int],
  d : Point[Int]
) -> UIElementBase {
  UIElementBase::new(p, d, true)
}

pub fn UIElementBase::default() -> UIElementBase {
  UIElementBase::new(Point::default(), Point::default(), true)
}

pub fn draw(self : UIElementBase, alpha : Double) -> Unit {
  draw_sprites(self, alpha)
  draw_buttons(self, alpha)
}

pub fn draw_sprites(self : UIElementBase, alpha : Double) -> Unit {
  self.sprites.iter(fn(sprite) { sprite.draw(self.position, alpha) })
}

pub fn draw_buttons(self : UIElementBase, _alpha : Double) -> Unit {
  self.buttons.iter(fn(_k, button) { button.draw(self.position) })
}

pub fn update(self : UIElementBase) -> Unit {
  self.sprites.iter(fn(sprite) { sprite.update() |> ignore })
  self.buttons.iter(fn(_k, button) { button.update() })
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
  let bounds = Rectangle::new(self.position, self.position + self.dimension)
  bounds.contains(cursorpos)
}

pub fn remove_cursor(self : UIElementBase) -> Unit {
  self.buttons.iter(
    fn(_k, button) {
      if button.get_state() == ButtonState::MOUSEOVER {
        button.set_state(ButtonState::NORMAL)
      }
    },
  )
}

pub fn base_send_cursor(
  elem : UIElement,
  down : Bool,
  pos : Point[Int]
) -> CursorState {
  let mut ret = if down { CursorState::CLICKING } else { CursorState::IDLE }
  elem.get_buttons().iter(
    fn(k, button) {
      if button.is_active() && button.bounds(elem.get_position()).contains(pos) {
        match button.get_state() {
          ButtonState::NORMAL => {
            Sound::new(SoundName::BUTTON_OVER).play()
            button.set_state(ButtonState::MOUSEOVER)
            ret = CursorState::CAN_CLICK
          }
          ButtonState::MOUSEOVER =>
            if down {
              Sound::new(SoundName::BUTTON_CLICK).play()
              button.set_state(elem.button_pressed(k))
              ret = CursorState::IDLE
            } else {
              ret = CursorState::CAN_CLICK
            }
          _ => ()
        }
      } else if button.get_state() == ButtonState::MOUSEOVER {
        button.set_state(ButtonState::NORMAL)
      }
    },
  )
  ret
}
