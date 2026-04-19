///|
using @server_proto {
  type InventoryEntry,
  type InventoryItemEntry,
  type ModifyInventoryMessage,
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
  icon_by_item_id : Map[Int, @resource.NxTexture]
  ui_entities : Array[@entity.Entity]
  tab_buttons : Array[TabButton]
  slot_buttons : Array[SlotButton]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
  mut binding_version : Int
  mut active_slot : Int?
}

///|
priv struct UiResources {
  full_backgrnd : @resource.NxTexture
  full_backgrnd2 : @resource.NxTexture
  full_backgrnd3 : @resource.NxTexture
  tab_btn_resources : Array[(@resource.NxTexture, @resource.NxTexture)]
}

///|
priv struct TabButton {
  tab_index : Int
  entity : @entity.Entity
}

///|
priv struct SlotButton {
  slot_no : Int
  entity : @entity.Entity
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
  ui_entities: [],
  tab_buttons: [],
  slot_buttons: [],
  click_reader: @event.EventReader::new(),
  binding_version: 0,
  active_slot: None,
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
    entity.destroy()
  }
  entities.clear()
}

///|
async fn load_ui_resources() -> UiResources {
  let item = @ui.ui_window_2_loader().load_resource(["Item"])
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
        tab_btn_resources.push((disabled_tab, enabled_tab))
      }
      { full_backgrnd, full_backgrnd2, full_backgrnd3, tab_btn_resources }
    }
    _ => fail("invalid UIWindow2 Item.json")
  }
}

///|
fn ui_image_from_texture(texture : @resource.NxTexture) -> @selene_ui.UiImage {
  let source = ui_image_source_from_texture(texture)
  @selene_ui.UiImage::new(
    @selene_math.Vec2(texture.w.to_double(), texture.h.to_double()),
    texture.i,
    source=Some(source),
  )
}

