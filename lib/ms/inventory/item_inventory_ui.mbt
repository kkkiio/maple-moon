/// ItemInventory Dialog
/// 
/// support full display mode only for now
struct UIItemInventory {
  player_getter : () -> @player.Player?
  base : @ui.UIModel
  buttons : Map[ItemInventoryUIButton, @ui.UIButton]
  inventory : Inventory
  meso_label : @graphics.Text
  maple_points_label : @graphics.Text
  icons : Map[Int, (IconModel, @graphics.Texture)]
  mut tab : TypeId
  disabled : @graphics.Texture
  full_backgrnd : @graphics.Texture
  full_backgrnd2 : @graphics.Texture
  full_backgrnd3 : @graphics.Texture
  // TODO: support projectile 
}

pub fn UIItemInventory::new(
  inventory : Inventory,
  player_getter : () -> @player.Player?
) -> UIItemInventory {
  let tab = TypeId::EQUIP
  let ui_loader = @resource.ui_loader()
  let item = ui_loader.load_res(["UIWindow2.img", "Item"])

  // TODO: Change these to production
  let full_backgrnd = item["FullBackgrnd"] |> @graphics.Texture::from_resource
  let full_backgrnd2 = item["FullBackgrnd2"] |> @graphics.Texture::from_resource
  let full_backgrnd3 = item["FullBackgrnd3"] |> @graphics.Texture::from_resource
  let bg_full_dimensions = full_backgrnd.get_dimensions()

  // TODO: new tab

  let disabled = item["disabled"] |> @graphics.Texture::from_resource
  let srctab = item["Tab"]
  let taben = srctab["enabled"]
  let tabdis = srctab["disabled"]
  let close = ui_loader.load_res(["Basic.img", "BtClose3"])
  let buttons : Map[ItemInventoryUIButton, @ui.UIButton] = {}
  buttons[ItemInventoryUIButton::BT_CLOSE] = @ui.MapleButton::from_resource(
    close,
  )
  buttons[ItemInventoryUIButton::BT_TAB_EQUIP] = @ui.TwoSpriteButton::new(
    tabdis["0"],
    taben["0"],
  )
  buttons[ItemInventoryUIButton::BT_TAB_USE] = @ui.TwoSpriteButton::new(
    tabdis["1"],
    taben["1"],
  )
  buttons[ItemInventoryUIButton::BT_TAB_ETC] = @ui.TwoSpriteButton::new(
    tabdis["2"],
    taben["2"],
  )
  buttons[ItemInventoryUIButton::BT_TAB_SETUP] = @ui.TwoSpriteButton::new(
    tabdis["3"],
    taben["3"],
  )
  buttons[ItemInventoryUIButton::BT_TAB_CASH] = @ui.TwoSpriteButton::new(
    tabdis["4"],
    taben["4"],
  )
  buttons[ItemInventoryUIButton::BT_GATHER] = @ui.MapleButton::from_resource(
    item["BtGather3"],
  )
  buttons[ItemInventoryUIButton::BT_SORT] = @ui.MapleButton::from_resource(
    item["BtSort3"],
  )
  buttons[ItemInventoryUIButton::BT_COIN_SM] = @ui.MapleButton::from_resource(
    item["BtCoin4"],
  )
  buttons[ItemInventoryUIButton::BT_POINT_SM] = @ui.MapleButton::from_resource(
    item["BtPoint1"],
  )
  buttons[ItemInventoryUIButton::BT_GATHER_SM] = @ui.MapleButton::from_resource(
    item["BtGather4"],
  )
  buttons[ItemInventoryUIButton::BT_SORT_SM] = @ui.MapleButton::from_resource(
    item["BtSort4"],
  )
  buttons[ItemInventoryUIButton::BT_POT_SM] = @ui.MapleButton::from_resource(
    item["BtPot4"],
  )
  buttons[ItemInventoryUIButton::BT_UPGRADE_SM] = @ui.MapleButton::from_resource(
    item["BtUpgrade4"],
  )
  buttons[ItemInventoryUIButton::BT_APPRAISE_SM] = @ui.MapleButton::from_resource(
    item["BtAppraise4"],
  )
  buttons[ItemInventoryUIButton::BT_EXTRACT_SM] = @ui.MapleButton::from_resource(
    item["BtExtract4"],
  )
  buttons[ItemInventoryUIButton::BT_DISASSEMBLE_SM] = @ui.MapleButton::from_resource(
    item["BtDisassemble4"],
  )
  buttons[ItemInventoryUIButton::BT_TOAD_SM] = @ui.MapleButton::from_resource(
    item["BtToad4"],
  )
  buttons[button_by_tab(tab)]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::PRESSED)
  let meso_label = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  // TODO: support maple points
  let maple_points_label = @graphics.Text::new(
    text="0",
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  let base = @ui.UIModel::new(@struct.Point::new(300, 160), bg_full_dimensions)
  let ui : UIItemInventory = {
    player_getter,
    base,
    buttons,
    inventory,
    meso_label,
    maple_points_label,
    icons: {},
    tab,
    disabled,
    full_backgrnd,
    full_backgrnd2,
    full_backgrnd3,
  }
  ui.load_icons?().unwrap()
  ui
}

