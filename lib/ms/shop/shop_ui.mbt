///| UI for the shop
/// 
/// right_click will sell items
struct UIShop {
  hooks : @ui.Hooks
  logic_state : LogicState
  resources : Resources
  mut runtime_state : RuntimeState?
}

///|
struct LogicState {
  attributes : Attributes
  model : @ui.UIModel
  buy_state : BuyState
  sell_state : SellState
  mut selection : (Bool, Int)?
}

///|
struct Attributes {
  countset : @graphics.Charset
  charlook : @char_look.CharLook
  inventory : @inventory.Inventory
  npcid : Int
  shop_items : Array[ShopItem]
}

///|
struct RuntimeState {
  position : @struct.Point[Int]
  sprites : Array[@graphics.Sprite]
  buttons : Array[@ui.Button]
  npc : @graphics.Texture
  charlook : @char_look.CharLook
  meso_label : @graphics.Text
  draws : Array[(@struct.Point[Int]) -> Unit]
}

///|
struct Resources {
  buy_selection : @graphics.Texture
  sell_selection : @graphics.Texture
  tab_buttons : Array[(@inventory.TypeId, @ui.TwoSpriteButton)]
  buy_button : @ui.MapleButton
  sell_all_button : @ui.MapleButton
  exit_button : @ui.MapleButton
  sprites : Array[@graphics.Sprite]
}

///|
fn UIShop::new(
  attributes : Attributes,
  src : @resource.NxNode,
  hooks : @ui.Hooks
) -> UIShop {
  let background = src["backgrnd"]
  let bg = @graphics.Texture::from_resource(background)
  let bg_dimensions = bg.get_dimensions()
  let sprites = [
    @graphics.Sprite::from_resource(background),
    @graphics.Sprite::from_resource(src["backgrnd2"]),
    @graphics.Sprite::from_resource(src["backgrnd3"]),
    @graphics.Sprite::from_resource(src["backgrnd4"]),
  ]
  let buy_selection = @graphics.Texture::from_resource(src["select"])
  let sell_selection = @graphics.Texture::from_resource(src["select2"])
  let meso = @graphics.Texture::from_resource(src["meso"])
  let items = attributes.shop_items
  let buy_state = BuyState::new(meso, items)
  let sell_state = SellState::new()
  let model = @ui.UIModel::new(@struct.Point::new(146, 48), bg_dimensions)
  let buy_button = @ui.MapleButton::from_resource(src["BtBuy"])
  let sell_all_button = @ui.MapleButton::from_resource(src["BtSell"]) // FIXME: use new texture for sell all
  let exit_button = @ui.MapleButton::from_resource(src["BtExit"])
  let sellen = src["TabSell"]["enabled"]
  let selldis = src["TabSell"]["disabled"]
  let tab_buttons = [
    @inventory.TypeId::EQUIP,
    @inventory.TypeId::USE,
    @inventory.TypeId::ETC,
    @inventory.TypeId::SETUP,
    @inventory.TypeId::CASH,
  ].mapi(fn(i, inventory_type) {
    let tabnum = i.to_string()
    (
      inventory_type,
      @ui.TwoSpriteButton::new(
        selldis[tabnum] |> @graphics.Texture::from_resource,
        sellen[tabnum] |> @graphics.Texture::from_resource,
      ),
    )
  })
  let logic_state = {
    attributes,
    model,
    buy_state,
    sell_state,
    selection: None,
  }
  let resources = {
    buy_selection,
    sell_selection,
    tab_buttons,
    buy_button,
    sell_all_button,
    exit_button,
    sprites,
  }
  { hooks, logic_state, resources, runtime_state: None }
}

///|
pub fn draw(self : UIShop, alpha : Double) -> Unit {
  use_runtime_state(self).draw(alpha)
}

///|
pub fn set_attributes(self : UIShop) -> Unit { // TODO: store the info in attributes directly
  self.runtime_state = None
}

