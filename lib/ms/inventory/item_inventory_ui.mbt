struct UIItemInventory {
  base : @ui.UIElementBase
  buttons : @ui.UIButtons
  inventory : Inventory
  mut meso_label : @graphics.Text
  maple_points_label : @graphics.Text
  icons : Map[Int, Icon]
  tab : TypeId
  disabled : @graphics.Texture
  full_backgrnd : @graphics.Texture
  full_backgrnd2 : @graphics.Texture
  full_backgrnd3 : @graphics.Texture
  // TODO: support projectile 
}

pub fn UIItemInventory::new(inventory : Inventory) -> UIItemInventory {
  let tab = TypeId::EQUIP
  let ui_loader = @resource.ui_loader()
  let item = ui_loader.load_res(["UIWindow2.img", "Item"])

  // TODO: Change these to production
  let full_backgrnd = item["FullBackgrnd"] |> @graphics.Texture::from_resource
  let full_backgrnd2 = item["FullBackgrnd2"] |> @graphics.Texture::from_resource
  let full_backgrnd3 = item["FullBackgrnd3"] |> @graphics.Texture::from_resource

  // TODO: new tab

  let disabled = item["disabled"] |> @graphics.Texture::from_resource
  let srctab = item["Tab"]
  let taben = srctab["enabled"]
  let tabdis = srctab["disabled"]
  let close = ui_loader.load_res(["Basic.img", "BtClose3"])
  let buttons : Map[Int, @ui.Button] = {}
  buttons[bid_close] = @ui.MapleButton::from_resource(close)
  buttons[bid_tab_equip] = @ui.TwoSpriteButton::new(tabdis["0"], taben["0"])
  buttons[bid_tab_use] = @ui.TwoSpriteButton::new(tabdis["1"], taben["1"])
  buttons[bid_tab_etc] = @ui.TwoSpriteButton::new(tabdis["2"], taben["2"])
  buttons[bid_tab_setup] = @ui.TwoSpriteButton::new(tabdis["3"], taben["3"])
  buttons[bid_tab_cash] = @ui.TwoSpriteButton::new(tabdis["4"], taben["4"])
  buttons[bid_coin] = @ui.MapleButton::from_resource(item["BtCoin3"])
  buttons[bid_point] = @ui.MapleButton::from_resource(item["BtPoint0"])
  buttons[bid_gather] = @ui.MapleButton::from_resource(item["BtGather3"])
  buttons[bid_sort] = @ui.MapleButton::from_resource(item["BtSort3"])
  buttons[bid_full] = @ui.MapleButton::from_resource(item["BtFull3"])
  buttons[bid_small] = @ui.MapleButton::from_resource(item["BtSmall3"])
  buttons[bid_pot] = @ui.MapleButton::from_resource(item["BtPot3"])
  buttons[bid_upgrade] = @ui.MapleButton::from_resource(item["BtUpgrade3"])
  buttons[bid_appraise] = @ui.MapleButton::from_resource(item["BtAppraise3"])
  buttons[bid_extract] = @ui.MapleButton::from_resource(item["BtExtract3"])
  buttons[bid_disassemble] = @ui.MapleButton::from_resource(
    item["BtDisassemble3"],
  )
  buttons[bid_toad] = @ui.MapleButton::from_resource(item["BtToad3"])
  buttons[bid_coin_sm] = @ui.MapleButton::from_resource(item["BtCoin4"])
  buttons[bid_point_sm] = @ui.MapleButton::from_resource(item["BtPoint1"])
  buttons[bid_gather_sm] = @ui.MapleButton::from_resource(item["BtGather4"])
  buttons[bid_sort_sm] = @ui.MapleButton::from_resource(item["BtSort4"])
  buttons[bid_full_sm] = @ui.MapleButton::from_resource(item["BtFull4"])
  buttons[bid_small_sm] = @ui.MapleButton::from_resource(item["BtSmall4"])
  buttons[bid_pot_sm] = @ui.MapleButton::from_resource(item["BtPot4"])
  buttons[bid_upgrade_sm] = @ui.MapleButton::from_resource(item["BtUpgrade4"])
  buttons[bid_appraise_sm] = @ui.MapleButton::from_resource(item["BtAppraise4"])
  buttons[bid_extract_sm] = @ui.MapleButton::from_resource(item["BtExtract4"])
  buttons[bid_disassemble_sm] = @ui.MapleButton::from_resource(
    item["BtDisassemble4"],
  )
  buttons[bid_toad_sm] = @ui.MapleButton::from_resource(item["BtToad4"])
  buttons[bid_cashshop] = @ui.MapleButton::from_resource(item["BtCashshop"])
  buttons[bid_pot]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[bid_pot_sm]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[bid_extract]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[bid_extract_sm]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[bid_disassemble]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[bid_disassemble_sm]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[button_by_tab(tab)]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::PRESSED)
  let meso_label = @graphics.Text::new(
    "",
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  // TODO: support maple points
  let maple_points_label = @graphics.Text::new(
    "0",
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  let ui = {
    base: @ui.UIElementBase::default(),
    buttons: { buttons, },
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
  self.base.draw(alpha)
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
          icon.draw(position + slotpos)
        }
      None =>
        if i > numslots && i <= lastslot {
          self.disabled.draw(position + slotpos |> @graphics.DrawArgument::new)
        }
    }
  }
  // TODO: bulletslot
  // TODO: new_tab
  self.buttons.draw(position)
}

