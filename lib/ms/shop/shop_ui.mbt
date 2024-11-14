/// UI for the shop
/// 
/// right_click will sell items
struct UIShop {
  model : @ui.UIModel
  sprites : Array[@graphics.Sprite]
  buttons : Map[Buttons, @ui.UIButton]
  npc : @graphics.Texture
  charlook : @character.CharLook
  inventory : @inventory.Inventory
  meso : @graphics.Texture
  meso_label : @graphics.Text
  buy_state : BuyState
  sell_state : SellState
  buy_selection : @graphics.Texture
  sell_selection : @graphics.Texture
  buy_x : Int
  buy_width : Int
  sell_x : Int
  sell_width : Int
}

pub fn UIShop::new(
  countset : @graphics.Charset,
  charlook : @character.CharLook,
  inventory : @inventory.Inventory,
  npcid : Int,
  items : Array[ShopItem]
) -> UIShop {
  let src = @resource.ui_loader().load_res(["UIWindow2.img", "Shop2"])
  let npc = @graphics.Texture::from_resource(
    @npc.npc_loader().load_res(["\{npcid}.img", "stand", "0"]),
  )
  let background = src["backgrnd"]
  let bg = @graphics.Texture::from_resource(background)
  let bg_dimensions = bg.get_dimensions()
  let sprites = [
    @graphics.Sprite::from_resource(background),
    @graphics.Sprite::from_resource(src["backgrnd2"]),
    @graphics.Sprite::from_resource(src["backgrnd3"]),
    @graphics.Sprite::from_resource(src["backgrnd4"]),
  ]
  let meso_label = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::MINESHAFT,
  )
  let buy_selection = @graphics.Texture::from_resource(src["select"])
  let sell_selection = @graphics.Texture::from_resource(src["select2"])
  let meso = @graphics.Texture::from_resource(src["meso"])
  let buy_state = BuyState::new(meso, items)
  let sell_state = SellState::new(items, countset)
  let model = @ui.UIModel::new(@struct.Point::new(146, 48), bg_dimensions)
  let buttons : Map[Buttons, @ui.UIButton] = Map::new()
  buttons[Buttons::BUY_ITEM] = @ui.MapleButton::from_resource(src["BtBuy"])
  buttons[Buttons::SELL_ITEM_ALL] = @ui.MapleButton::from_resource(
    src["BtSell"],
  ) // FIXME: use new texture for sell all
  buttons[Buttons::EXIT] = @ui.MapleButton::from_resource(src["BtExit"])
  let sellen = src["TabSell"]["enabled"]
  let selldis = src["TabSell"]["disabled"]
  for
    i, button in [
      Buttons::EQUIP,
      Buttons::USE,
      Buttons::ETC,
      Buttons::SETUP,
      Buttons::CASH,
    ] {
    let tabnum = i.to_string()
    buttons[button] = @ui.TwoSpriteButton::new(
      selldis[tabnum] |> @graphics.Texture::from_resource,
      sellen[tabnum] |> @graphics.Texture::from_resource,
    )
  }
  let buy_x = 8
  let buy_width = 257
  for i, button in buy_buttons {
    let pos = @struct.Point::new(buy_x, 116 + 42 * i)
    let dim = @struct.Point::new(buy_width, 42)
    buttons[button] = @ui.AreaButton::new(pos, dim)
  }
  let sell_x = 284
  let sell_width = 200
  for i, button in sell_buttons {
    let pos = @struct.Point::new(sell_x, 116 + 42 * i)
    let dim = @struct.Point::new(sell_width, 42)
    buttons[button] = @ui.AreaButton::new(pos, dim)
  }
  {
    meso,
    buy_x,
    buy_width,
    sell_x,
    sell_width,
    sprites,
    model,
    buttons,
    npc,
    charlook,
    inventory,
    meso_label,
    buy_state,
    sell_state,
    buy_selection,
    sell_selection,
  }
}

pub fn draw(self : UIShop, alpha : Double) -> Unit {
  let position = self.model.position
  self.sprites.each(fn(sprite) { sprite.draw(position, alpha) })
  for _, button in self.buttons {
    button.draw(position)
  }
  self.npc.draw(
    @graphics.DrawArgument::new(
      position + @struct.Point::new(58, 85),
      flip=true,
    ),
  )
  self.charlook.draw_with_stance(
    position + @struct.Point::new(338, 85),
    false,
    @char_look.StanceId::STAND1,
    @character.ExpressionId::DEFAULT,
  )
  self.meso_label.draw(position + @struct.Point::new(493, 51))
  self.buy_state.draw(position, self.buy_selection)
  self.sell_state.draw(position, self.sell_selection)
}

