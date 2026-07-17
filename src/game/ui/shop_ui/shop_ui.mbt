///|
using @server_proto {
  type ChangeStatsMesoMessage,
  type ConfirmShopTransactionMessage,
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
  type ModifyInventoryMessage,
  type ModifyInventoryMode,
  type ModifyInventoryMod,
  type NpcShopActionMessage,
  type OpenNpcShopMessage,
  type SetFieldMessage,
}

///|
priv struct DisplayInventoryItem {
  tab : InventoryType
  slot : Int
  item_id : Int
  count : Int
}

///|
priv struct State {
  mut visible : Bool
  mut pending_open_shop : OpenNpcShopMessage?
  mut pending_open_shop_item_ids : Array[Int]
  mut panel_x : Int
  mut panel_y : Int
  mut sell_tab_index : Int
  mut buy_offset : Int
  mut sell_offset : Int
  mut open_shop : OpenNpcShopMessage?
  mut selected_buy_slot : Int?
  mut selected_sell_slot : Int?
  mut meso : Int
  mut ui_resources : UiResources?
  mut ui_loading : @utils.Future[Result[UiResources, Error]]?
  mut items_by_tab : Map[InventoryType, Array[DisplayInventoryItem]]
  icon_by_item_id : Map[Int, @res.NxTexture]
  item_name_by_id : Map[Int, String]
  render_entities : Array[@entity.Entity]
}

///|
priv struct UiResources {
  backgrnd : @res.NxTexture
  backgrnd2 : @res.NxTexture
  backgrnd3 : @res.NxTexture
  backgrnd4 : @res.NxTexture
  select_buy : @res.NxTexture
  select_sell : @res.NxTexture
  meso_icon : @res.NxTexture
  buy_tab_enabled : @res.NxTexture
  sell_tab_resources : Array[(@res.NxTexture, @res.NxTexture)]
  sell_tab_hitboxes : Array[TabHitbox]
  buy_button_normal : @res.NxTexture
  sell_button_normal : @res.NxTexture
  exit_button_normal : @res.NxTexture
  checkbox_off : @res.NxTexture
}

///|
priv struct TabHitbox {
  tab_index : Int
  left : Int
  top : Int
  width : Int
  height : Int
}

///|
let tabs : ReadOnlyArray[InventoryType] = [
  InventoryType::EQUIP,
  InventoryType::USE,
  InventoryType::ETC,
  InventoryType::SETUP,
  InventoryType::CASH,
]

///|
const PANEL_X : Int = 146

///|
const PANEL_Y : Int = 48

///|
const ROW_HEIGHT : Int = 42

///|
const ROW_VISIBLE_COUNT : Int = 9

///|
const BUY_LIST_X : Int = 8

///|
const BUY_LIST_WIDTH : Int = 257

///|
const SELL_LIST_X : Int = 284

///|
const SELL_LIST_WIDTH : Int = 200

///|
const LIST_Y : Int = 116

///|
const UI_BASE_Z : Int = @graphics.MODAL_UI_ZINDEX

///|
const SHOP_TEXT_COLOR : String = "#2f2f2f"

///|
const BUY_SELECTION_X_OFFSET : Int = 47

///|
const SELL_SELECTION_X_OFFSET : Int = 321

///|
const SELECTION_Y_OFFSET : Int = 124

///|
let state_ref : Ref[State] = Ref({
  visible: false,
  pending_open_shop: None,
  pending_open_shop_item_ids: [],
  panel_x: PANEL_X,
  panel_y: PANEL_Y,
  sell_tab_index: 0,
  buy_offset: 0,
  sell_offset: 0,
  open_shop: None,
  selected_buy_slot: None,
  selected_sell_slot: None,
  meso: 0,
  ui_resources: None,
  ui_loading: None,
  items_by_tab: new_items_map(),
  icon_by_item_id: Map([]),
  item_name_by_id: Map([]),
  render_entities: [],
})

///|
let scene_cleanup_registered : Ref[Bool] = Ref(false)

///|
let ui_resources_cache_ref : Ref[UiResources?] = Ref(None)

///|
fn new_items_map() -> Map[InventoryType, Array[DisplayInventoryItem]] {
  let map = Map([])
  for tab in tabs {
    map.set(tab, [])
  }
  map
}

///|
fn clear_entities(entities : Array[@entity.Entity]) -> Unit {
  for entity in entities {
    @sprite.sprites().remove(entity) |> ignore
    @transform2d.remove(entity) |> ignore
    entity.destroy()
  }
  entities.clear()
}

