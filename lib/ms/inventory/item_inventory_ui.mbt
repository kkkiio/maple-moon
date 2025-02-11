///| ItemInventory Dialog
/// 
/// support full display mode only for now
/// TODO: support projectile 
struct ItemInventoryUI {
  base : @ui.UIModel
  inventory : Inventory
  tab_types : Array[TypeId]
  mut tab : Int
  mut slot_item_map : Map[Int, ItemIcon]
  mut inventory_version : Int
  slot_item_effect_hook : @ui.EffectHook[(Int, Int)]
  resources : ItemInventoryUIResources
  hooks : @ui.Hooks
  io_service : @io_task.Service
  on_changing_equip : (Int, @equip_data.EquipData) -> Unit
  on_using_item : (Int, Int) -> Unit
}

///|
struct ItemInventoryUIResources {
  full_backgrnd : @graphics.Texture
  full_backgrnd2 : @graphics.Texture
  full_backgrnd3 : @graphics.Texture
  disabled : @graphics.Texture
  close_btn_res : @ui.MapleButtonResource
  tab_btn_resources : Array[(@graphics.Texture, @graphics.Texture)]
} derive(Default)

///|
pub fn ItemInventoryUIResources::load() ->
     @utils.Future[ItemInventoryUIResources] {
  @ui.ui_window_2_loader()
  .load_res(["Item"])
  .map(fn(item) {

    // TODO: Change these to production
    let full_backgrnd = item["FullBackgrnd"] |> @graphics.Texture::from_resource
    let full_backgrnd2 = item["FullBackgrnd2"]
      |> @graphics.Texture::from_resource
    let full_backgrnd3 = item["FullBackgrnd3"]
      |> @graphics.Texture::from_resource

    // TODO: new tab

    let disabled = item["disabled"] |> @graphics.Texture::from_resource
    let srctab = item["Tab"]
    let enabled_tabs = srctab["enabled"]
    let disabled_tabs = srctab["disabled"]
    let close = @ui.common_ui_loader().load_res(["Basic.img", "BtClose3"])
    let tab_btn_resources = [
      (
        @graphics.Texture::from_resource(disabled_tabs["0"]),
        @graphics.Texture::from_resource(enabled_tabs["0"]),
      ),
      (
        @graphics.Texture::from_resource(disabled_tabs["1"]),
        @graphics.Texture::from_resource(enabled_tabs["1"]),
      ),
      (
        @graphics.Texture::from_resource(disabled_tabs["2"]),
        @graphics.Texture::from_resource(enabled_tabs["2"]),
      ),
      (
        @graphics.Texture::from_resource(disabled_tabs["3"]),
        @graphics.Texture::from_resource(enabled_tabs["3"]),
      ),
      (
        @graphics.Texture::from_resource(disabled_tabs["4"]),
        @graphics.Texture::from_resource(enabled_tabs["4"]),
      ),
    ]
    let close_btn_res = @ui.MapleButtonResource::from_resource(close)
    {
      disabled,
      full_backgrnd,
      full_backgrnd2,
      full_backgrnd3,
      close_btn_res,
      tab_btn_resources,
    }
  })
}

///|
pub fn ItemInventoryUI::new(
  inventory : Inventory,
  io_service : @io_task.Service,
  resources : ItemInventoryUIResources,
  hooks : @ui.Hooks,
  on_changing_equip~ : (Int, @equip_data.EquipData) -> Unit = fn(_, _) {  },
  on_using_item~ : (Int, Int) -> Unit = fn(_, _) {  }
) -> ItemInventoryUI {
  let bg_full_dimensions = resources.full_backgrnd.get_dimensions()
  let model = @ui.UIModel::new(@struct.Point::new(300, 160), bg_full_dimensions)
  let tab_types = [TypeId::EQUIP, TypeId::USE, TypeId::SETUP, TypeId::ETC]
  let ui : ItemInventoryUI = {
    base: model,
    inventory,
    io_service,
    tab_types,
    tab: 0,
    resources,
    hooks,
    slot_item_map: {},
    inventory_version: 0,
    slot_item_effect_hook: @ui.EffectHook::new(),
    on_changing_equip,
    on_using_item,
  }
  // hooks.on_double_click = fn(pos) { ui.doubleclick(pos) }
  inventory.listen_item_changes(fn() {
    guard ui.get_ui_model().active else { return false }
    ui.inventory_version += 1
    (hooks.on_state_changed)()
    true
  })
  ui
}