struct BuyState {
  items : Array[BuyItem]
  offset : Int
  last_slot : Int
  mut selection : Int
}

fn BuyState::new(
  currency : @graphics.Texture,
  shop_items : Array[ShopItem]
) -> BuyState {
  let items = []
  for shop_item in shop_items {
    let (icon, name) = match @item.ItemData::get?(shop_item.id) {
      Ok(item) => (item.get_icon(false), item.name)
      Err(err) => {
        @log.error(
          { "err": Show::to_string(err), "item_id": shop_item.id },
          "Failed to get item data",
        )
        (@graphics.Texture::default(), "")
      }
    }
    let name_label = @graphics.Text::new(
      text=name,
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::MINESHAFT,
    )
    let mesostr = @string_format.format_decimal_separator(shop_item.price)
    let price_label = @graphics.Text::new(
      text=mesostr + "meso",
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::MINESHAFT,
    )
    let buyitem : BuyItem = {
      icon,
      currency,
      id: shop_item.id,
      name_label,
      price_label,
      price: shop_item.price,
      pitch: shop_item.pitch,
      time: shop_item.time,
      charge_price: shop_item.charge_price,
      buyable: shop_item.buyable,
    }
    items.push(buyitem)
  }
  { items, offset: 0, last_slot: items.length(), selection: -1 }
}

pub fn draw(
  self : BuyState,
  parentpos : @struct.Point[Int],
  selected : @graphics.Texture
) -> Unit {
  for i in 0..<9 {
    let slot = i + self.offset
    if slot >= self.last_slot {
      break
    }
    let itempos = @struct.Point::new(12, 116 + 42 * i)
    if slot == self.selection {
      selected.draw(
        @graphics.DrawArgument::new(
          parentpos + itempos + @struct.Point::new(35, 8),
        ),
      )
    }
    self.items[slot].draw(parentpos + itempos)
  }
}

pub fn select(self : BuyState, selected : Int) -> Unit {
  let slot = selected + self.offset
  if slot == self.selection {
    self.buy()
  } else {
    self.selection = slot
  }
}

pub fn buy(self : BuyState) -> Unit {
  if self.selection < 0 || self.selection >= self.last_slot {
    return
  }
  let item = self.items[self.selection]
  let buyable = item.buyable
  let slot = self.selection
  let itemid = item.id
  if buyable > 0 {
    // TODO: support buying multiple items
    new_npc_shop_item_action_packet(slot, itemid, 1, true).dispatch()
  }
}

struct BuyItem {
  icon : @graphics.Texture
  currency : @graphics.Texture
  id : Int
  price : Int
  pitch : Int
  time : Int
  charge_price : Int
  buyable : Int
  name_label : @graphics.Text
  price_label : @graphics.Text
}

pub fn draw(self : BuyItem, pos : @struct.Point[Int]) -> Unit {
  self.icon.draw(@graphics.DrawArgument::new(pos + @struct.Point::new(0, 42)))
  self.name_label.draw(pos + @struct.Point::new(40, 6))
  self.currency.draw(
    @graphics.DrawArgument::new(pos + @struct.Point::new(38, 29)),
  )
  self.price_label.draw(pos + @struct.Point::new(55, 24))
}

struct SellState {
  countset : @graphics.Charset
  items : Array[SellItem]
  mut offset : Int
  mut tab : @inventory.TypeId?
  mut last_slot : Int
  mut selection : Int
}

fn SellState::new(
  items : Array[ShopItem],
  countset : @graphics.Charset
) -> SellState {
  { countset, items: [], offset: 0, tab: None, last_slot: 0, selection: -1 }
}

pub fn draw(
  self : SellState,
  parentpos : @struct.Point[Int],
  selected : @graphics.Texture
) -> Unit {
  for i in 0..=8 {
    let slot = i + self.offset
    if slot >= self.last_slot {
      break
    }
    let itempos = @struct.Point::new(243, 116 + 42 * i)
    if slot == self.selection {
      selected.draw(
        @graphics.DrawArgument::new(
          parentpos + itempos + @struct.Point::new(78, 8),
        ),
      )
    }
    self.items[slot].draw(parentpos + itempos)
  }
}

pub fn select(self : SellState, selected : Int) -> Unit {
  let slot = selected + self.offset
  if slot == self.selection {
    self.sell()
  } else {
    self.selection = slot
  }
}