///|
fn spawn_ui_sprite(
  entities : Array[@entity.Entity],
  sprite : @sprite.Sprite,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  let entity = @entity.Entity()
  entities.push(entity)
  @sprite.sprites().set(entity, sprite)
  let world_position = @camera.viewport_to_world(
    @selene_math.Vec2(x.to_double(), y.to_double()),
  )
  @transform.transforms().set(
    entity,
    @transform.Transform::from_xyz(
      world_position[@selene_math.X],
      world_position[@selene_math.Y],
      z.to_double(),
    ),
  )
  match @camera.camera_entity() {
    Some(camera_entity) => @transform.set_parent_in_place(entity, camera_entity)
    None => ()
  }
}

///|
fn make_text_sprite(
  entities : Array[@entity.Entity],
  text : String,
  x : Int,
  y : Int,
  z : Int,
  align? : @selene_math.HAlign = @selene_math.Left,
) -> Unit {
  let entity = @entity.Entity()
  entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(240.0, 18.0),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex(z))
  @selene_ui.texts().set(entity, @selene_ui.Text(text))
  @selene_ui.text_fonts().set(entity, @game_ui_font.text_font(size=11.0))
  @selene_ui.text_colors().set(
    entity,
    @selene_ui.TextColor::from_css(SHOP_TEXT_COLOR),
  )
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout(align~, baseline=@selene_math.Top),
  )
}

///|
priv struct NxShop {
  backgrnd : @res.NxTexture
  backgrnd2 : @res.NxTexture
  backgrnd3 : @res.NxTexture
  backgrnd4 : @res.NxTexture
  select : @res.NxTexture
  select2 : @res.NxTexture
  meso : @res.NxTexture
  tab_buy : NxShopTabGroup
  tab_sell : NxShopTabGroup
  bt_buy : NxShopButton
  bt_sell : NxShopButton
  bt_exit : NxShopButton
  check_box : NxShopCheckBox
} derive (
  @json.FromJson(
    fields(
      tab_buy(rename="TabBuy"),
      tab_sell(rename="TabSell"),
      bt_buy(rename="BtBuy"),
      bt_sell(rename="BtSell"),
      bt_exit(rename="BtExit"),
      check_box(rename="checkBox"),
    ),
  ),
)

///|
priv struct NxShopTabGroup {
  enabled : Array[@res.NxTexture]
  disabled : Array[@res.NxTexture]
}

///|
priv struct NxShopButton {
  normal : @res.NxTexture
}

///|
priv struct NxShopCheckBox {
  off : @res.NxTexture
}

///|
fn parse_texture_array(
  json : Json,
  path : @json.JsonPath,
) -> Array[@res.NxTexture] raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object for texture array"))
  }
  let kvs : Array[(Int, @res.NxTexture)] = []
  for key, value in obj {
    let index = @string.parse_int(key) catch {
      _ =>
        raise @json.JsonDecodeError((path.add_key(key), "tab key is not int"))
    }
    let texture : @res.NxTexture = @json.from_json(
      value,
      path=path.add_key(key),
    )
    kvs.push((index, texture))
  }
  kvs.sort_by(fn(lhs, rhs) {
    let left = lhs.0
    let right = rhs.0
    if left < right {
      -1
    } else if left > right {
      1
    } else {
      0
    }
  })
  let textures : Array[@res.NxTexture] = []
  for kv in kvs {
    textures.push(kv.1)
  }
  textures
}

///|
impl @json.FromJson for NxShopTabGroup with fn from_json(json, path) {
  match json {
    { "enabled": enabled_json, "disabled": disabled_json, .. } => {
      let enabled = parse_texture_array(enabled_json, path.add_key("enabled"))
      let disabled = parse_texture_array(
        disabled_json,
        path.add_key("disabled"),
      )
      { enabled, disabled }
    }
    _ => raise @json.JsonDecodeError((path, "invalid Shop2 tab group"))
  }
}

///|
impl @json.FromJson for NxShopButton with fn from_json(json, path) {
  match json {
    { "normal": { "0": normal_json, .. }, .. } => {
      let normal : @res.NxTexture = @json.from_json(
        normal_json,
        path=path.add_key("normal").add_key("0"),
      )
      { normal, }
    }
    _ => raise @json.JsonDecodeError((path, "invalid Shop2 button"))
  }
}

///|
impl @json.FromJson for NxShopCheckBox with fn from_json(json, path) {
  match json {
    { "0": off_json, .. } => {
      let off : @res.NxTexture = @json.from_json(
        off_json,
        path=path.add_key("0"),
      )
      { off, }
    }
    _ => raise @json.JsonDecodeError((path, "invalid Shop2 checkbox"))
  }
}