pub fn draw(self : UIItemInventory, alpha : Double) -> Unit {
  let position = self.base.position
  let mesolabel_pos = position + @struct.Point::new(127, 262)
  let maplepointslabel_pos = position + @struct.Point::new(159, 279)

  // TODO: support scroll
  self.full_backgrnd.draw(self.base.position |> @graphics.DrawArgument::new)
  self.full_backgrnd2.draw(self.base.position |> @graphics.DrawArgument::new)
  self.full_backgrnd3.draw(self.base.position |> @graphics.DrawArgument::new)
  self.meso_label.draw(mesolabel_pos + @struct.Point::new(3, 70))
  self.maple_points_label.draw(
    maplepointslabel_pos + @struct.Point::new(181, 53),
  )
  let numslots = self.inventory.get_slotmax(self.tab)
  let firstslot = 1
  let lastslot = max_full_slots
  for i in 0..=max_full_slots {
    let slotpos = get_full_slotpos(i)
    match self.icons.get(i) {
      Some(icon) =>
        if i >= firstslot && i <= lastslot {
          icon.0.draw(position + slotpos, icon.1)
        }
      None =>
        if i > numslots && i <= lastslot {
          self.disabled.draw(position + slotpos |> @graphics.DrawArgument::new)
        }
    }
  }
  // TODO: bulletslot
  // TODO: new_tab
  for _, button in self.buttons {
    button.draw(position)
  }
}

pub fn update(self : UIItemInventory) -> Unit {
  let meso_str = @string_format.format_decimal_separator(
    self.inventory.get_meso(),
  )
  self.meso_label.change_text(meso_str)
}

pub fn get_full_slotpos(slot : Int) -> @struct.Point[Int] {
  let absslot = slot - 1
  let div = absslot / max_slots
  let new_slot = absslot - div * max_slots
  let adj_x = div * columns * icon_width
  @struct.Point::new(
    10 + adj_x + new_slot % columns * icon_width,
    51 + new_slot / columns * icon_height,
  )
}

let rows = 8

let columns = 4

let max_slots : Int = rows * columns

let max_full_slots : Int = columns * max_slots

let icon_width = 36

let icon_height = 35

pub fn is_visible(self : UIItemInventory, slot : Int) -> Bool {
  self.is_not_visible(slot).not()
}

pub fn is_not_visible(self : UIItemInventory, slot : Int) -> Bool {
  let numslots = self.inventory.get_slotmax(self.tab)
  slot < 1 || slot > numslots
}

pub fn load_icons(self : UIItemInventory) -> Unit! {
  self.icons.clear()
  let numslots = self.inventory.get_slotmax(self.tab)
  for i in 0..=max_full_slots {
    if i <= numslots {
      self.update_slot!(i)
    }
  }
}