///|
fn render(
  self : LogicState,
  resources : Resources,
  on_state_changed : () -> Unit
) -> RuntimeState {
  let npcid = self.attributes.npcid
  let npc = @graphics.Texture::from_resource(
    @npc.npc_loader().load_res(["\{npcid}.img", "stand", "0"]),
  )
  let inventory = self.attributes.inventory
  let draws = []
  let sell_items = []
  let sell_item_tab = self.sell_state.tab
  let slots = inventory.get_slotmax(sell_item_tab)
  for i in 1..=slots {
    match inventory.get_item_id(sell_item_tab, i) {
      0 => ()
      item_id => {
        let count = inventory.get_item_count(sell_item_tab, i)
        sell_items.push(
          SellItem::new(
            item_id,
            count,
            i,
            sell_item_tab != @inventory.TypeId::EQUIP,
          ),
        )
      }
    }
  }
  let buttons = [
    resources.buy_button
    |> @ui.Button::new(on_click=fn() {
      match self.selection {
        Some((true, i)) => self.buy_state.buy(i)
        _ => ()
      }
      return Some(@ui.ButtonState::NORMAL)
    }),
    resources.sell_all_button
    |> @ui.Button::new(on_click=fn() {
      match self.selection {
        Some((false, i)) => sell(sell_items, i, all=true)
        _ => ()
      }
      return Some(@ui.ButtonState::NORMAL)
    }),
    resources.exit_button
    |> @ui.Button::new(on_click=fn() {
      self.exit_shop()
      return Some(@ui.ButtonState::PRESSED)
    }),
  ]
  buttons.push_iter(
    resources.tab_buttons
    .iter()
    .map(fn(it) {
      let (inventory_type, button) = it
      button
      .get_button_base()
      .set_state(
        if self.sell_state.tab == inventory_type {
          @ui.ButtonState::PRESSED
        } else {
          @ui.ButtonState::NORMAL
        },
      )
      button
      |> @ui.Button::new(on_click=fn() {
        self.sell_state.tab = inventory_type
        self.sell_state.offset = 0
        on_state_changed()
        return Some(@ui.ButtonState::NORMAL)
      })
    }),
  )
  let buy_x = 8
  let buy_width = 257
  for i in 0..<9 {
    let pos = @struct.Point::new(buy_x, 116 + 42 * i)
    let dim = @struct.Point::new(buy_width, 42)
    buttons.push(
      @ui.AreaButton::new(pos, dim)
      |> @ui.Button::new(on_click=fn() {
        self.selection = Some((true, i))
        on_state_changed()
        return Some(@ui.ButtonState::NORMAL)
      }),
    )
  }
  for i in 0..<9 {
    let slot = i + self.buy_state.offset
    if slot >= self.buy_state.last_slot {
      break
    }
    let itempos = @struct.Point::new(12, 116 + 42 * i)
    if Some((true, slot)) == self.selection {
      draws.push(fn(parentpos) {
        resources.buy_selection.draw(
          @graphics.DrawArgument::new(
            position=parentpos + itempos + @struct.Point::new(35, 8),
          ),
        )
      })
    }
    let item = self.buy_state.items[slot]
    draws.push(fn(parentpos) {
      guard let Some((icon, name_label)) = item.display.poll().flatten() else {
        None => return
      }
      let pos = parentpos + itempos
      icon.draw(
        @graphics.DrawArgument::new(position=pos + @struct.Point::new(0, 42)),
      )
      name_label.draw(pos + @struct.Point::new(40, 6))
      item.currency.draw(
        @graphics.DrawArgument::new(position=pos + @struct.Point::new(38, 29)),
      )
      item.price_label.draw(pos + @struct.Point::new(55, 24))
    })
  }
  let sell_x = 284
  let sell_width = 200
  for i in 0..<9 {
    let pos = @struct.Point::new(sell_x, 116 + 42 * i)
    let dim = @struct.Point::new(sell_width, 42)
    let button = @ui.AreaButton::new(pos, dim)
    button
    .get_button_base()
    .set_state(
      if i < sell_items.length() {
        @ui.ButtonState::NORMAL
      } else {
        @ui.ButtonState::DISABLED
      },
    )
    buttons.push(
      button
      |> @ui.Button::new(on_click=fn() {
        self.selection = Some((false, i))
        on_state_changed()
        return Some(@ui.ButtonState::NORMAL)
      }),
    )
  }
  for i in 0..<9 {
    let slot = i + self.sell_state.offset
    if slot >= sell_items.length() {
      break
    }
    let itempos = @struct.Point::new(243, 116 + 42 * i)
    if Some((false, slot)) == self.selection {
      draws.push(fn(parentpos) {
        resources.sell_selection.draw(
          @graphics.DrawArgument::new(
            position=parentpos + itempos + @struct.Point::new(78, 8),
          ),
        )
      })
    }
    let item = sell_items[slot]
    draws.push(fn(parentpos) {
      guard let Some((icon, name_label, price_label)) = item.display
        .poll()
        .flatten() else {
        None => return
      }
      let pos = parentpos + itempos
      icon.draw(
        @graphics.DrawArgument::new(position=pos + @struct.Point::new(43, 42)),
      )
      if item.show_count {
        self.attributes.countset.draw_text(
          item.sellable.to_string(),
          @graphics.DrawArgument::new(position=pos + @struct.Point::new(41, 28)),
        )
        |> ignore
      }
      name_label.draw(pos + @struct.Point::new(84, 6))
      price_label.draw(pos + @struct.Point::new(84, 24))
    })
  }
  let num_mesos = inventory.get_meso()
  let mesostr = @string_format.format_decimal_separator(num_mesos)
  let meso_label = @graphics.Text::new(
    text=mesostr,
    @graphics.FontId::A11M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::MINESHAFT,
  )
  {
    npc,
    charlook: self.attributes.charlook,
    meso_label,
    draws,
    buttons,
    sprites: resources.sprites,
    position: self.model.position,
  }
}