///|
fn load_ui_resources() -> UiResources {
  let shop2 = @res.require_json("res://UI/UIWindow2.img/Shop2/nx.json")
  parse_ui_resources_from_shop2_json(shop2) catch {
    _ => abort("invalid Shop2 ui resource")
  }
}

///|
fn parse_ui_resources_from_shop2_json(shop2_json : Json) -> UiResources raise {
  let nx_shop : NxShop = @json.from_json(shop2_json)
  let sell_tab_resources : Array[(@res.NxTexture, @res.NxTexture)] = []
  let sell_tab_hitboxes : Array[TabHitbox] = []
  for i in 0..<tabs.length() {
    let key = i.to_string()
    guard i < nx_shop.tab_sell.disabled.length() else {
      fail("missing Shop2.TabSell.disabled.\{key}")
    }
    guard i < nx_shop.tab_sell.enabled.length() else {
      fail("missing Shop2.TabSell.enabled.\{key}")
    }
    let disabled_texture = nx_shop.tab_sell.disabled[i]
    let enabled_texture = nx_shop.tab_sell.enabled[i]
    sell_tab_resources.push((disabled_texture, enabled_texture))
    sell_tab_hitboxes.push({
      tab_index: i,
      left: PANEL_X - disabled_texture.origin.x,
      top: PANEL_Y - disabled_texture.origin.y,
      width: disabled_texture.w,
      height: disabled_texture.h,
    })
  }
  guard nx_shop.tab_buy.enabled.length() > 0 else {
    fail("missing Shop2.TabBuy.enabled.0")
  }
  let tab_buy_enabled = nx_shop.tab_buy.enabled[0]
  {
    backgrnd: nx_shop.backgrnd,
    backgrnd2: nx_shop.backgrnd2,
    backgrnd3: nx_shop.backgrnd3,
    backgrnd4: nx_shop.backgrnd4,
    select_buy: nx_shop.select,
    select_sell: nx_shop.select2,
    meso_icon: nx_shop.meso,
    buy_tab_enabled: tab_buy_enabled,
    sell_tab_resources,
    sell_tab_hitboxes,
    buy_button_normal: nx_shop.bt_buy.normal,
    sell_button_normal: nx_shop.bt_sell.normal,
    exit_button_normal: nx_shop.bt_exit.normal,
    checkbox_off: nx_shop.check_box.off,
  }
}

///|
fn ensure_item_visual(state : State, item_id : Int) -> Unit {
  guard @item.request_item_data_if_ready(item_id) is Some(item_data) else {
    return
  }
  if !state.icon_by_item_id.contains(item_id) {
    state.icon_by_item_id.set(item_id, item_data.get_icon(false))
  }
  if !state.item_name_by_id.contains(item_id) {
    state.item_name_by_id.set(item_id, item_data.name)
  }
}

///|
fn ensure_item_visual_loaded(state : State, item_id : Int) -> Unit {
  let item_data = @item.request_item_data(item_id)
  if !state.icon_by_item_id.contains(item_id) {
    state.icon_by_item_id.set(item_id, item_data.get_icon(false))
  }
  if !state.item_name_by_id.contains(item_id) {
    state.item_name_by_id.set(item_id, item_data.name)
  }
}

///|
fn collect_unique_shop_item_ids(shop : OpenNpcShopMessage) -> Array[Int] {
  let unique : Map[Int, Bool] = Map([])
  let ids : Array[Int] = []
  for item in shop.items {
    if unique.contains(item.id) {
      continue
    }
    unique.set(item.id, true)
    ids.push(item.id)
  }
  ids
}

///|
fn open_shop_ready(state : State, shop : OpenNpcShopMessage) -> Unit {
  state.pending_open_shop = None
  state.pending_open_shop_item_ids = []
  state.open_shop = Some(shop)
  state.visible = true
  @mini_map_ui.set_modal_suppressed("shop", true)
  state.buy_offset = 0
  state.sell_offset = 0
  state.selected_buy_slot = None
  state.selected_sell_slot = None
  for item in shop.items {
    ensure_item_visual_loaded(state, item.id)
  }
}

///|
fn begin_open_shop(state : State, shop : OpenNpcShopMessage) -> Unit {
  let ids = collect_unique_shop_item_ids(shop)
  @item.get_item_data_system().request_many(ids)
  state.pending_open_shop = Some(shop)
  state.pending_open_shop_item_ids = ids
  state.open_shop = None
  state.visible = false
  state.selected_buy_slot = None
  state.selected_sell_slot = None
}

///|
fn poll_open_shop_preload(state : State) -> Bool {
  guard state.pending_open_shop is Some(shop) else { return false }
  if !@item.get_item_data_system().all_requested_ready_or_fail(
      state.pending_open_shop_item_ids,
    ) {
    return false
  }
  open_shop_ready(state, shop)
  true
}