pub fn sell(self : SellState, ~all : Bool = false) -> Unit {
  if self.selection < 0 || self.selection >= self.last_slot {
    return
  }
  let item = self.items[self.selection]
  let itemid = item.id
  let sellable = item.sellable
  let slot = item.slot
  if sellable > 0 {
    new_npc_shop_item_action_packet(
      slot,
      itemid,
      if all {
        sellable
      } else {
        1
      },
      false,
    ).dispatch()
  }
}

pub fn change_tab(
  self : SellState,
  inventory : @inventory.Inventory,
  newtab : @inventory.TypeId,
  meso : @graphics.Texture
) -> Unit {
  self.tab = Some(newtab)
  self.offset = 0
  self.items.clear()
  let slots = inventory.get_slotmax(newtab)
  for i in 1..=slots {
    match inventory.get_item_id(newtab, i) {
      0 => ()
      item_id => {
        let count = inventory.get_item_count(newtab, i)
        self.items.push(
          SellItem::new(
            self.countset,
            item_id,
            count,
            i,
            newtab != @inventory.TypeId::EQUIP,
            meso,
          ),
        )
      }
    }
  }
  self.last_slot = self.items.length()
}

pub fn update(self : UIShop) -> Unit {
  for _, sprite in self.sprites {
    sprite.update() |> ignore
  }
  for _, button in self.buttons {
    button.update() |> ignore
  }
  let num_mesos = self.inventory.get_meso()
  let mesostr = @string_format.format_decimal_separator(num_mesos)
  self.meso_label.change_text(mesostr)
}

struct SellItem {
  countset : @graphics.Charset
  icon : @graphics.Texture
  id : Int
  slot : Int
  sellable : Int
  show_count : Bool
  name_label : @graphics.Text
  price_label : @graphics.Text
}

pub fn SellItem::new(
  countset : @graphics.Charset,
  item_id : Int,
  count : Int,
  s : Int,
  sc : Bool,
  cur : @graphics.Texture
) -> SellItem {
  let idata = @item.ItemData::get?(item_id).unwrap() // TODO: handle error
  let icon = idata.get_icon(false)
  let id = item_id
  let sellable = count
  let slot = s
  let show_count = sc
  let mut name = idata.name
  if name.length() >= 28 {
    name = name.substring(end=28) + ".."
  }
  let name_label = @graphics.Text::new(
    text=name,
    @graphics.FontId::A11M,
    @graphics.TextAlignment::LEFT,
    @struct.ColorName::MINESHAFT,
  )
  let price = idata.price
  let mesostr = @string_format.format_decimal_separator(price)
  let price_label = @graphics.Text::new(
    text=mesostr + "meso",
    @graphics.FontId::A11M,
    @graphics.TextAlignment::LEFT,
    @struct.ColorName::MINESHAFT,
  )
  { countset, icon, id, slot, sellable, show_count, name_label, price_label }
}

pub fn draw(self : SellItem, pos : @struct.Point[Int]) -> Unit {
  self.icon.draw(@graphics.DrawArgument::new(pos + @struct.Point::new(43, 42)))
  if self.show_count {
    self.countset.draw_text(
      self.sellable.to_string(),
      @graphics.DrawArgument::new(pos + @struct.Point::new(41, 28)),
    )
    |> ignore
  }
  self.name_label.draw(pos + @struct.Point::new(84, 6))
  self.price_label.draw(pos + @struct.Point::new(84, 24))
}

pub fn get_ui_model(self : UIShop) -> @ui.UIModel {
  self.model
}

