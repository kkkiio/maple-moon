///|
using @maple_protocol {
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
}

///|
using @inventory {type Inventory}

///|
priv struct DisplayItem {
  tab : InventoryType
  slot : Int
  item_id : Int
  count : Int
}

///|
priv struct State {
  mut visible : Bool
  mut tab_index : Int
  mut panel_x : Int
  mut panel_y : Int
  mut items_by_tab : Map[InventoryType, Array[DisplayItem]]
  mut meso : Int
  mut slot_max_by_tab : Map[InventoryType, Int]
  mut ui_resources : UiResources?
  mut ui_loading : @utils.Future[Result[UiResources, Error]]?
  icon_by_item_id : Map[Int, @sprite.Animation]
  icon_loading : Map[Int, Bool]
  render_entities : Array[@entity.Entity]
  mut binding_version : Int
}

///|
priv struct UiResources {
  full_backgrnd : @sprite.Picture
  full_backgrnd2 : @sprite.Picture
  full_backgrnd3 : @sprite.Picture
  tab_btn_resources : Array[(@sprite.Animation, @sprite.Animation)]
  tab_hitboxes : Array[TabHitbox]
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
let tabs : Array[InventoryType] = [
  InventoryType::EQUIP,
  InventoryType::USE,
  InventoryType::SETUP,
  InventoryType::ETC,
]

///|
let state_ref : Ref[State] = Ref::new({
  visible: false,
  tab_index: 0,
  panel_x: PANEL_X,
  panel_y: PANEL_Y,
  items_by_tab: new_items_map(),
  meso: 0,
  slot_max_by_tab: new_slot_max_map(),
  ui_resources: None,
  ui_loading: None,
  icon_by_item_id: Map::new(),
  icon_loading: Map::new(),
  render_entities: [],
  binding_version: 0,
})

///|
let scene_cleanup_registered : Ref[Bool] = Ref::new(false)

///|
const PANEL_X : Int = 536

///|
const PANEL_Y : Int = 24

///|
const SLOT_COLUMNS : Int = 4

///|
const SLOT_WIDTH : Int = 36

///|
const SLOT_HEIGHT : Int = 35

///|
const SLOT_START_X_OFFSET : Int = 10

///|
const SLOT_START_Y_OFFSET : Int = 51

///|
const MAX_VISIBLE_SLOTS : Int = 32

///|
const UI_BASE_Z : Int = @graphics.UI_ZINDEX

///|
const INVENTORY_ICON_BASELINE_Y : Int = 32

///|
/// Full inventory meso label anchor (OpenMaple full mode: 127,262 + 3,70).
const MESO_LABEL_X_OFFSET : Int = 130

///|
/// Full inventory meso label anchor (OpenMaple full mode: 127,262 + 3,70).
const MESO_LABEL_Y_OFFSET : Int = 338

///|
const COUNT_TEXT_BOTTOM_PADDING : Int = 2

///|
const COUNT_TEXT_HEIGHT_PX : Int = 11

///|
fn new_items_map() -> Map[InventoryType, Array[DisplayItem]] {
  let map = Map::new()
  for tab in tabs {
    map.set(tab, [])
  }
  map
}

///|
fn new_slot_max_map() -> Map[InventoryType, Int] {
  let map = Map::new()
  map.set(InventoryType::EQUIP, 96)
  map.set(InventoryType::USE, 96)
  map.set(InventoryType::SETUP, 96)
  map.set(InventoryType::ETC, 96)
  map
}

///|
fn clear_entities(entities : Array[@entity.Entity]) -> Unit {
  for entity in entities {
    @sprite.sprites.remove(entity) |> ignore
    @position.positions.remove(entity) |> ignore
    @selene_ui.uis.remove(entity) |> ignore
    entity.destroy()
  }
  entities.clear()
}

///|
async fn load_ui_resources() -> UiResources {
  let item = @ui.ui_window_2_loader().load_res_async(["Item"]).value()
  parse_ui_resources_from_item_json(item)
}

///|
fn parse_ui_resources_from_item_json(item_json : Json) -> UiResources raise {
  match item_json {
    {
      "FullBackgrnd": full_backgrnd_json,
      "FullBackgrnd2": full_backgrnd2_json,
      "FullBackgrnd3": full_backgrnd3_json,
      "Tab": {
        "enabled": Object(enabled_tabs),
        "disabled": Object(disabled_tabs),
        ..
      },
      ..
    } => {
      let full_backgrnd : @resource.NxTexture = @json.from_json(
        full_backgrnd_json,
      )
      let full_backgrnd2 : @resource.NxTexture = @json.from_json(
        full_backgrnd2_json,
      )
      let full_backgrnd3 : @resource.NxTexture = @json.from_json(
        full_backgrnd3_json,
      )
      let tab_btn_resources = []
      let tab_hitboxes = []
      for i in 0..<tabs.length() {
        let key = i.to_string()
        guard disabled_tabs.get(key) is Some(disabled_tab_json) else {
          fail("missing Tab.disabled.\{key}")
        }
        guard enabled_tabs.get(key) is Some(enabled_tab_json) else {
          fail("missing Tab.enabled.\{key}")
        }
        let disabled_tab : @resource.NxTexture = @json.from_json(
          disabled_tab_json,
        )
        let enabled_tab : @resource.NxTexture = @json.from_json(
          enabled_tab_json,
        )
        tab_btn_resources.push(
          (
            nx_texture_to_static_animation(disabled_tab),
            nx_texture_to_static_animation(enabled_tab),
          ),
        )
        tab_hitboxes.push({
          tab_index: i,
          left: PANEL_X - disabled_tab.origin.x,
          top: PANEL_Y - disabled_tab.origin.y,
          width: disabled_tab.w,
          height: disabled_tab.h,
        })
      }
      {
        full_backgrnd: @resource.nx_texture_to_selene_picture(full_backgrnd),
        full_backgrnd2: @resource.nx_texture_to_selene_picture(full_backgrnd2),
        full_backgrnd3: @resource.nx_texture_to_selene_picture(full_backgrnd3),
        tab_btn_resources,
        tab_hitboxes,
      }
    }
    _ => fail("invalid UIWindow2 Item.json")
  }
}

///|
fn nx_texture_to_static_animation(
  texture : @resource.NxTexture,
) -> @sprite.Animation {
  @sprite.Animation::single_frame(
    texture.i,
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    offset=@selene_math.Vec2D(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    pivot=@selene_math.Vec2D(
      texture.origin.x.to_double(),
      texture.origin.y.to_double(),
    ),
  )
}

///|
fn spawn_ui_sprite(
  entities : Array[@entity.Entity],
  sprite : @sprite.Sprite,
  x : Int,
  y : Int,
) -> Unit {
  let entity = @entity.Entity::new()
  entities.push(entity)
  @sprite.sprites.set(entity, sprite)
  @position.positions.set(
    entity,
    @position.Position(@selene_math.Vec2D(x.to_double(), y.to_double())),
  )
  @selene_ui.uis.set(entity, @selene_ui.Ui::new())
}

///|
fn display_item_from_entry(item : InventoryItemEntry) -> DisplayItem? {
  match item {
    InventoryItemEntry::Equip(invtype~, slot~, id~, ..) =>
      if slot <= 0 {
        None
      } else {
        Some({ tab: invtype, slot, item_id: id, count: 1 })
      }
    InventoryItemEntry::Item(invtype~, slot~, id~, count~, ..) =>
      if slot <= 0 {
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
fn is_visible_tab(tab : InventoryType) -> Bool {
  tab == InventoryType::EQUIP ||
  tab == InventoryType::USE ||
  tab == InventoryType::SETUP ||
  tab == InventoryType::ETC
}

///|
fn slot_sort(lhs : DisplayItem, rhs : DisplayItem) -> Int {
  if lhs.slot < rhs.slot {
    -1
  } else if lhs.slot > rhs.slot {
    1
  } else {
    0
  }
}

///|
fn prepare_from_entry(state : State, entry : InventoryEntry) -> Unit {
  state.items_by_tab = new_items_map()
  state.meso = entry.meso
  state.slot_max_by_tab = new_slot_max_map()
  state.icon_by_item_id.clear()
  for tab in tabs {
    match entry.slot_maxs.0.get(tab) {
      Some(slot_max) => state.slot_max_by_tab.set(tab, slot_max)
      None => ()
    }
  }

  for entry in entry.items {
    guard display_item_from_entry(entry) is Some(item) else { continue }
    if not(is_visible_tab(item.tab)) {
      continue
    }
    let tab_items = state.items_by_tab.get(item.tab).unwrap_or([])
    tab_items.push(item)
    state.items_by_tab.set(item.tab, tab_items)
    ensure_icon_loading(state, item.item_id)
  }

  for tab in tabs {
    match state.items_by_tab.get(tab) {
      Some(tab_items) => tab_items.sort_by(slot_sort)
      None => ()
    }
  }
}

///|
fn ensure_icon_loading(state : State, item_id : Int) -> Unit {
  if state.icon_by_item_id.contains(item_id) {
    return
  }
  let item_data = @item.request_item_data(item_id)
  let icon = nx_texture_to_inventory_icon_animation(item_data.get_icon(false))
  state.icon_by_item_id.set(item_id, icon)
}

///|
fn refresh_tab_from_inventory(
  state : State,
  inventory : Inventory,
  tab : InventoryType,
) -> Unit {
  let slot_max = inventory.get_slotmax(tab)
  state.slot_max_by_tab.set(tab, slot_max)
  let items : Array[DisplayItem] = []
  if slot_max > 0 {
    for slot in 1..<=slot_max {
      guard inventory.get_slot_item_at(tab, slot) is Some(slot_item) else {
        continue
      }
      let item : DisplayItem = {
        tab,
        slot,
        item_id: slot_item.item_id,
        count: slot_item.count,
      }
      items.push(item)
      ensure_icon_loading(state, slot_item.item_id)
    }
  }
  items.sort_by(slot_sort)
  state.items_by_tab.set(tab, items)
}

///|
fn refresh_from_inventory(state : State, inventory : Inventory) -> Unit {
  state.items_by_tab = new_items_map()
  state.slot_max_by_tab = new_slot_max_map()
  state.meso = inventory.get_meso()
  for tab in tabs {
    refresh_tab_from_inventory(state, inventory, tab)
  }
}

///|
fn poll_icon_loading(state : State) -> Bool {
  ignore(state)
  false
}

///|
fn nx_texture_to_inventory_icon_animation(
  texture : @resource.NxTexture,
) -> @sprite.Animation {
  @sprite.Animation::new(
    [
      @sprite.AnimationFrame::{
        sprite_path: texture.i,
        size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
        offset: @selene_math.Vec2D(
          texture.offset.x.to_double(),
          texture.offset.y.to_double(),
        ),
        pivot: @selene_math.Vec2D(
          texture.origin.x.to_double(),
          texture.origin.y.to_double(),
        ),
        duration: 1.0,
      },
    ],
    loop_=true,
  )
}

///|
fn clear_render(state : State) -> Unit {
  clear_entities(state.render_entities)
}

///|
fn find_clicked_tab(resources : UiResources, pos : @selene_math.Vec2D) -> Int? {
  let x = pos[@selene_math.X]
  let y = pos[@selene_math.Y]
  for hitbox in resources.tab_hitboxes {
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
fn render_inventory(state : State) -> Unit {
  clear_render(state)
  guard state.ui_resources is Some(ui_resources) else { return }

  let panel_x = state.panel_x
  let panel_y = state.panel_y
  let slot_start_x = panel_x + SLOT_START_X_OFFSET
  let slot_start_y = panel_y + SLOT_START_Y_OFFSET

  let z = UI_BASE_Z + 10
  spawn_ui_sprite(
    state.render_entities,
    @sprite.Sprite::from_picture(ui_resources.full_backgrnd, z),
    panel_x,
    panel_y,
  )
  spawn_ui_sprite(
    state.render_entities,
    @sprite.Sprite::from_picture(ui_resources.full_backgrnd2, z + 1),
    panel_x,
    panel_y,
  )
  spawn_ui_sprite(
    state.render_entities,
    @sprite.Sprite::from_picture(ui_resources.full_backgrnd3, z + 2),
    panel_x,
    panel_y,
  )
  let meso_text = @sprite.Text::new(
    state.meso.to_string(),
    color="#0b1f2a",
    font="12px Menlo",
    baseline=@selene_math.Top,
    align=@selene_math.Right,
  )
  spawn_ui_sprite(
    state.render_entities,
    @sprite.Sprite::from_text(meso_text, z + 4),
    panel_x + MESO_LABEL_X_OFFSET,
    panel_y + MESO_LABEL_Y_OFFSET,
  )

  let current_tab = tabs[state.tab_index]

  let current_items = state.items_by_tab.get(current_tab).unwrap_or([])
  let slot_map : Map[Int, DisplayItem] = Map::new()
  for item in current_items {
    slot_map.set(item.slot, item)
  }

  let slot_max = state.slot_max_by_tab.get(current_tab).unwrap_or(0)
  let visible_slots = if slot_max < MAX_VISIBLE_SLOTS {
    slot_max
  } else {
    MAX_VISIBLE_SLOTS
  }

  if visible_slots > 0 {
    for i in 0..<visible_slots {
      let slot_index = i + 1
      let row = i / SLOT_COLUMNS
      let col = i % SLOT_COLUMNS
      let x = slot_start_x + col * SLOT_WIDTH
      let y = slot_start_y + row * SLOT_HEIGHT

      match slot_map.get(slot_index) {
        Some(item) => {
          match state.icon_by_item_id.get(item.item_id) {
            Some(icon) =>
              spawn_ui_sprite(
                state.render_entities,
                @sprite.Sprite::from_animation(icon, z + 3),
                x,
                y + INVENTORY_ICON_BASELINE_Y,
              )
            None => ()
          }
          if item.count > 1 {
            let count_text = @sprite.Text::new(
              item.count.to_string(),
              color="#0b1f2a",
              font="11px Menlo",
              baseline=@selene_math.Top,
              align=@selene_math.Right,
            )
            spawn_ui_sprite(
              state.render_entities,
              @sprite.Sprite::from_text(count_text, z + 3),
              x + SLOT_WIDTH - 2,
              y + SLOT_HEIGHT - COUNT_TEXT_HEIGHT_PX - COUNT_TEXT_BOTTOM_PADDING,
            )
          }
        }
        None => ()
      }
    }
  }

  for i in 0..<tabs.length() {
    let (disabled_tab, enabled_tab) = ui_resources.tab_btn_resources[i]
    let tab_sprite = if i == state.tab_index {
      enabled_tab
    } else {
      disabled_tab
    }
    spawn_ui_sprite(
      state.render_entities,
      @sprite.Sprite::from_animation(tab_sprite, z + 3),
      panel_x,
      panel_y,
    )
  }
}

///|
fn register_scene_cleanup_once() -> Unit {
  if scene_cleanup_registered.val {
    return
  }
  scene_cleanup_registered.val = true
  @game_state.listen_scene_clear(fn(_reason) {
    let state = state_ref.val
    clear_render(state)
    state.visible = false
    state.tab_index = 0
    state.panel_x = PANEL_X
    state.panel_y = PANEL_Y
    state.items_by_tab = new_items_map()
    state.slot_max_by_tab = new_slot_max_map()
    state.ui_resources = None
    state.ui_loading = None
    state.icon_by_item_id.clear()
    state.icon_loading.clear()
    state.binding_version += 1
    true
  })
}

///|
pub fn init_inventory_ui() -> Unit {
  register_scene_cleanup_once()
}

///|
let game_server_handlers_registered : Ref[Bool] = Ref::new(false)

///|
/// Register local-server inventory sync handlers for inventory UI.
pub fn setup_game_server_handlers() -> Unit {
  if game_server_handlers_registered.val {
    return
  }
  game_server_handlers_registered.val = true
  @game_server.add_server_message_handler(
    "inventory_ui_change_stats_meso",
    @net.Opcode::CHANGE_STATS.int_value(),
    fn(json : Json) -> Unit raise {
      let message : @maple_protocol.ChangeStatsMesoMessage = @json.from_json(
        json,
      )
      let state = state_ref.val
      state.meso = message.meso
      if state.visible {
        render_inventory(state)
      }
    },
  )
  @game_server.add_server_message_handler(
    "inventory_ui_modify_inventory",
    @net.Opcode::MODIFY_INVENTORY.int_value(),
    fn(json : Json) -> Unit raise {
      let message : @maple_protocol.ModifyInventoryItemMessage = @json.from_json(
        json,
      )
      apply_modify_inventory_message(state_ref.val, message.item)
    },
  )
}

///|
fn apply_modify_inventory_message(
  state : State,
  item : InventoryItemEntry,
) -> Unit {
  guard display_item_from_entry(item) is Some(display_item) else { return }
  if not(is_visible_tab(display_item.tab)) {
    return
  }
  let tab_items = state.items_by_tab.get(display_item.tab).unwrap_or([])
  let mut replaced = false
  for i in 0..<tab_items.length() {
    if tab_items[i].slot == display_item.slot {
      tab_items[i] = display_item
      replaced = true
      break
    }
  }
  if not(replaced) {
    tab_items.push(display_item)
  }
  tab_items.sort_by(slot_sort)
  state.items_by_tab.set(display_item.tab, tab_items)
  ensure_icon_loading(state, display_item.item_id)
  if state.visible {
    render_inventory(state)
  }
}

///|
/// Bind inventory as UI source and refresh incrementally from inventory events.
pub fn bind_inventory(inventory : Inventory) -> Unit {
  let state = state_ref.val
  state.binding_version += 1
  let current_binding = state.binding_version
  refresh_from_inventory(state, inventory)
  for tab in tabs {
    inventory.listen_item_changes(tab, fn() {
      let state = state_ref.val
      if state.binding_version != current_binding {
        return false
      }
      refresh_tab_from_inventory(state, inventory, tab)
      if state.visible {
        render_inventory(state)
      }
      true
    })
  }
  inventory.listen_meso_changes(fn(meso) {
    let state = state_ref.val
    if state.binding_version != current_binding {
      return false
    }
    state.meso = meso
    if state.visible {
      render_inventory(state)
    }
    true
  })
  if state.visible {
    render_inventory(state)
  }
}

///|
/// Setting the initial inventory snapshot used by the display-only UI.
pub fn set_inventory_entry(entry : InventoryEntry) -> Unit {
  let state = state_ref.val
  prepare_from_entry(state, entry)
  if state.visible {
    render_inventory(state)
  }
}

///|
/// Sets whether the display-only inventory UI should be visible.
pub fn set_inventory_visible(visible : Bool) -> Unit {
  let state = state_ref.val
  if state.visible == visible {
    return
  }
  state.visible = visible
  if not(visible) {
    clear_render(state)
    return
  }
  render_inventory(state)
}

///|
/// Sets `UIWindow2.img/Item.json` resources directly for tests.
pub fn set_item_json_for_test(item_json : Json) -> Unit raise {
  let state = state_ref.val
  state.ui_loading = None
  state.ui_resources = Some(parse_ui_resources_from_item_json(item_json))
  if state.visible {
    render_inventory(state)
  }
}

///|
/// Sets inventory panel position for tests.
pub fn set_panel_position_for_test(x : Int, y : Int) -> Unit {
  let state = state_ref.val
  state.panel_x = x
  state.panel_y = y
  if state.visible {
    render_inventory(state)
  }
}

///|
/// Sets active tab index directly for tests.
pub fn set_tab_index_for_test(tab_index : Int) -> Unit {
  let state = state_ref.val
  if tab_index < 0 || tab_index >= tabs.length() {
    return
  }
  state.tab_index = tab_index
  if state.visible {
    render_inventory(state)
  }
}

///|
fn poll_ui_resources(state : State) -> Bool {
  guard state.ui_resources is None else { return false }
  match state.ui_loading {
    Some(future) =>
      match future.poll() {
        Some(Ok(resources)) => {
          state.ui_loading = None
          state.ui_resources = Some(resources)
          true
        }
        Some(Err(err)) =>
          @log.fatal("failed to load inventory ui resources", data={
            "error": err.to_string(),
          })
        None => false
      }
    None => {
      state.ui_loading = Some(
        @io_service.submit_background_task(async fn() { load_ui_resources() }),
      )
      false
    }
  }
}

///|
/// System for rendering and toggling the display-only inventory UI.
pub fn inventory_ui_system(_delta : Double) -> Unit {
  let state = state_ref.val
  let mut dirty = false

  if @inputs.is_just_pressed(@inputs.KeyI) {
    state.visible = not(state.visible)
    dirty = true
  }

  if state.visible && @inputs.is_mouse_just_released(@inputs.MouseButton::Left) {
    match state.ui_resources {
      Some(resources) =>
        match find_clicked_tab(resources, @inputs.mouse.pos) {
          Some(next_tab) =>
            if state.tab_index != next_tab {
              state.tab_index = next_tab
              dirty = true
            }
          None => ()
        }
      None => ()
    }
  }

  if poll_ui_resources(state) {
    dirty = true
  }

  if poll_icon_loading(state) {
    dirty = true
  }

  if not(state.visible) {
    if state.render_entities.length() > 0 {
      clear_render(state)
    }
    return
  }

  if dirty || state.render_entities.is_empty() {
    render_inventory(state)
  }
}