///|
pub impl @ui.Widget for ItemInventoryUI with render(self) -> @ui.RenderSpec {
  let render_elements : Array[@ui.RenderElement] = []
  let resources = self.resources
  let inventory = self.inventory
  let tab_type = self.tab_types[self.tab]
  let numslots = inventory.get_slotmax(tab_type)
  let meso_label = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
    text=@string_format.format_decimal_separator(inventory.get_meso()),
  )
  // TODO: support maple points
  let maple_points_label = @graphics.Text::new(
    text="0",
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  // Add background textures
  render_elements.push(
    @ui.RenderElement::Static(
      @ui.StaticUnit::new(@ui.TextureUI(resources.full_backgrnd)),
    ),
  )
  render_elements.push(
    @ui.RenderElement::Static(
      @ui.StaticUnit::new(@ui.TextureUI(resources.full_backgrnd2)),
    ),
  )
  render_elements.push(
    @ui.RenderElement::Static(
      @ui.StaticUnit::new(@ui.TextureUI(resources.full_backgrnd3)),
    ),
  )

  // Add labels
  render_elements.push(
    @ui.OffsetedUnit::new(
      @ui.StaticUnit::new(@ui.TextUI(meso_label)),
      @struct.Point::new(130, 332),
    )
    |> @ui.RenderElement::Static,
  )
  render_elements.push(
    @ui.OffsetedUnit::new(
      @ui.StaticUnit::new(@ui.TextUI(maple_points_label)),
      @struct.Point::new(340, 332),
    )
    |> @ui.RenderElement::Static,
  )

  // Update slot items
  self.slot_item_effect_hook.use_effect((self.tab, self.inventory_version), fn(

  ) {
    let slot_item_map = {}
    for i in 0..=max_full_slots {
      if i <= numslots {
        match make_slot(inventory, tab_type, i) {
          Some((icon, texture_fut)) =>
            self.io_service.on_complete(texture_fut, fn(texture) {
              slot_item_map[i] = {
                icon,
                texture,
                on_double_click: match tab_type {
                  TypeId::EQUIP =>
                    fn() {
                      let slot = i
                      guard let Some(item_data) = inventory.get_item_at_slot(
                        tab_type, slot,
                      ) else {
                        None => return
                      }
                      let equip_data = @equip_data.EquipData::from_item_data?(
                        item_data,
                      ).unwrap() // TODO: handle error
                      (self.on_changing_equip)(slot, equip_data)
                    }
                  TypeId::USE =>
                    fn() {
                      let slot = i
                      guard let Some(item_data) = inventory.get_item_at_slot(
                        tab_type, slot,
                      ) else {
                        None => return
                      }
                      (self.on_using_item)(slot, item_data.item_id)
                    }
                  _ => fn() {  }
                },
                pos: @struct.Point::default(),
              }
              (self.hooks.on_state_changed)()
            })
          None => ()
        }
      }
    }
    self.slot_item_map = slot_item_map
  })

  // Add slots and items
  let firstslot = 1
  let lastslot = max_full_slots
  for i in 0..=max_full_slots {
    let slotpos = get_full_slotpos(i)
    if i >= firstslot && i <= lastslot {
      match self.slot_item_map.get(i) {
        Some(item) =>
          render_elements.push({ ..item, pos: slotpos }.as_interactable())
        None =>
          if i > numslots {
            render_elements.push(
              @ui.OffsetedUnit::new(
                @ui.StaticUnit::new(@ui.TextureUI(resources.disabled)),
                slotpos,
              )
              |> @ui.RenderElement::Static,
            )
          }
      }
    }
  }

  // Add close button and tab buttons
  render_elements.push(
    (@ui.MapleButton::new(
      resources.close_btn_res,
      pos=@struct.Point::new(476, 6),
    )
    |> @ui.Button::new(on_click=fn() {
      self.base.toggle_active()
      Some(@ui.ButtonState::NORMAL)
    })).as_interactable(),
  )
  fn change_tab(new_tab : Int) {
    guard self.tab != new_tab else { return None }
    self.tab = new_tab
    (self.hooks.on_state_changed)()
    None
  }

  render_elements.push_iter(
    (0)
    .until(self.tab_types.length())
    .map(fn(i) {
      let (disabled, enabled) = resources.tab_btn_resources[i]
      let btn = @ui.TwoSpriteButton::new(
        disabled,
        enabled,
        state=if i == self.tab {
          @ui.ButtonState::PRESSED
        } else {
          @ui.ButtonState::NORMAL
        },
      )
      @ui.Button::new(btn, on_click=fn() { change_tab(i) }).as_interactable()
    }),
  )
  { render_elements, }
}