impl @ui.UIElement for UIShop with send_cursor(
  self,
  clicked : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  let position = self.model.position
  let cursoroffset = cursorpos - position
  let xoff = cursoroffset.x
  let yoff = cursoroffset.y
  let slot = slot_by_position(yoff)
  if slot >= 0 && slot <= 8 {
    if xoff >= self.buy_x && xoff <= self.buy_width {
      self.show_item(slot, true)
    } else if xoff >= self.sell_x && xoff <= self.sell_x + self.sell_width {
      self.show_item(slot, false)
    }
  }
  let mut ret = if clicked {
    @ui.CursorState::CLICKING
  } else {
    @ui.CursorState::IDLE
  }
  for i, button in self.buttons {
    if button.get_button_base().is_active() &&
      button.bounds(position).contains(cursorpos) {
      if button.get_button_base().get_state() == @ui.ButtonState::NORMAL {
        if i == Buttons::BUY_ITEM ||
          i == Buttons::SELL_ITEM_ALL ||
          i == Buttons::EXIT {
          button.get_button_base().set_state(@ui.ButtonState::MOUSEOVER)
          ret = @ui.CursorState::CAN_CLICK
        } else {
          button.get_button_base().set_state(@ui.ButtonState::MOUSEOVER)
          ret = @ui.CursorState::IDLE
        }
      } else if button.get_button_base().get_state() ==
        @ui.ButtonState::MOUSEOVER {
        if clicked {
          if i >= Buttons::BUY_ITEM && i <= Buttons::CASH {
            if i >= Buttons::OVERALL && i <= Buttons::CASH {

            } else if i != Buttons::CHECKBOX {

            }
            button.get_button_base().set_state(self.button_pressed(i))
            ret = @ui.CursorState::IDLE
          } else {
            button.get_button_base().set_state(self.button_pressed(i))
            ret = @ui.CursorState::IDLE
          }
        } else if i >= Buttons::BUY_ITEM && i <= Buttons::EXIT {
          ret = @ui.CursorState::CAN_CLICK
        } else {
          ret = @ui.CursorState::IDLE
        }
      } else if button.get_button_base().get_state() == @ui.ButtonState::PRESSED {
        if clicked {
          if i >= Buttons::OVERALL && i <= Buttons::CASH {
            ret = @ui.CursorState::IDLE
          }
        }
      }
    } else if button.get_button_base().get_state() == @ui.ButtonState::MOUSEOVER {
      button.get_button_base().set_state(@ui.ButtonState::NORMAL)
    }
  }
  return ret
}

let buy_buttons : Array[Buttons] = [
  Buttons::BUY0,
  Buttons::BUY1,
  Buttons::BUY2,
  Buttons::BUY3,
  Buttons::BUY4,
  Buttons::BUY5,
  Buttons::BUY6,
  Buttons::BUY7,
  Buttons::BUY8,
]

let sell_buttons : Array[Buttons] = [
  Buttons::SELL0,
  Buttons::SELL1,
  Buttons::SELL2,
  Buttons::SELL3,
  Buttons::SELL4,
  Buttons::SELL5,
  Buttons::SELL6,
  Buttons::SELL7,
  Buttons::SELL8,
]

fn button_pressed(self : UIShop, button : Buttons) -> @ui.ButtonState {
  match buy_buttons.search(button) {
    Some(selected) => {
      self.buy_state.select(selected)
      self.sell_state.selection = -1
      return @ui.ButtonState::NORMAL
    }
    None => ()
  }
  match sell_buttons.search(button) {
    Some(selected) => {
      self.sell_state.select(selected)
      self.buy_state.selection = -1
      return @ui.ButtonState::NORMAL
    }
    None => ()
  }
  match button {
    Buttons::BUY_ITEM => {
      self.buy_state.buy()
      return @ui.ButtonState::NORMAL
    }
    Buttons::SELL_ITEM_ALL => {
      self.sell_state.sell(all=true)
      return @ui.ButtonState::NORMAL
    }
    Buttons::EXIT => {
      self.exit_shop()
      return @ui.ButtonState::PRESSED
    }
    Buttons::EQUIP => {
      self.changeselltab(@inventory.TypeId::EQUIP)
      return @ui.ButtonState::IDENTITY
    }
    Buttons::USE => {
      self.changeselltab(@inventory.TypeId::USE)
      return @ui.ButtonState::IDENTITY
    }
    Buttons::ETC => {
      self.changeselltab(@inventory.TypeId::ETC)
      return @ui.ButtonState::IDENTITY
    }
    Buttons::SETUP => {
      self.changeselltab(@inventory.TypeId::SETUP)
      return @ui.ButtonState::IDENTITY
    }
    Buttons::CASH => {
      self.changeselltab(@inventory.TypeId::CASH)
      return @ui.ButtonState::IDENTITY
    }
    _ => @ui.ButtonState::PRESSED
  }
}

fn changeselltab(self : UIShop, inventory_type : @inventory.TypeId) -> Unit {
  let oldtab = self.sell_state.tab.bind(tabbyinventory)
  match oldtab {
    Some(oldtab) =>
      self.buttons[oldtab]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::NORMAL)
    None => ()
  }
  let newtab = tabbyinventory(inventory_type)
  match newtab {
    Some(newtab) =>
      self.buttons[newtab]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::PRESSED)
    None => ()
  }
  self.sell_state.change_tab(self.inventory, inventory_type, self.meso)
  for i, button in sell_buttons {
    if i < self.sell_state.last_slot {
      self.buttons[button]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::NORMAL)
    } else {
      self.buttons[button]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::DISABLED)
    }
  }
}

fn exit_shop(self : UIShop) -> Unit {
  self.model.deactivate()
  new_npc_shop_leave_action_packet().dispatch()
}