///|
fn use_runtime_state(self : UIShop) -> RuntimeState {
  match self.runtime_state {
    Some(rs) => rs
    None => {
      let render_state = render(self.logic_state, self.resources, fn() {
        self.runtime_state = None
      })
      self.runtime_state = Some(render_state)
      render_state
    }
  }
}

///|
fn draw(self : RuntimeState, alpha : Double) -> Unit {
  let position = self.position
  self.sprites.each(fn(sprite) { sprite.draw(position, alpha) })
  for _, button in self.buttons {
    button.object.draw(position)
  }
  self.npc.draw(
    @graphics.DrawArgument::new(
      position=position + @struct.Point::new(58, 85),
      flip=true,
    ),
  )
  self.charlook.draw_with_stance(
    position + @struct.Point::new(338, 85),
    false,
    @types.StanceId::STAND1,
    @char_look.ExpressionId::DEFAULT,
  )
  self.meso_label.draw(position + @struct.Point::new(493, 51))
  self.draws.each(fn(draw) { draw(position) })
}

///|
struct BuyState {
  items : Array[BuyItem]
  offset : Int
  last_slot : Int
}

///|
fn BuyState::new(
  currency : @graphics.Texture,
  shop_items : Array[ShopItem]
) -> BuyState {
  let items = []
  for shop_item in shop_items {
    let display = @item.ItemData::get_async(shop_item.id)
      .map_exn(fn(item) {
        let item = item.unwrap_or_error!()
        let (icon, name) = (item.get_icon(false), item.name)
        let name_label = @graphics.Text::new(
          text=name,
          @graphics.FontId::A11M,
          @graphics.TextAlignment::LEFT,
          @struct.ColorName::MINESHAFT,
        )
        (icon, name_label)
      })
      .map(fn(r) {
        match r {
          Ok(r) => Some(r)
          Err(err) => {
            @log.error(
              { "err": Show::to_string(err), "item_id": shop_item.id },
              "Failed to get item data",
            )
            None
          }
        }
      })
    let mesostr = @string_format.format_decimal_separator(shop_item.price)
    let price_label = @graphics.Text::new(
      text=mesostr + "meso",
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::MINESHAFT,
    )
    let buyitem : BuyItem = {
      display,
      currency,
      id: shop_item.id,
      price_label,
      buyable: shop_item.buyable,
    }
    items.push(buyitem)
  }
  { items, offset: 0, last_slot: items.length() }
}