///|
struct ItemIcon {
  icon : IconModel
  texture : @graphics.Texture
  on_double_click : () -> Unit
  pos : @struct.Point[Int]
}

///|
pub impl @graphics.Drawable for ItemIcon with draw(self, args) -> Unit {
  self.icon.draw(args.pos + self.pos, self.texture)
}

///|
pub impl @ui.RenderUnit for ItemIcon with update(self) -> Unit { ignore(self) }

///|
pub fn ItemIcon::as_interactable(self : ItemIcon) -> @ui.RenderElement {
  @ui.RenderElement::Interactable(self, {
    bounds: IconModel::get_bounds(self.texture).shift(self.pos),
    on_click: fn() {  },
    on_double_click: self.on_double_click,
    state: Ref::new(@ui.ButtonState::NORMAL),
  })
}

///|
pub impl ToJson for ItemIcon with to_json(self) -> Json {
  { "icon": self.icon.to_json(), "texture": self.texture.to_json() }
}

///|
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

///|
let rows = 8

///|
let columns = 4

///|
let max_slots : Int = rows * columns

///|
let max_full_slots : Int = columns * max_slots

///|
let icon_width = 36

///|
let icon_height = 35

///|
pub fn is_visible(self : ItemInventoryUI, slot : Int) -> Bool {
  not(self.is_not_visible(slot))
}

///|
pub fn is_not_visible(self : ItemInventoryUI, slot : Int) -> Bool {
  let tab = self.tab
  let numslots = self.inventory.get_slotmax(self.tab_types[tab])
  slot < 1 || slot > numslots
}

///|
fn make_slot(
  inventory : Inventory,
  tab : TypeId,
  slot : Int
) -> (IconModel, @utils.Future[@graphics.Texture])? {
  let item_id = inventory.get_item_id(tab, slot)
  guard item_id != 0 else { return None }
  let count = if tab == TypeId::EQUIP {
    None
  } else {
    inventory.get_item_count(tab, slot) |> Some
  }
  let texture = @item.ItemData::get_async(item_id).map(fn(r) {
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
  })
  Some((IconModel::new(count), texture)) // TODO: support drop
}

///|
pub fn ItemInventoryUI::is_focused() -> Bool {
  false
}

///|
pub fn get_ui_model(self : ItemInventoryUI) -> @ui.UIModel {
  self.base
}

///|
pub fn send_key(
  self : ItemInventoryUI,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

///|
pub fn remove_cursor(self : ItemInventoryUI) -> Unit {
  // TODO: implement
  // self.slider_.remove_cursor()
}

///|
fn slot_by_position(
  self : ItemInventoryUI,
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

///|
fn can_wear_equip(
  player : @player.Player,
  equip_data : @equip_data.EquipData
) -> Bool {
  let look = player.character.get_look()
  let alerted = look.get_alerted()
  if alerted {
    // TODO: alert
    return false
  }
  let stats = player.get_stats()
  let reqGender = equip_data.get_gender()
  let female = stats.get_female()
  match reqGender {
    0 => // Male
      if female {
        return false
      }
    1 => // Female
      if not(female) {
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
  if reqLevel > stats.get_stat(@maple_stat.Id::LEVEL) {
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

///|
pub fn new_use_item_packet(slot : Int, itemid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::USE_ITEM)
  ..write_time()
  ..write_short(slot)
  ..write_int(itemid)
}

///| Packet which requests that an item is moved
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