impl @ui.UIElement for UIShop with send_key(
  self,
  _key : Int,
  pressed : Bool,
  esc : Bool
) -> Unit {
  if pressed && esc {
    self.exit_shop()
  }
}

impl @ui.UIElement for UIShop with remove_cursor(self) -> Unit {  }

enum Buttons {
  BUY_ITEM
  SELL_ITEM_ALL
  EXIT
  CHECKBOX
  OVERALL
  EQUIP
  USE
  ETC
  SETUP
  CASH
  BUY0
  BUY1
  BUY2
  BUY3
  BUY4
  BUY5
  BUY6
  BUY7
  BUY8
  SELL0
  SELL1
  SELL2
  SELL3
  SELL4
  SELL5
  SELL6
  SELL7
  SELL8
} derive(Eq, Hash)

pub fn int_value(self : Buttons) -> Int {
  match self {
    Buttons::BUY_ITEM => 0
    Buttons::SELL_ITEM_ALL => 1
    Buttons::EXIT => 2
    Buttons::CHECKBOX => 3
    Buttons::OVERALL => 4
    Buttons::EQUIP => 5
    Buttons::USE => 6
    Buttons::ETC => 7
    Buttons::SETUP => 8
    Buttons::CASH => 9
    Buttons::BUY0 => 10
    Buttons::BUY1 => 11
    Buttons::BUY2 => 12
    Buttons::BUY3 => 13
    Buttons::BUY4 => 14
    Buttons::BUY5 => 15
    Buttons::BUY6 => 16
    Buttons::BUY7 => 17
    Buttons::BUY8 => 18
    Buttons::SELL0 => 19
    Buttons::SELL1 => 20
    Buttons::SELL2 => 21
    Buttons::SELL3 => 22
    Buttons::SELL4 => 23
    Buttons::SELL5 => 24
    Buttons::SELL6 => 25
    Buttons::SELL7 => 26
    Buttons::SELL8 => 27
  }
}

impl Compare for Buttons with compare(self, other : Buttons) -> Int {
  self.int_value().compare(other.int_value())
}

fn slot_by_position(y : Int) -> Int {
  let yoff = y - 123
  if yoff > 0 && yoff < 38 {
    return 0
  }
  if yoff > 42 && yoff < 80 {
    return 1
  }
  if yoff > 84 && yoff < 122 {
    return 2
  }
  if yoff > 126 && yoff < 164 {
    return 3
  }
  if yoff > 168 && yoff < 206 {
    return 4
  }
  if yoff > 210 && yoff < 248 {
    return 5
  }
  if yoff > 252 && yoff < 290 {
    return 6
  }
  if yoff > 294 && yoff < 332 {
    return 7
  }
  if yoff > 336 && yoff < 374 {
    return 8
  }
  -1
}

pub fn show_item(self : UIShop, slot : Int, buy : Bool) -> Unit {
  // TODO: Implement
  // if buy {
  //   self.buy_state.show_item(slot)
  // } else {
  //   self.sell_state.show_item(slot)
  // }
}

let mode_BUY : Byte = b'\x00'

let mode_SELL : Byte = b'\x01'

let mode_RECHARGE : Byte = b'\x02'

let mode_LEAVE : Byte = b'\x03'

// Requests that an item should be bought from or sold to a NPC shop
fn new_npc_shop_item_action_packet(
  slot : Int,
  itemid : Int,
  qty : Int,
  buy : Bool
) -> @net.OutPacket {
  new_npc_shop_action_packet(if buy { mode_BUY } else { mode_SELL })
  ..write_short(slot)
  ..write_int(itemid)
  ..write_short(qty)
}

// Requests that an item should be recharged at a NPC shop
fn new_npc_shop_recharge_action_packet(slot : Int) -> @net.OutPacket {
  new_npc_shop_action_packet(mode_RECHARGE)..write_short(slot)
}

// Requests exiting from a NPC shop
fn new_npc_shop_leave_action_packet() -> @net.OutPacket {
  new_npc_shop_action_packet(mode_LEAVE)
}

fn new_npc_shop_action_packet(mode : Byte) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NPC_SHOP_ACTION)..write_byte(mode)
}

fn tabbyinventory(inventory_type : @inventory.TypeId) -> Buttons? {
  match inventory_type {
    @inventory.TypeId::EQUIP => Some(Buttons::EQUIP)
    @inventory.TypeId::USE => Some(Buttons::USE)
    @inventory.TypeId::ETC => Some(Buttons::ETC)
    @inventory.TypeId::SETUP => Some(Buttons::SETUP)
    @inventory.TypeId::CASH => Some(Buttons::CASH)
    _ => None
  }
}