///|
fn display_item_from_entry(item : InventoryItemEntry) -> DisplayInventoryItem? {
  match item {
    InventoryItemEntry::Equip(invtype~, slot~, id~, ..) =>
      if slot <= 0 {
        None
      } else {
        Some({ tab: invtype, slot, item_id: id, count: 1 })
      }
    InventoryItemEntry::Item(invtype~, slot~, id~, count~, ..) =>
      if slot <= 0 || count <= 0 {
        None
      } else {
        Some({ tab: invtype, slot, item_id: id, count })
      }
    InventoryItemEntry::Pet(invtype~, slot~, id~, ..) =>
      if slot <= 0 {
        None
      } else {
        Some({ tab: invtype, slot, item_id: id, count: 1 })
      }
  }
}

///|
fn slot_sort(lhs : DisplayInventoryItem, rhs : DisplayInventoryItem) -> Int {
  if lhs.slot < rhs.slot {
    -1
  } else if lhs.slot > rhs.slot {
    1
  } else {
    0
  }
}

///|
fn refresh_inventory_from_entry(state : State, entry : InventoryEntry) -> Unit {
  state.items_by_tab = new_items_map()
  state.meso = entry.meso
  for raw_item in entry.items {
    guard display_item_from_entry(raw_item) is Some(item) else { continue }
    let tab_items = state.items_by_tab.get(item.tab).unwrap_or([])
    tab_items.push(item)
    tab_items.sort_by(slot_sort)
    state.items_by_tab.set(item.tab, tab_items)
    ensure_item_visual(state, item.item_id)
  }
}

///|
fn apply_modify_inventory_message(
  state : State,
  item : InventoryItemEntry,
) -> Unit {
  let invtype = match item {
    InventoryItemEntry::Equip(invtype~, ..) => invtype
    InventoryItemEntry::Item(invtype~, ..) => invtype
    InventoryItemEntry::Pet(invtype~, ..) => invtype
  }
  let slot = match item {
    InventoryItemEntry::Equip(slot~, ..) => slot
    InventoryItemEntry::Item(slot~, ..) => slot
    InventoryItemEntry::Pet(slot~, ..) => slot
  }
  let tab_items = state.items_by_tab.get(invtype).unwrap_or([])
  guard display_item_from_entry(item) is Some(display_item) else {
    tab_items.retain(fn(it) { it.slot != slot })
    state.items_by_tab.set(invtype, tab_items)
    return
  }
  let mut replaced = false
  for i in 0..<tab_items.length() {
    if tab_items[i].slot == display_item.slot {
      tab_items[i] = display_item
      replaced = true
      break
    }
  }
  if !replaced {
    tab_items.push(display_item)
  }
  tab_items.sort_by(slot_sort)
  state.items_by_tab.set(invtype, tab_items)
  ensure_item_visual(state, display_item.item_id)
}

///|
fn apply_modify_inventory_batch_message(
  state : State,
  message : ModifyInventoryMessage,
) -> Unit {
  for mod in message.mods {
    apply_modify_inventory_mod(state, mod, message.movement)
  }
}

///|
fn apply_modify_inventory_mod(
  state : State,
  mod : ModifyInventoryMod,
  movement : Int?,
) -> Unit {
  match mod.mode {
    ModifyInventoryMode::ADD =>
      match mod.item {
        Some(item) => apply_modify_inventory_message(state, item)
        None => ()
      }
    ModifyInventoryMode::CHANGE_COUNT | ModifyInventoryMode::ADD_COUNT => {
      let tab_items = state.items_by_tab.get(mod.t).unwrap_or([])
      let new_count = mod.arg
      if new_count <= 0 {
        tab_items.retain(fn(it) { it.slot != mod.pos })
      } else {
        for i in 0..<tab_items.length() {
          if tab_items[i].slot == mod.pos {
            tab_items[i] = { ..tab_items[i], count: new_count }
            break
          }
        }
      }
      tab_items.sort_by(slot_sort)
      state.items_by_tab.set(mod.t, tab_items)
    }
    ModifyInventoryMode::REMOVE => {
      let tab_items = state.items_by_tab.get(mod.t).unwrap_or([])
      tab_items.retain(fn(it) { it.slot != mod.pos })
      state.items_by_tab.set(mod.t, tab_items)
    }
    ModifyInventoryMode::SWAP => apply_modify_swap(state, mod, movement)
  }
}

