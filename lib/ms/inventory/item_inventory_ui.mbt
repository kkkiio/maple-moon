///| ItemInventory Dialog
/// 
/// support full display mode only for now
/// TODO: support projectile 
struct UIItemInventory {
  logic_state : LogicState
  resources : Resources
  mut render_state : RenderState?
}

struct Attributes {
  player : @player.Player
  inventory : Inventory
}

struct LogicState {
  base : @ui.UIModel
  mut attributes : Attributes
  tab_btns : Array[@ui.TwoSpriteButton]
  tab_types : Array[TypeId]
  mut tab : Int
}

struct Resources {
  full_backgrnd : @graphics.Texture
  full_backgrnd2 : @graphics.Texture
  full_backgrnd3 : @graphics.Texture
  disabled : @graphics.Texture
  close_btn : @ui.MapleButton
  meso_label : @graphics.Text
  maple_points_label : @graphics.Text
}

struct RenderState {
  buttons : Array[@ui.Button]
  position : @struct.Point[Int]
  meso_label : @graphics.Text
  maple_points_label : @graphics.Text
  icons : Map[Int, (IconModel, @utils.Future[@graphics.Texture])]
  numslots : Int
}

pub fn UIItemInventory::new(attributes : Attributes) -> UIItemInventory {
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
  let model = @ui.UIModel::new(@struct.Point::new(300, 160), bg_full_dimensions)
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
  let tab_btns : Array[@ui.TwoSpriteButton] = [
    @ui.TwoSpriteButton::new(
      @graphics.Texture::from_resource(tabdis["0"]),
      @graphics.Texture::from_resource(taben["0"]),
    ),
    @ui.TwoSpriteButton::new(
      @graphics.Texture::from_resource(tabdis["1"]),
      @graphics.Texture::from_resource(taben["1"]),
    ),
    @ui.TwoSpriteButton::new(
      @graphics.Texture::from_resource(tabdis["2"]),
      @graphics.Texture::from_resource(taben["2"]),
    ),
    @ui.TwoSpriteButton::new(
      @graphics.Texture::from_resource(tabdis["3"]),
      @graphics.Texture::from_resource(taben["3"]),
    ),
    @ui.TwoSpriteButton::new(
      @graphics.Texture::from_resource(tabdis["4"]),
      @graphics.Texture::from_resource(taben["4"]),
    ),
  ]
  let tab_types = [
    TypeId::EQUIP,
    TypeId::USE,
    TypeId::SETUP,
    TypeId::ETC,
    TypeId::CASH,
  ]
  let close_btn = @ui.MapleButton::from_resource(close)
  let logic_state = { base: model, attributes, tab_btns, tab_types, tab: 0 }
  let resources = {
    disabled,
    full_backgrnd,
    full_backgrnd2,
    full_backgrnd3,
    close_btn,
    meso_label,
    maple_points_label,
  }
  { logic_state, resources, render_state: None }
}

pub fn draw(self : UIItemInventory, _alpha : Double) -> Unit {
  self.use_render_state().draw(self.resources)
}

fn draw(self : RenderState, resources : Resources) -> Unit {
  let position = self.position
  let mesolabel_pos = position + @struct.Point::new(127, 262)
  let maplepointslabel_pos = position + @struct.Point::new(159, 279)

  // TODO: support scroll
  resources.full_backgrnd.draw(position |> @graphics.DrawArgument::new)
  resources.full_backgrnd2.draw(position |> @graphics.DrawArgument::new)
  resources.full_backgrnd3.draw(position |> @graphics.DrawArgument::new)
  self.meso_label.draw(mesolabel_pos + @struct.Point::new(3, 70))
  self.maple_points_label.draw(
    maplepointslabel_pos + @struct.Point::new(181, 53),
  )
  let firstslot = 1
  let lastslot = max_full_slots
  let numslots = self.numslots
  for i in 0..=max_full_slots {
    let slotpos = get_full_slotpos(i)
    match self.icons.get(i) {
      Some(icon) =>
        if i >= firstslot && i <= lastslot {
          match icon.1.poll() {
            Some(texture) => icon.0.draw(position + slotpos, texture)
            None => ()
          }
        }
      None =>
        if i > numslots && i <= lastslot {
          resources.disabled.draw(
            position + slotpos |> @graphics.DrawArgument::new,
          )
        }
    }
  }
  // TODO: bulletslot
  // TODO: new_tab
  for button in self.buttons {
    button.object.draw(position)
  }
}

fn use_render_state(self : UIItemInventory) -> RenderState {
  match self.render_state {
    Some(rs) => rs
    None => {
      let render_state = render(
        self.logic_state,
        self.resources,
        fn() { self.render_state = None },
      )
      self.render_state = Some(render_state)
      render_state
    }
  }
}