///|
fn ui_image_source_from_texture(
  texture : @resource.NxTexture,
) -> @render2d_types.ImageRegion2D {
  {
    position: @selene_math.Vec2(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @selene_math.Vec2(texture.w.to_double(), texture.h.to_double()),
  }
}

///|
fn set_image_texture(
  entity : @entity.Entity,
  texture : @resource.NxTexture,
) -> Unit {
  @selene_ui.ui_images().set(entity, ui_image_from_texture(texture))
}

///|
fn spawn_image_node(
  entities : Array[@entity.Entity],
  texture : @resource.NxTexture,
  x : Int,
  y : Int,
  z : Int,
  width? : Int = texture.w,
  height? : Int = texture.h,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(width.to_double(), height.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  set_image_texture(entity, texture)
  entity
}

///|
fn spawn_text_node(
  entities : Array[@entity.Entity],
  text : String,
  x : Int,
  y : Int,
  z : Int,
  width : Int,
  height : Int,
  align? : @selene_math.HAlign = @selene_math.Left,
  font_size? : Double = 11.0,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(width.to_double(), height.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout::new(
      align~,
      baseline=@selene_math.Top,
      wrap=@selene_ui.TextWrap::NoWrap,
      overflow=@selene_ui.TextOverflow::Clip,
    ),
  )
  @selene_ui.texts().set(entity, @selene_ui.Text::new(text))
  @selene_ui.text_colors().set(
    entity,
    @selene_ui.TextColor::from_css("#0b1f2a"),
  )
  @selene_ui.text_fonts().set(
    entity,
    @selene_ui.TextFont::new(family="Menlo", size=font_size),
  )
  entity
}

///|
fn texture_draw_x(panel_x : Int, texture : @resource.NxTexture) -> Int {
  panel_x - texture.origin.x
}

///|
fn texture_draw_y(panel_y : Int, texture : @resource.NxTexture) -> Int {
  panel_y - texture.origin.y
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
    if !is_visible_tab(item.tab) {
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
  let icon = item_data.get_icon(false)
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
fn clear_render(state : State) -> Unit {
  clear_entities(state.ui_entities)
  state.tab_buttons.clear()
  state.slot_buttons.clear()
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
  ignore(
    spawn_image_node(
      state.ui_entities,
      ui_resources.full_backgrnd,
      texture_draw_x(panel_x, ui_resources.full_backgrnd),
      texture_draw_y(panel_y, ui_resources.full_backgrnd),
      z,
    ),
  )
  ignore(
    spawn_image_node(
      state.ui_entities,
      ui_resources.full_backgrnd2,
      texture_draw_x(panel_x, ui_resources.full_backgrnd2),
      texture_draw_y(panel_y, ui_resources.full_backgrnd2),
      z + 1,
    ),
  )
  ignore(
    spawn_image_node(
      state.ui_entities,
      ui_resources.full_backgrnd3,
      texture_draw_x(panel_x, ui_resources.full_backgrnd3),
      texture_draw_y(panel_y, ui_resources.full_backgrnd3),
      z + 2,
    ),
  )
  let meso_anchor_x = panel_x + MESO_LABEL_X_OFFSET
  ignore(
    spawn_text_node(
      state.ui_entities,
      state.meso.to_string(),
      meso_anchor_x - 120,
      panel_y + MESO_LABEL_Y_OFFSET,
      z + 4,
      120,
      16,
      align=@selene_math.Right,
      font_size=12.0,
    ),
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
      let slot_entity = @entity.Entity::new()
      state.ui_entities.push(slot_entity)
      @selene_ui.nodes().set(
        slot_entity,
        @selene_ui.Node::absolute(
          @selene_math.Vec2(x.to_double(), y.to_double()),
          size=@selene_math.Vec2(
            SLOT_WIDTH.to_double(),
            SLOT_HEIGHT.to_double(),
          ),
        ),
      )
      @selene_ui.z_indexes().set(slot_entity, @selene_ui.ZIndex::new(z + 6))
      @selene_ui.buttons().set(slot_entity, @selene_ui.Button::new())
      if state.active_slot == Some(slot_index) {
        @selene_ui.background_colors().set(
          slot_entity,
          @selene_ui.BackgroundColor::from_css("rgba(255, 207, 74, 0.18)"),
        )
        @selene_ui.outlines().set(
          slot_entity,
          @selene_ui.Outline::new(
            @selene_ui.Val::px(2.0),
            @selene_ui.BorderColor::from_css("#ffcf4a").color,
          ),
        )
      }
      state.slot_buttons.push({ slot_no: slot_index, entity: slot_entity })

      match slot_map.get(slot_index) {
        Some(item) => {
          match state.icon_by_item_id.get(item.item_id) {
            Some(icon) =>
              ignore(
                spawn_image_node(
                  state.ui_entities,
                  icon,
                  x - icon.origin.x,
                  y + INVENTORY_ICON_BASELINE_Y - icon.origin.y,
                  z + 3,
                ),
              )
            None => ()
          }
          if item.count > 1 {
            ignore(
              spawn_text_node(
                state.ui_entities,
                item.count.to_string(),
                x + SLOT_WIDTH - 2 - 34,
                y +
                SLOT_HEIGHT -
                COUNT_TEXT_HEIGHT_PX -
                COUNT_TEXT_BOTTOM_PADDING,
                z + 4,
                34,
                COUNT_TEXT_HEIGHT_PX + 2,
                align=@selene_math.Right,
              ),
            )
          }
        }
        None => ()
      }
    }
  }

  for i in 0..<tabs.length() {
    let (disabled_tab, enabled_tab) = ui_resources.tab_btn_resources[i]
    let tab_texture = if i == state.tab_index {
      enabled_tab
    } else {
      disabled_tab
    }
    let tab_entity = spawn_image_node(
      state.ui_entities,
      tab_texture,
      texture_draw_x(panel_x, tab_texture),
      texture_draw_y(panel_y, tab_texture),
      z + 5,
    )
    @selene_ui.buttons().set(tab_entity, @selene_ui.Button::new())
    state.tab_buttons.push({ tab_index: i, entity: tab_entity })
  }
}

///|
fn clear_scene(reason_is_change_map : Bool) -> Unit {
  let state = state_ref.val
  clear_render(state)
  if !reason_is_change_map {
    state.visible = false
    state.tab_index = 0
    state.panel_x = PANEL_X
    state.panel_y = PANEL_Y
    state.items_by_tab = new_items_map()
    state.slot_max_by_tab = new_slot_max_map()
    state.ui_resources = None
    state.ui_loading = None
    state.icon_by_item_id.clear()
    state.binding_version += 1
    state.active_slot = None
  }
}

///|
pub fn clear_for_change_map() -> Unit {
  clear_scene(true)
}

///|
pub fn clear_for_leave_world() -> Unit {
  clear_scene(false)
}

///|
pub fn init_inventory_ui() -> Unit {
  if scene_cleanup_registered.val {
    return
  }
  scene_cleanup_registered.val = true
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
    @server_proto.Opcode::CHANGE_STATS.int_value(),
    fn(json : Json) -> Unit raise {
      let message : @server_proto.ChangeStatsMesoMessage = @json.from_json(json)
      let state = state_ref.val
      state.meso = message.meso
      if state.visible {
        render_inventory(state)
      }
    },
  )
  @game_server.add_server_message_handler(
    "inventory_ui_modify_inventory",
    @server_proto.Opcode::MODIFY_INVENTORY.int_value(),
    fn(json : Json) -> Unit raise {
      let _msg : ModifyInventoryMessage = @json.from_json(json)
    },
  )
}

///|
/// Bind inventory as UI source and refresh incrementally from inventory events.
pub fn bind_inventory(inventory : Inventory) -> Unit {
  let state = state_ref.val
  state.binding_version += 1
  state.active_slot = None
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
  if !visible {
    state.active_slot = None
    clear_render(state)
    return
  }
  state.active_slot = None
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
  state.active_slot = None
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
fn find_clicked_tab_index(state : State, entity : @entity.Entity) -> Int? {
  for button in state.tab_buttons {
    if button.entity == entity {
      return Some(button.tab_index)
    }
  }
  None
}

///|
fn find_clicked_slot(state : State, entity : @entity.Entity) -> Int? {
  for button in state.slot_buttons {
    if button.entity == entity {
      return Some(button.slot_no)
    }
  }
  None
}

///|
fn process_click_events(state : State) -> (Bool, Bool) {
  let mut dirty = false
  let mut clicked_slot_or_tab = false
  let click_events = @selene_ui.click_event_bus.read(state.click_reader)
  for event in click_events {
    guard event.button is @inputs.MouseButton::Left else { continue }
    match find_clicked_tab_index(state, event.entity) {
      Some(next_tab) => {
        clicked_slot_or_tab = true
        if state.tab_index != next_tab {
          state.tab_index = next_tab
          state.active_slot = None
          dirty = true
        }
      }
      None =>
        match find_clicked_slot(state, event.entity) {
          Some(slot_no) => {
            clicked_slot_or_tab = true
            if state.active_slot == Some(slot_no) {
              state.active_slot = None
              let type_id = tabs[state.tab_index]
              @inventory.use_item_at_slot(type_id, slot_no) |> ignore
            } else {
              state.active_slot = Some(slot_no)
            }
            dirty = true
          }
          None =>
            if state.active_slot is Some(_) {
              state.active_slot = None
              dirty = true
            }
        }
    }
  }
  (dirty, clicked_slot_or_tab)
}

///|
/// System for rendering and toggling the display-only inventory UI.
pub fn inventory_ui_system(_world : @ecs.World) -> Unit {
  let state = state_ref.val
  let mut dirty = false

  if @inputs.is_just_pressed(@inputs.KeyI) {
    state.visible = !state.visible
    if !state.visible {
      state.active_slot = None
    }
    dirty = true
  }

  if poll_ui_resources(state) {
    dirty = true
  }

  if poll_icon_loading(state) {
    dirty = true
  }

  if !state.visible {
    if state.ui_entities.length() > 0 {
      clear_render(state)
    }
    return
  }

  if dirty || state.ui_entities.is_empty() {
    render_inventory(state)
  }
  let (click_dirty, clicked_slot_or_tab) = process_click_events(state)
  if click_dirty {
    render_inventory(state)
    return
  }
  if @inputs.is_mouse_just_pressed(@inputs.MouseButton::Left) &&
    state.active_slot is Some(_) &&
    !clicked_slot_or_tab {
    state.active_slot = None
    render_inventory(state)
  }
}