///|
fn apply_modify_swap(
  state : State,
  mod : ModifyInventoryMod,
  movement : Int?,
) -> Unit {
  let (from_tab, from_slot, to_tab, to_slot) = match movement {
    Some(2) =>
      (InventoryType::EQUIP, mod.pos, InventoryType::EQUIPPED, mod.arg.abs())
    Some(1) =>
      (InventoryType::EQUIPPED, mod.pos.abs(), InventoryType::EQUIP, mod.arg)
    _ => {
      let from_tab = if mod.pos < 0 { InventoryType::EQUIPPED } else { mod.t }
      let to_tab = if mod.arg < 0 { InventoryType::EQUIPPED } else { mod.t }
      (from_tab, mod.pos.abs(), to_tab, mod.arg.abs())
    }
  }
  let from_items = state.items_by_tab.get(from_tab).unwrap_or([])
  let to_items = state.items_by_tab.get(to_tab).unwrap_or([])
  let from_idx = find_slot_index(from_items, from_slot)
  let to_idx = find_slot_index(to_items, to_slot)
  match (from_idx, to_idx) {
    (Some(fi), Some(ti)) => {
      let from_item = from_items[fi]
      let to_item = to_items[ti]
      from_items[fi] = { ..to_item, slot: from_slot, tab: from_tab }
      to_items[ti] = { ..from_item, slot: to_slot, tab: to_tab }
    }
    (Some(fi), None) => {
      let from_item = from_items[fi]
      ignore(from_items.remove(fi))
      if to_tab != InventoryType::EQUIPPED {
        to_items.push({ ..from_item, slot: to_slot, tab: to_tab })
      }
    }
    (None, Some(ti)) => {
      let to_item = to_items[ti]
      ignore(to_items.remove(ti))
      if from_tab != InventoryType::EQUIPPED {
        from_items.push({ ..to_item, slot: from_slot, tab: from_tab })
      }
    }
    (None, None) => ()
  }
  from_items.sort_by(slot_sort)
  to_items.sort_by(slot_sort)
  state.items_by_tab.set(from_tab, from_items)
  state.items_by_tab.set(to_tab, to_items)
}

///|
fn find_slot_index(items : Array[DisplayInventoryItem], slot : Int) -> Int? {
  for i in 0..<items.length() {
    if items[i].slot == slot {
      return Some(i)
    }
  }
  None
}

///|
fn find_clicked_tab(resources : UiResources, pos : @selene_math.Vec2) -> Int? {
  let x = pos[@selene_math.X]
  let y = pos[@selene_math.Y]
  for hitbox in resources.sell_tab_hitboxes {
    let left = hitbox.left.to_double()
    let top = hitbox.top.to_double()
    let right = (hitbox.left + hitbox.width).to_double()
    let bottom = (hitbox.top + hitbox.height).to_double()
    if x >= left && x < right && y >= top && y < bottom {
      return Some(hitbox.tab_index)
    }
  }
  None
}

///|
fn find_clicked_row(
  state : State,
  pos : @selene_math.Vec2,
  list_x : Int,
  list_width : Int,
) -> Int? {
  let x = pos[@selene_math.X]
  let y = pos[@selene_math.Y]
  let left = (state.panel_x + list_x).to_double()
  let right = (state.panel_x + list_x + list_width).to_double()
  if x < left || x >= right {
    return None
  }
  let top = state.panel_y + LIST_Y
  let index = ((y - top.to_double()) / ROW_HEIGHT.to_double()).to_int()
  if index < 0 || index >= ROW_VISIBLE_COUNT {
    return None
  }
  Some(index)
}