fn render(
  self : LogicState,
  resources : Resources,
  on_state_changed : () -> Unit
) -> RenderState {
  let tab = self.tab
  let numslots = self.attributes.inventory.get_slotmax(self.tab_types[tab])
  let buttons = []
  buttons.push(
    resources.close_btn
    |> @ui.Button::new(
      on_click=fn() {
        self.base.toggle_active()
        @ui.ButtonState::NORMAL
      },
    ),
  )
  let make_change_tab_cb = fn(new_tab : Int) {
    fn() {
      guard self.tab != new_tab else { return @ui.ButtonState::IDENTITY }
      self.tab = new_tab
      on_state_changed()
      @ui.ButtonState::IDENTITY
    }
  }
  buttons.push_iter(
    self.tab_btns
    .iter2()
    .iter()
    .map(
      fn(it) {
        let (i, btn) = it
        btn
        .get_button_base()
        .set_state(
          if i == tab {
            @ui.ButtonState::PRESSED
          } else {
            @ui.ButtonState::NORMAL
          },
        )
        @ui.Button::new(btn, on_click=make_change_tab_cb(i))
      },
    ),
  )
  let icons = {}
  let inventory = self.attributes.inventory
  let tab_type = self.tab_types[tab]
  let numslots = inventory.get_slotmax(tab_type)
  for i in 0..=max_full_slots {
    if i <= numslots {
      match make_slot(inventory, tab_type, i) {
        Some(icon) => icons[i] = icon
        None => ()
      }
    }
  }
  {
    buttons,
    position: self.base.position,
    meso_label: resources.meso_label.with_text(
      @string_format.format_decimal_separator(inventory.get_meso()),
    ),
    maple_points_label: resources.maple_points_label,
    icons,
    numslots,
  }
}

pub fn update(self : UIItemInventory) -> Unit {
  let render_state = self.use_render_state()
  for button in render_state.buttons {
    button.object.update()
  }
}

pub fn set_attributes(self : UIItemInventory, attributes : Attributes) -> Unit {
  self.logic_state.attributes = attributes
  self.render_state = None
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
  let tab = self.logic_state.tab
  let numslots = self.logic_state.attributes.inventory.get_slotmax(
    self.logic_state.tab_types[tab],
  )
  slot < 1 || slot > numslots
}

fn make_slot(
  inventory : Inventory,
  tab : TypeId,
  slot : Int
) -> (IconModel, @utils.Future[@graphics.Texture])? {
  let item_id = inventory.get_item_id(tab, slot)
  guard item_id != 0 else { return None }
  let count = if tab == TypeId::EQUIP {
    -1
  } else {
    inventory.get_item_count(tab, slot)
  }
  let texture = @item.ItemData::get_async(item_id).map(
    fn(r) {
      match r {
        Ok(item_data) => item_data.get_icon(false)
        Err(e) => {
          @log.error(
            { "item_id": item_id, "error": e },
            "failed to load item data",
          )
          @graphics.Texture::default() // TODO: show error icon
        }
      }
    },
  )
  Some((IconModel::new(count), texture)) // TODO: support drop
}

pub fn UIItemInventory::is_focused() -> Bool {
  false
}

pub fn get_ui_model(self : UIItemInventory) -> @ui.UIModel {
  self.logic_state.base
}

pub fn send_cursor(
  self : UIItemInventory,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  // TODO: implement
  let render_state = self.use_render_state()
  @ui.send_cursor_to_btns(
    render_state.buttons.iter(),
    render_state.position,
    pressed,
    cursorpos,
  )
}

pub fn send_key(
  self : UIItemInventory,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

pub fn remove_cursor(self : UIItemInventory) -> Unit {
  // TODO: implement
  // self.slider_.remove_cursor()
}

pub fn doubleclick(
  self : UIItemInventory,
  cursorpos : @struct.Point[Int]
) -> Unit {
  let render_state = self.use_render_state()
  let slot = self.slot_by_position(cursorpos - render_state.position)
  if render_state.icons.contains(slot) && self.is_visible(slot) {
    let inventory = self.logic_state.attributes.inventory
    let tab = self.logic_state.tab_types[self.logic_state.tab]
    guard let Some(item_data) = inventory.get_item_at_slot(tab, slot) else {
      None => ()
    }
    match tab {
      TypeId::EQUIP => {
        let equip_data = @equip.EquipData::from_item_data?(item_data).unwrap() // TODO: handle error
        if self.can_wear_equip(equip_data) {
          new_equip_item_packet(slot, inventory.find_equipslot(equip_data)).dispatch()
        }
      }
      TypeId::USE => new_use_item_packet(slot, item_data.item_id).dispatch()
      _ => ()
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

pub fn can_wear_equip(
  self : UIItemInventory,
  equip_data : @equip.EquipData
) -> Bool {
  let player = self.logic_state.attributes.player
  let stats = player.get_stats()
  let look = player.get_look()
  let alerted = look.get_alerted()
  if alerted {
    // TODO: alert
    return false
  }
  let reqGender = equip_data.get_gender()
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
  let reqLevel = equip_data.get_reqstat(@maple_stat.Id::LEVEL)
  let reqDEX = equip_data.get_reqstat(@maple_stat.Id::DEX)
  let reqSTR = equip_data.get_reqstat(@maple_stat.Id::STR)
  let reqLUK = equip_data.get_reqstat(@maple_stat.Id::LUK)
  let reqINT = equip_data.get_reqstat(@maple_stat.Id::INT)
  let reqFAME = equip_data.get_reqstat(@maple_stat.Id::FAME)
  let mut i = 0
  if reqLevel > stats.get_level() {
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

/// Packet which requests that an item is moved
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

/// Packet which requests that an item is equipped
pub fn new_equip_item_packet(src : Int, dest : @slot.Id) -> @net.OutPacket {
  new_move_item_packet(TypeId::EQUIP, src, -dest.int_value(), 1)
}