pub fn update_slot(self : UIItemInventory, slot : Int) -> Unit! {
  let item_id = self.inventory.get_item_id(self.tab, slot)
  if item_id == 0 {
    self.icons.remove(slot)
    return
  }
  let count = if self.tab == TypeId::EQUIP {
    -1
  } else {
    self.inventory.get_item_count(self.tab, slot)
  }
  let texture = @item.ItemData::get!(item_id).get_icon(false)
  self.icons[slot] = (IconModel::new(count), texture) // TODO: support drop
}

enum ItemInventoryUIButton {
  BT_CLOSE
  BT_TAB_EQUIP
  BT_TAB_USE
  BT_TAB_ETC
  BT_TAB_SETUP
  BT_TAB_CASH
  BT_GATHER
  BT_SORT
  BT_COIN_SM
  BT_POINT_SM
  BT_GATHER_SM
  BT_SORT_SM
  BT_POT_SM
  BT_UPGRADE_SM
  BT_APPRAISE_SM
  BT_EXTRACT_SM
  BT_DISASSEMBLE_SM
  BT_TOAD_SM
} derive(Eq, Hash)

pub fn button_by_tab(tb : TypeId) -> ItemInventoryUIButton {
  match tb {
    TypeId::EQUIP => ItemInventoryUIButton::BT_TAB_EQUIP
    TypeId::USE => ItemInventoryUIButton::BT_TAB_USE
    TypeId::SETUP => ItemInventoryUIButton::BT_TAB_SETUP
    TypeId::ETC => ItemInventoryUIButton::BT_TAB_ETC
    _ => ItemInventoryUIButton::BT_TAB_CASH
  }
}

pub fn UIItemInventory::is_focused() -> Bool {
  false
}

pub fn get_ui_model(self : UIItemInventory) -> @ui.UIModel {
  self.base
}

pub fn send_cursor(
  self : UIItemInventory,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  // TODO: implement
  @ui.send_cursor_to_buttons(
    self.buttons.iter2(),
    self.base.position,
    fn(buttonid) { self.button_pressed(buttonid) },
    pressed,
    cursorpos,
  )
}

pub fn button_pressed(
  self : UIItemInventory,
  buttonid : ItemInventoryUIButton
) -> @ui.ButtonState {
  let old_tab = self.tab
  match buttonid {
    ItemInventoryUIButton::BT_CLOSE => {
      self.toggle_active()
      return @ui.ButtonState::NORMAL
    }
    ItemInventoryUIButton::BT_TAB_EQUIP => self.tab = TypeId::EQUIP
    ItemInventoryUIButton::BT_TAB_USE => self.tab = TypeId::USE
    ItemInventoryUIButton::BT_TAB_SETUP => self.tab = TypeId::SETUP
    ItemInventoryUIButton::BT_TAB_ETC => self.tab = TypeId::ETC
    ItemInventoryUIButton::BT_TAB_CASH => self.tab = TypeId::CASH
    // ItemInventoryUIButton::BT_GATHER | ItemInventoryUIButton::BT_GATHER_SM =>
    //   self.fn_gather_items(self.tab)
    // ItemInventoryUIButton::BT_SORT | ItemInventoryUIButton::BT_SORT_SM =>
    //   self.fn_sort_items(self.tab)
    _ => return @ui.ButtonState::NORMAL
  }
  if self.tab != old_tab {
    self.buttons[button_by_tab(old_tab)]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::NORMAL)
    self.buttons[button_by_tab(self.tab)]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::PRESSED)
    self.load_icons?().unwrap() // TODO: handle error
  }
  @ui.ButtonState::IDENTITY
}