///|
fn render_shop_ui(state : State) -> Unit {
  clear_entities(state.render_entities)
  guard state.visible else { return }
  guard state.ui_resources is Some(resources) else { return }
  let z = UI_BASE_Z
  let px = state.panel_x
  let py = state.panel_y

  spawn_ui_sprite(
    state.render_entities,
    resources.backgrnd.require_sprite(),
    px,
    py,
    z,
  )
  spawn_ui_sprite(
    state.render_entities,
    resources.backgrnd2.require_sprite(),
    px,
    py,
    z + 1,
  )
  spawn_ui_sprite(
    state.render_entities,
    resources.backgrnd3.require_sprite(),
    px,
    py,
    z + 2,
  )
  spawn_ui_sprite(
    state.render_entities,
    resources.backgrnd4.require_sprite(),
    px,
    py,
    z + 3,
  )

  // OpenMapleClient: TabBuy overall button is kept in pressed/enabled state.
  spawn_ui_sprite(
    state.render_entities,
    resources.buy_tab_enabled.require_sprite(),
    px,
    py,
    z + 5,
  )

  for i in 0..<tabs.length() {
    let (disabled_tab, enabled_tab) = resources.sell_tab_resources[i]
    let sprite = if i == state.sell_tab_index {
      enabled_tab
    } else {
      disabled_tab
    }
    spawn_ui_sprite(
      state.render_entities,
      sprite.require_sprite(),
      px,
      py,
      z + 5,
    )
  }

  spawn_ui_sprite(
    state.render_entities,
    resources.buy_button_normal.require_sprite(),
    px,
    py,
    z + 5,
  )
  spawn_ui_sprite(
    state.render_entities,
    resources.sell_button_normal.require_sprite(),
    px,
    py,
    z + 5,
  )
  spawn_ui_sprite(
    state.render_entities,
    resources.exit_button_normal.require_sprite(),
    px,
    py,
    z + 5,
  )
  spawn_ui_sprite(
    state.render_entities,
    resources.checkbox_off.require_sprite(),
    px,
    py,
    z + 5,
  )

  make_text_sprite(
    state.render_entities,
    state.meso.to_string(),
    px + 493,
    py + 51,
    z + 6,
    align=@selene_math.Right,
  )

  match state.open_shop {
    Some(shop) =>
      for i in 0..<ROW_VISIBLE_COUNT {
        let slot = state.buy_offset + i
        if slot >= shop.items.length() {
          break
        }
        let item = shop.items[slot]
        ensure_item_visual_loaded(state, item.id)
        if state.selected_buy_slot == Some(slot) {
          spawn_ui_sprite(
            state.render_entities,
            resources.select_buy.require_sprite(),
            px + BUY_SELECTION_X_OFFSET,
            py + SELECTION_Y_OFFSET + i * ROW_HEIGHT,
            z + 7,
          )
        }
        match state.icon_by_item_id.get(item.id) {
          Some(icon) =>
            spawn_ui_sprite(
              state.render_entities,
              icon.require_sprite(),
              px + 12,
              py + 116 + i * ROW_HEIGHT + 42,
              z + 6,
            )
          None => ()
        }
        let name = state.item_name_by_id
          .get(item.id)
          .unwrap_or(item.id.to_string())
        make_text_sprite(
          state.render_entities,
          name,
          px + 52,
          py + 122 + i * ROW_HEIGHT,
          z + 6,
        )
        spawn_ui_sprite(
          state.render_entities,
          resources.meso_icon.require_sprite(),
          px + 50,
          py + 145 + i * ROW_HEIGHT,
          z + 6,
        )
        make_text_sprite(
          state.render_entities,
          "\{item.price}meso",
          px + 67,
          py + 140 + i * ROW_HEIGHT,
          z + 6,
        )
      }
    None => ()
  }

  let sell_tab = tabs[state.sell_tab_index]
  let current_items = state.items_by_tab.get(sell_tab).unwrap_or([])
  for i in 0..<ROW_VISIBLE_COUNT {
    let slot = state.sell_offset + i
    if slot >= current_items.length() {
      break
    }
    let item = current_items[slot]
    ensure_item_visual(state, item.item_id)
    if state.selected_sell_slot == Some(item.slot) {
      spawn_ui_sprite(
        state.render_entities,
        resources.select_sell.require_sprite(),
        px + SELL_SELECTION_X_OFFSET,
        py + SELECTION_Y_OFFSET + i * ROW_HEIGHT,
        z + 7,
      )
    }
    match state.icon_by_item_id.get(item.item_id) {
      Some(icon) =>
        spawn_ui_sprite(
          state.render_entities,
          icon.require_sprite(),
          px + 286,
          py + 116 + i * ROW_HEIGHT + 42,
          z + 6,
        )
      None => ()
    }
    let name = state.item_name_by_id
      .get(item.item_id)
      .unwrap_or(item.item_id.to_string())
    make_text_sprite(
      state.render_entities,
      name,
      px + 327,
      py + 122 + i * ROW_HEIGHT,
      z + 6,
    )
    make_text_sprite(
      state.render_entities,
      "\{item.count}",
      px + 324,
      py + 144 + i * ROW_HEIGHT,
      z + 6,
      align=@selene_math.Right,
    )
  }
}

///|
fn close_shop(state : State) -> Unit {
  if !state.visible {
    return
  }
  state.visible = false
  @mini_map_ui.set_modal_suppressed("shop", false)
  state.pending_open_shop = None
  state.pending_open_shop_item_ids = []
  state.open_shop = None
  state.selected_buy_slot = None
  state.selected_sell_slot = None
  @game_server.send(
    NpcShopActionMessage::{ mode: 3, slot: 0, item_id: 0, qty: 0 },
    log_level=@log.Level::INFO,
  )
  render_shop_ui(state)
}

///|
fn clear_scene() -> Unit {
  let state = state_ref.val
  @mini_map_ui.set_modal_suppressed("shop", false)
  state.visible = false
  state.pending_open_shop = None
  state.pending_open_shop_item_ids = []
  state.open_shop = None
  state.selected_buy_slot = None
  state.selected_sell_slot = None
  clear_entities(state.render_entities)
}