pub fn update(self : UIItemInventory) -> Unit {
  self.base.update()
  let meso_str = @string_format.format_decimal_separator(
    self.inventory.get_meso(),
  )
  self.meso_label = self.meso_label.change_text(meso_str)
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
  // TODO: support scroll
  return slot < 1 || slot > 24
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
  self.icons[slot] = Icon::new(NullType::default(), texture, count) // TODO: support drop
}

let bid_close = 0

let bid_tab_equip = 1

let bid_tab_use = 2

let bid_tab_etc = 3

let bid_tab_setup = 4

let bid_tab_cash = 5

let bid_coin = 6

let bid_point = 7

let bid_gather = 8

let bid_sort = 9

let bid_full = 10

let bid_small = 11

let bid_pot = 12

let bid_upgrade = 13

let bid_appraise = 14

let bid_extract = 15

let bid_disassemble = 16

let bid_toad = 17

let bid_coin_sm = 18

let bid_point_sm = 19

let bid_gather_sm = 20

let bid_sort_sm = 21

let bid_full_sm = 22

let bid_small_sm = 23

let bid_pot_sm = 24

let bid_upgrade_sm = 25

let bid_appraise_sm = 26

let bid_extract_sm = 27

let bid_disassemble_sm = 28

let bid_toad_sm = 29

let bid_cashshop = 30

pub fn button_by_tab(tb : TypeId) -> Int {
  match tb {
    TypeId::EQUIP => bid_tab_equip
    TypeId::USE => bid_tab_use
    TypeId::SETUP => bid_tab_setup
    TypeId::ETC => bid_tab_etc
    _ => bid_tab_cash
  }
}

pub fn UIItemInventory::is_focused() -> Bool {
  false
}

pub fn get_ui_element_base(self : UIItemInventory) -> @ui.UIElementBase {
  self.base
}

pub fn send_cursor(
  self : UIItemInventory,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  // TODO: implement
  self.buttons.send_cursor(
    self.base.position,
    fn(buttonid) { self.button_pressed(buttonid) },
    pressed,
    cursorpos,
  )
}

pub fn button_pressed(
  self : UIItemInventory,
  buttonid : Int
) -> @ui.ButtonState {
  // TODO: implement
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

pub fn is_in_range(self : UIItemInventory, pos : @struct.Point[Int]) -> Bool {
  self.base.is_in_range(pos)
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