pub fn send_key(
  self : UIItemInventory,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

pub fn get_type(self : UIItemInventory) -> @ui.UIElementType {
  @ui.UIElementType::ITEM_INVENTORY
}

pub fn toggle_active(self : UIItemInventory) -> Unit {
  self.base.toggle_active()
  if self.base.is_active().not() {
    // TODO: implement
    // self.clear_new()
    // self.clear_tooltip()
  }
}

pub fn remove_cursor(self : UIItemInventory) -> Unit {
  // TODO: implement
  // self.slider_.remove_cursor()
}

pub fn doubleclick(
  self : UIItemInventory,
  cursorpos : @struct.Point[Int]
) -> Unit {
  let slot = self.slot_by_position(cursorpos - self.base.position)
  if self.icons.contains(slot) && self.is_visible(slot) {
    let item_id = self.inventory.get_item_id(self.tab, slot)
    if item_id != 0 {
      match self.tab {
        TypeId::EQUIP =>
          if self.can_wear_equip(slot) {
            new_equip_item_packet(slot, self.inventory.find_equipslot(item_id)).dispatch()
          }
        TypeId::USE => new_use_item_packet(slot, item_id).dispatch()
        _ => ()
      }
    }
  }
}

fn slot_by_position(
  self : UIItemInventory,
  cursorpos : @struct.Point[Int]
) -> Int {
  let xoff = cursorpos.x - 11
  let yoff = cursorpos.y - 51
  if xoff < 1 || xoff > 143 || yoff < 1 {
    return 0
  }
  let slot = 1 + xoff / icon_width + columns * (yoff / icon_height)
  if self.is_visible(slot) {
    slot
  } else {
    0
  }
}

pub fn can_wear_equip(self : UIItemInventory, slot : Int) -> Bool {
  guard let Some(player) = (self.player_getter)() else { None => false }
  let stats = player.get_stats()
  let look = player.get_look()
  let alerted = look.get_alerted()
  if alerted {
    // TODO: alert
    return false
  }
  let item_id = self.inventory.get_item_id(TypeId::EQUIP, slot)
  let equipdata = @equip.EquipData::get?(item_id).unwrap() // TODO: handle error
  let itemdata = equipdata.get_itemdata()
  let reqGender = itemdata.gender
  let female = stats.get_female()
  match reqGender {
    0 => // Male
      if female {
        return false
      }
    1 => // Female
      if female.not() {
        return false
      }
    2 => () // Unisex
    _ => ()
  }
  let reqLevel = equipdata.get_reqstat(@MapleStat.Id::LEVEL)
  let reqDEX = equipdata.get_reqstat(@MapleStat.Id::DEX)
  let reqSTR = equipdata.get_reqstat(@MapleStat.Id::STR)
  let reqLUK = equipdata.get_reqstat(@MapleStat.Id::LUK)
  let reqINT = equipdata.get_reqstat(@MapleStat.Id::INT)
  let reqFAME = equipdata.get_reqstat(@MapleStat.Id::FAME)
  let mut i = 0
  if reqLevel > stats.level {
    i += 1
  } else if reqDEX > stats.get_total(@equip_stat.Id::DEX) {
    i += 1
  } else if reqSTR > stats.get_total(@equip_stat.Id::STR) {
    i += 1
  } else if reqLUK > stats.get_total(@equip_stat.Id::LUK) {
    i += 1
  } else if reqINT > stats.get_total(@equip_stat.Id::INT) {
    i += 1
  } else if reqFAME > 0 { // TODO: support honor
    i += 1
  }
  if i > 0 {
    // TODO: show hint message
    return false
  }
  return true
}

pub fn new_use_item_packet(slot : Int, itemid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::USE_ITEM)
  ..write_time()
  ..write_short(slot)
  ..write_int(itemid)
}

// Update the button_pressed function to use the new enum
fn change_tab(
  self : UIItemInventory,
  tab : ItemInventoryUIButton
) -> @ui.ButtonState {
  // Implementation
  @ui.ButtonState::PRESSED
}

// Packet which requests that an item is moved
// Opcode: MOVE_ITEM(71)
pub fn new_move_item_packet(
  type_id : TypeId,
  slot : Int,
  action : Int,
  qty : Int
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::MOVE_ITEM)
  ..write_time()
  ..write_byte(type_id.int_value().to_byte())
  ..write_short(slot)
  ..write_short(action)
  ..write_short(qty)
}

// Packet which requests that an item is equipped
// Opcode: MOVE_ITEM(71)
pub fn new_equip_item_packet(src : Int, dest : @slot.Id) -> @net.OutPacket {
  new_move_item_packet(TypeId::EQUIP, src, -dest.int_value(), 1)
}