///|
pub fn clear_for_change_map() -> Unit {
  clear_scene()
}

///|
pub fn clear_for_leave_world() -> Unit {
  clear_scene()
}

///|
pub fn init_shop_ui() -> Unit {
  if scene_cleanup_registered.val {
    return
  }
  scene_cleanup_registered.val = true
  @console.register_state_section("shop", debug_state)
}

///|
/// Return compact, stable NPC shop state for debug tools and blackbox tests.
///
/// # Example
/// ```moonbit nocheck
/// ignore(debug_state())
/// ```
pub fn debug_state() -> Json {
  let state = state_ref.val
  let (npc_id, item_count) = match state.open_shop {
    Some(shop) => (shop.npc_id, shop.items.length())
    None =>
      match state.pending_open_shop {
        Some(shop) => (shop.npc_id, shop.items.length())
        None => (-1, 0)
      }
  }
  {
    "visible": state.visible,
    "pending": state.pending_open_shop is Some(_),
    "open_shop_ready": state.open_shop is Some(_),
    "resources_ready": state.ui_resources is Some(_),
    "npc_id": npc_id,
    "item_count": item_count,
    "pending_item_count": state.pending_open_shop_item_ids.length(),
    "render_entity_count": state.render_entities.length(),
    "selected_buy_slot": state.selected_buy_slot.to_json(),
    "selected_sell_slot": state.selected_sell_slot.to_json(),
  }
}

///|
let game_server_handlers_registered : Ref[Bool] = Ref(false)

///|
/// Register local-server handlers for shop ui.
pub fn setup_game_server_handlers() -> Unit {
  if game_server_handlers_registered.val {
    return
  }
  game_server_handlers_registered.val = true
  @game_server.add_server_message_handler(
    "shop_ui_set_field",
    @server_proto.Opcode::SET_FIELD.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : SetFieldMessage = @json.from_json(json)
      guard msg is SetField(inventory_entry~, ..) else { return }
      let state = state_ref.val
      refresh_inventory_from_entry(state, inventory_entry)
      if state.visible {
        render_shop_ui(state)
      }
    },
  )
  @game_server.add_server_message_handler(
    "shop_ui_open_npc_shop",
    @server_proto.Opcode::OPEN_NPC_SHOP.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : OpenNpcShopMessage = @json.from_json(json)
      let state = state_ref.val
      begin_open_shop(state, msg)
    },
  )
  @game_server.add_server_message_handler(
    "shop_ui_confirm_transaction",
    @server_proto.Opcode::CONFIRM_SHOP_TRANSACTION.int_value(),
    fn(json : Json) -> Unit raise {
      let _msg : ConfirmShopTransactionMessage = @json.from_json(json)
      let state = state_ref.val
      if state.visible {
        render_shop_ui(state)
      }
    },
  )
  @game_server.add_server_message_handler(
    "shop_ui_change_stats_meso",
    @server_proto.Opcode::CHANGE_STATS.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : ChangeStatsMesoMessage = @json.from_json(json)
      let state = state_ref.val
      state.meso = msg.meso
      if state.visible {
        render_shop_ui(state)
      }
    },
  )
  @game_server.add_server_message_handler(
    "shop_ui_modify_inventory",
    @server_proto.Opcode::MODIFY_INVENTORY.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : ModifyInventoryMessage = @json.from_json(json)
      let state = state_ref.val
      apply_modify_inventory_batch_message(state, msg)
      if state.visible {
        render_shop_ui(state)
      }
    },
  )
}

///|
/// Sets panel position for tests.
pub fn set_panel_position_for_test(x : Int, y : Int) -> Unit {
  let state = state_ref.val
  state.panel_x = x
  state.panel_y = y
  if state.visible {
    render_shop_ui(state)
  }
}

///|
/// Sets shop open data for tests.
pub fn set_open_shop_for_test(shop : OpenNpcShopMessage?) -> Unit {
  let state = state_ref.val
  state.pending_open_shop = None
  state.pending_open_shop_item_ids = []
  state.open_shop = shop
  state.visible = shop is Some(_)
  @mini_map_ui.set_modal_suppressed("shop", state.visible)
  state.selected_buy_slot = None
  state.selected_sell_slot = None
  state.buy_offset = 0
  state.sell_offset = 0
  match shop {
    Some(shop) =>
      for item in shop.items {
        ensure_item_visual_loaded(state, item.id)
      }
    None => ()
  }
  render_shop_ui(state)
}

