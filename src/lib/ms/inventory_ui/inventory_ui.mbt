///|
using @maple_protocol {
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
}

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
  mut slot_max_by_tab : Map[InventoryType, Int]
  mut ui_resources : UiResources?
  mut ui_loading : @utils.Future[Result[UiResources, Error]]?
  icon_by_item_id : Map[Int, @sprite.Picture]
  icon_loading : Map[Int, @utils.Future[Result[@item.ItemData, Error]]]
  render_entities : Array[@entity.Entity]
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
  slot_max_by_tab: new_slot_max_map(),
  ui_resources: None,
  ui_loading: None,
  icon_by_item_id: Map::new(),
  icon_loading: Map::new(),
  render_entities: [],
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
const SLOT_SIZE : Int = 40

///|
const MAX_VISIBLE_SLOTS : Int = 32

///|
const UI_BASE_Z : Int = @graphics.UI_ZINDEX

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
      let full_backgrnd : @resource.NxTexture = @json.from_json(full_backgrnd_json)
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
        let enabled_tab : @resource.NxTexture = @json.from_json(enabled_tab_json)
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
  state.slot_max_by_tab = new_slot_max_map()
  state.icon_by_item_id.clear()
  state.icon_loading.clear()

  for entry in entry.items {
    guard display_item_from_entry(entry) is Some(item) else { continue }
    if not(is_visible_tab(item.tab)) {
      continue
    }
    let tab_items = state.items_by_tab.get(item.tab).unwrap_or([])
    tab_items.push(item)
    state.items_by_tab.set(item.tab, tab_items)
    if not(state.icon_loading.contains(item.item_id)) {
      state.icon_loading.set(
        item.item_id,
        @io_service.submit_background_task(async fn() {
          @item.ItemData::get_async(item.item_id)
        }),
      )
    }
  }

  for tab in tabs {
    match state.items_by_tab.get(tab) {
      Some(tab_items) => tab_items.sort_by(slot_sort)
      None => ()
    }
  }
}

///|
fn poll_icon_loading(state : State) -> Bool {
  let mut changed = false
  let done_ids : Array[Int] = []
  for item_id, future in state.icon_loading {
    match future.poll() {
      Some(Ok(item_data)) => {
        let icon = @resource.nx_texture_to_selene_picture(
          item_data.get_icon(false),
        )
        state.icon_by_item_id.set(item_id, icon)
        done_ids.push(item_id)
        changed = true
      }
      Some(Err(err)) => {
        @log.error("failed to load inventory icon", data={
          "item_id": item_id,
          "error": err.to_string(),
        })
        done_ids.push(item_id)
      }
      None => ()
    }
  }
  for item_id in done_ids {
    state.icon_loading.remove(item_id) |> ignore
  }
  changed
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
  let slot_start_x = panel_x + 12
  let slot_start_y = panel_y + 72

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
      let x = slot_start_x + col * SLOT_SIZE
      let y = slot_start_y + row * SLOT_SIZE

      match slot_map.get(slot_index) {
        Some(item) => {
          match state.icon_by_item_id.get(item.item_id) {
            Some(icon) =>
              spawn_ui_sprite(
                state.render_entities,
                @sprite.Sprite::from_picture(icon, z + 2),
                x + 17,
                y + 17,
              )
            None => ()
          }
          if item.count > 1 {
            let count_text = @sprite.Text::new(
              item.count.to_string(),
              color="#f6fbff",
              font="11px Menlo",
            )
            spawn_ui_sprite(
              state.render_entities,
              @sprite.Sprite::from_text(count_text, z + 3),
              x + 2,
              y + 22,
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
    true
  })
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
  register_scene_cleanup_once()

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