///|
pub fn buy(self : BuyState, i : Int) -> Unit {
  if i < 0 || i >= self.last_slot {
    return
  }
  let item = self.items[i]
  let buyable = item.buyable
  let slot = i
  let itemid = item.id
  if buyable > 0 {
    // TODO: support buying multiple items
    new_npc_shop_item_action_packet(slot, itemid, 1, true).dispatch()
  }
}

///|
struct BuyItem {
  display : @utils.Future[(@graphics.Texture, @graphics.Text)?]
  currency : @graphics.Texture
  id : Int
  buyable : Int
  price_label : @graphics.Text
}

///|
struct SellState {
  mut offset : Int
  mut tab : @inventory.TypeId
}

///|
fn SellState::new() -> SellState {
  { offset: 0, tab: @inventory.TypeId::EQUIP }
}

///|
fn sell(items : Array[SellItem], i : Int, all~ : Bool = false) -> Unit {
  guard let Some(item) = items.get(i) else { None => return }
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

///|
pub fn update(self : UIShop) -> Unit {
  let render_state = self.use_runtime_state()
  for _, sprite in render_state.sprites {
    sprite.update() |> ignore
  }
  for _, button in render_state.buttons {
    button.object.update() |> ignore
  }
}

///|
struct SellItem {
  id : Int
  slot : Int
  sellable : Int
  show_count : Bool
  display : @utils.Future[(@graphics.Texture, @graphics.Text, @graphics.Text)?]
}

///|
pub fn SellItem::new(
  item_id : Int,
  count : Int,
  s : Int,
  sc : Bool
) -> SellItem {
  let id = item_id
  let sellable = count
  let slot = s
  let show_count = sc
  let idata = @item.ItemData::get_async(item_id) // TODO: handle error
  let display = idata
    .map_exn(fn(idata) {
      let idata = idata.unwrap_or_error!()
      let icon = idata.get_icon(false)
      let name = @utils.ellipsis(idata.name, 30)
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
      (icon, name_label, price_label)
    })
    .map(fn(r) {
      match r {
        Ok(r) => Some(r)
        Err(err) => {
          @log.error(
            { "err": Show::to_string(err), "item_id": item_id },
            "Failed to get item data",
          )
          None
        }
      }
    })
  { id, slot, sellable, show_count, display }
}

///|
pub fn get_ui_model(self : UIShop) -> @ui.UIModel {
  self.logic_state.model
}

///|
pub fn send_cursor(
  self : UIShop,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  let render_state = self.use_runtime_state()
  @ui.send_cursor_to_btns(
    render_state.buttons.iter(),
    render_state.position,
    pressed,
    cursorpos,
  )
}

///|
fn exit_shop(self : LogicState) -> Unit {
  self.model.deactivate()
  new_npc_shop_leave_action_packet().dispatch()
}

///|
pub fn send_key(self : UIShop, _key : Int, pressed : Bool, esc : Bool) -> Unit {
  if pressed && esc {
    self.logic_state.exit_shop()
  }
}

///|
impl @ui.UIElement for UIShop with remove_cursor(self) -> Unit {  }

///|
impl @ui.UIElement for UIShop with render(self) -> @ui.RenderSpec {
  let rs = self.logic_state.render(self.resources, self.hooks.on_state_changed)
  { render_units: rs.buttons.map(fn(btn) { btn as &@ui.RenderUnit }) }
}

///|
let mode_BUY : Byte = b'\x00'

///|
let mode_SELL : Byte = b'\x01'

///|
let mode_RECHARGE : Byte = b'\x02'

///|
let mode_LEAVE : Byte = b'\x03'

// Requests that an item should be bought from or sold to a NPC shop
///|
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

///| Requests that an item should be recharged at a NPC shop
fn new_npc_shop_recharge_action_packet(slot : Int) -> @net.OutPacket {
  new_npc_shop_action_packet(mode_RECHARGE)..write_short(slot)
}

///| Requests exiting from a NPC shop
fn new_npc_shop_leave_action_packet() -> @net.OutPacket {
  new_npc_shop_action_packet(mode_LEAVE)
}

///|
fn new_npc_shop_action_packet(mode : Byte) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NPC_SHOP_ACTION)..write_byte(mode)
}