///|
/// Sets inventory snapshot for tests.
pub fn set_inventory_entry_for_test(entry : InventoryEntry) -> Unit {
  let state = state_ref.val
  refresh_inventory_from_entry(state, entry)
  if state.visible {
    render_shop_ui(state)
  }
}

///|
/// Sets visible for tests.
pub fn set_shop_visible_for_test(visible : Bool) -> Unit {
  let state = state_ref.val
  state.visible = visible
  @mini_map_ui.set_modal_suppressed("shop", visible)
  if !visible {
    state.pending_open_shop = None
    state.pending_open_shop_item_ids = []
    clear_entities(state.render_entities)
    return
  }
  render_shop_ui(state)
}

///|
/// Sets active sell tab index for tests.
pub fn set_sell_tab_index_for_test(tab_index : Int) -> Unit {
  let state = state_ref.val
  if tab_index < 0 || tab_index >= tabs.length() {
    return
  }
  state.sell_tab_index = tab_index
  state.selected_sell_slot = None
  if state.visible {
    render_shop_ui(state)
  }
}

///|
/// Sets `UIWindow2.img/Shop2/nx.json` resources directly for tests.
pub fn set_shop2_json_for_test(shop2_json : Json) -> Unit raise {
  let state = state_ref.val
  state.ui_loading = None
  let resources = parse_ui_resources_from_shop2_json(shop2_json)
  state.ui_resources = Some(resources)
  ui_resources_cache_ref.val = Some(resources)
  if state.visible {
    render_shop_ui(state)
  }
}

///|
fn poll_ui_resources(state : State) -> Bool {
  guard state.ui_resources is None else { return false }
  if ui_resources_cache_ref.val is Some(cached) {
    state.ui_resources = Some(cached)
    return true
  }
  match state.ui_loading {
    Some(future) =>
      match future.poll() {
        Some(Ok(resources)) => {
          state.ui_loading = None
          state.ui_resources = Some(resources)
          ui_resources_cache_ref.val = Some(resources)
          true
        }
        Some(Err(err)) =>
          @log.fatal("failed to load shop ui resources", data={
            "error": err.to_string(),
          })
        None => false
      }
    None => {
      state.ui_loading = Some(
        @io_service.submit_background_task(fn() { load_ui_resources() }),
      )
      false
    }
  }
}

///|
/// Sprite-based NPC shop ui system.
pub fn shop_ui_system(_world : @ecs.World) -> Unit {
  let state = state_ref.val
  let mut dirty = false
  if poll_open_shop_preload(state) {
    dirty = true
  }
  if !state.visible {
    if state.render_entities.length() > 0 {
      clear_entities(state.render_entities)
    }
    return
  }

  if poll_ui_resources(state) {
    dirty = true
  }
  guard state.ui_resources is Some(resources) else { return }

  if @inputs.is_just_pressed(@inputs.Escape) {
    close_shop(state)
    return
  }

  if @inputs.is_mouse_just_released(@inputs.MouseButton::Left) {
    let pos = @inputs.mouse.pos
    match find_clicked_tab(resources, pos) {
      Some(tab_index) => {
        if state.sell_tab_index != tab_index {
          state.sell_tab_index = tab_index
          state.selected_sell_slot = None
          dirty = true
        }
        return
      }
      None => ()
    }

    match find_clicked_row(state, pos, BUY_LIST_X, BUY_LIST_WIDTH) {
      Some(index) => {
        match state.open_shop {
          Some(shop) => {
            let slot = state.buy_offset + index
            if slot >= 0 && slot < shop.items.length() {
              let item = shop.items[slot]
              state.selected_buy_slot = Some(slot)
              @game_server.send(
                NpcShopActionMessage::{
                  mode: 0,
                  slot,
                  item_id: item.id,
                  qty: 1,
                },
                log_level=@log.Level::INFO,
              )
              dirty = true
            }
          }
          None => ()
        }
        return
      }
      None => ()
    }

    match find_clicked_row(state, pos, SELL_LIST_X, SELL_LIST_WIDTH) {
      Some(index) => {
        let sell_tab = tabs[state.sell_tab_index]
        let current_items = state.items_by_tab.get(sell_tab).unwrap_or([])
        let slot = state.sell_offset + index
        if slot >= 0 && slot < current_items.length() {
          let item = current_items[slot]
          state.selected_sell_slot = Some(item.slot)
          @game_server.send(
            NpcShopActionMessage::{
              mode: 1,
              slot: item.slot,
              item_id: item.item_id,
              qty: 1,
            },
            log_level=@log.Level::INFO,
          )
          dirty = true
        }
      }
      None => ()
    }
  }

  if dirty || state.render_entities.is_empty() {
    render_shop_ui(state)
  }
}
