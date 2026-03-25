///|
priv struct QuestLogButtonResource {
  normal : @resource.NxTexture
  mouse_over : @resource.NxTexture
  pressed : @resource.NxTexture
  disabled : @resource.NxTexture
}

///|
priv struct QuestLogUiResource {
  backgrnd : @resource.NxTexture
  backgrnd2 : @resource.NxTexture
  search_area : @resource.NxTexture
  tab_disabled : Array[@resource.NxTexture]
  tab_enabled : Array[@resource.NxTexture]
  bt_min : QuestLogButtonResource
  bt_search : QuestLogButtonResource
  bt_my_level : QuestLogButtonResource
  bt_all_level : QuestLogButtonResource
  bt_my_location : QuestLogButtonResource
  bt_all_location : QuestLogButtonResource
}

///|
priv struct TabButton {
  tab_index : Int
  entity : @entity.Entity
}

///|
priv struct ActionButton {
  resource : QuestLogButtonResource
  entity : @entity.Entity
  enabled : Bool
  on_click : () -> Unit
}

///|
priv struct QuestLogUiState {
  mut visible : Bool
  mut selected_tab : Int
  panel_x : Int
  panel_y : Int
  mut last_revision : Int
  mut ui_resource : QuestLogUiResource?
  mut ui_loading : @utils.Future[Result[QuestLogUiResource, Error]]?
  render_entities : Array[@entity.Entity]
  tab_buttons : Array[TabButton]
  action_buttons : Array[ActionButton]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
}

///|
let states_by_world_ref : Ref[Map[UInt, QuestLogUiState]] = Ref::new(Map::new())

///|
fn make_initial_state() -> QuestLogUiState {
  {
    visible: false,
    selected_tab: 0,
    panel_x: 300,
    panel_y: 160,
    last_revision: -1,
    ui_resource: None,
    ui_loading: None,
    render_entities: [],
    tab_buttons: [],
    action_buttons: [],
    click_reader: @event.EventReader::new(),
  }
}

///|
fn state() -> QuestLogUiState {
  let world_id = @ecs.require_current_world().id()
  states_by_world_ref.val.get_or_init(world_id, make_initial_state)
}

///|
const QUEST_LOG_BASE_Z : Int = @graphics.UI_ZINDEX + 80

///|
const QUEST_LOG_TAB_COUNT : Int = 2

///|
const QUEST_LOG_DEBUG_PACKAGE : String = "quest_log"

///|
fn tab_debug_name(tab_index : Int) -> String {
  match tab_index {
    0 => "tab.in_progress"
    1 => "tab.completed"
    _ => abort("invalid quest-log tab index: \{tab_index}")
  }
}

///|
fn ui_tab_texture_index(tab_index : Int) -> Int {
  tab_index + 1
}

///|
fn clear_entities(entities : Array[@entity.Entity]) -> Unit {
  for entity in entities {
    entity.destroy()
  }
  entities.clear()
}

///|
fn ui_image_from_texture(texture : @resource.NxTexture) -> @selene_ui.UiImage {
  @selene_ui.UiImage::new(
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    texture.i,
  )
}

///|
fn ui_image_region_from_texture(
  texture : @resource.NxTexture,
) -> @selene_ui.UiImageRegion {
  @selene_ui.UiImageRegion::new({
    position: @selene_math.Vec2D(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
  })
}

///|
fn set_image_texture(
  entity : @entity.Entity,
  texture : @resource.NxTexture,
) -> Unit {
  @selene_ui.ui_images().set(entity, ui_image_from_texture(texture))
  @selene_ui.ui_image_regions().set(
    entity,
    ui_image_region_from_texture(texture),
  )
}

///|
fn spawn_image_node(
  entities : Array[@entity.Entity],
  texture : @resource.NxTexture,
  x : Int,
  y : Int,
  z : Int,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(x.to_double(), y.to_double()),
      size=@selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
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
  color? : String = "#0b1f2a",
  align? : @selene_math.HAlign = @selene_math.Left,
  size? : Double = 12.0,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(x.to_double(), y.to_double()),
      size=@selene_math.Vec2D(width.to_double(), height.to_double()),
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
  @selene_ui.text_colors().set(entity, @selene_ui.TextColor::from_css(color))
  @selene_ui.text_fonts().set(
    entity,
    @selene_ui.TextFont::new(family="Menlo", size~),
  )
  entity
}

///|
fn first_frame_texture(
  animation : @resource.NxAnimation,
  label : String,
) -> @resource.NxTexture raise {
  guard animation.frames.length() > 0 else {
    fail("invalid button animation without frame: \{label}")
  }
  animation.frames[0].texture
}

///|
fn parse_button_resource(
  json : Json,
  label : String,
) -> QuestLogButtonResource raise {
  let button : @ui.NxMapleButton = @json.from_json(json)
  {
    normal: first_frame_texture(button.normal, "\{label}.normal"),
    mouse_over: first_frame_texture(button.mouse_over, "\{label}.mouseOver"),
    pressed: first_frame_texture(button.pressed, "\{label}.pressed"),
    disabled: first_frame_texture(button.disabled, "\{label}.disabled"),
  }
}

///|
fn parse_tab_textures(
  src : Json,
  label : String,
) -> Array[@resource.NxTexture] raise {
  guard src is Object(obj) else { fail("invalid tab json: \{label}") }
  let result = []
  for i in 0..<QUEST_LOG_TAB_COUNT {
    let key = ui_tab_texture_index(i).to_string()
    guard obj.get(key) is Some(value) else {
      fail("missing tab state: \{label}.\{key}")
    }
    let texture : @resource.NxTexture = @json.from_json(value)
    result.push(texture)
  }
  result
}

///|
fn parse_quest_ui_resource(json : Json) -> QuestLogUiResource raise {
  match json {
    {
      "BtMin": bt_min,
      "list": {
        "backgrnd": backgrnd,
        "backgrnd2": backgrnd2,
        "searchArea": search_area,
        "Tab": { "disabled": tab_disabled, "enabled": tab_enabled, .. },
        "BtSearch": bt_search,
        "BtMyLevel": bt_my_level,
        "BtAllLevel": bt_all_level,
        "BtMyLocation": bt_my_location,
        "BtAllLocation": bt_all_location,
        ..
      },
      ..
    } =>
      {
        backgrnd: @json.from_json(backgrnd),
        backgrnd2: @json.from_json(backgrnd2),
        search_area: @json.from_json(search_area),
        tab_disabled: parse_tab_textures(tab_disabled, "Tab.disabled"),
        tab_enabled: parse_tab_textures(tab_enabled, "Tab.enabled"),
        bt_min: parse_button_resource(bt_min, "BtMin"),
        bt_search: parse_button_resource(bt_search, "BtSearch"),
        bt_my_level: parse_button_resource(bt_my_level, "BtMyLevel"),
        bt_all_level: parse_button_resource(bt_all_level, "BtAllLevel"),
        bt_my_location: parse_button_resource(bt_my_location, "BtMyLocation"),
        bt_all_location: parse_button_resource(bt_all_location, "BtAllLocation"),
      }
    _ => fail("invalid UIWindow2 Quest json")
  }
}

///|
async fn load_quest_ui_resource() -> QuestLogUiResource {
  let raw : Json = @resource.get_ui_window_2_loader().load_resource(["Quest"])
  parse_quest_ui_resource(raw)
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
fn clear_render(state : QuestLogUiState) -> Unit {
  for tab_button in state.tab_buttons {
    @console.unregister_ui_entity(tab_button.entity)
  }
  clear_entities(state.render_entities)
  state.tab_buttons.clear()
  state.action_buttons.clear()
}

///|
fn spawn_action_button(
  state : QuestLogUiState,
  button : QuestLogButtonResource,
  x : Int,
  y : Int,
  z : Int,
  enabled : Bool,
  on_click : () -> Unit,
) -> Unit {
  let entity = spawn_image_node(state.render_entities, button.normal, x, y, z)
  @selene_ui.buttons().set(entity, @selene_ui.Button::new())
  state.action_buttons.push({ resource: button, entity, enabled, on_click })
}

///|
fn render_entries(
  state : QuestLogUiState,
  snapshot : @quest_log.QuestLogSnapshot,
) -> Unit {
  let left = state.panel_x + 16
  let top = state.panel_y + 110
  let line_height = 20
  match state.selected_tab {
    0 => {
      if snapshot.in_progress.is_empty() {
        ignore(
          spawn_text_node(
            state.render_entities,
            "No in-progress quests.",
            left,
            top,
            QUEST_LOG_BASE_Z + 30,
            260,
            20,
            color="#777777",
          ),
        )
        return
      }
      for i, entry in snapshot.in_progress {
        if i >= 9 {
          break
        }
        ignore(
          spawn_text_node(
            state.render_entities,
            "[\{entry.quest_id}] \{entry.name}",
            left,
            top + i * line_height,
            QUEST_LOG_BASE_Z + 30,
            260,
            20,
          ),
        )
      }
    }
    1 => {
      if snapshot.completed.is_empty() {
        ignore(
          spawn_text_node(
            state.render_entities,
            "No completed quests.",
            left,
            top,
            QUEST_LOG_BASE_Z + 30,
            260,
            20,
            color="#777777",
          ),
        )
        return
      }
      for i, entry in snapshot.completed {
        if i >= 9 {
          break
        }
        ignore(
          spawn_text_node(
            state.render_entities,
            "[\{entry.quest_id}] \{entry.name}",
            left,
            top + i * line_height,
            QUEST_LOG_BASE_Z + 30,
            260,
            20,
          ),
        )
      }
    }
    _ => abort("invalid quest-log tab index: \{state.selected_tab}")
  }
}

///|
fn render_quest_log(state : QuestLogUiState) -> Unit {
  clear_render(state)
  guard state.ui_resource is Some(res) else { return }
  ignore(
    spawn_image_node(
      state.render_entities,
      res.backgrnd,
      texture_draw_x(state.panel_x, res.backgrnd),
      texture_draw_y(state.panel_y, res.backgrnd),
      QUEST_LOG_BASE_Z,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      res.backgrnd2,
      texture_draw_x(state.panel_x, res.backgrnd2),
      texture_draw_y(state.panel_y, res.backgrnd2),
      QUEST_LOG_BASE_Z + 1,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      res.search_area,
      texture_draw_x(state.panel_x, res.search_area),
      texture_draw_y(state.panel_y, res.search_area),
      QUEST_LOG_BASE_Z + 5,
    ),
  )
  ignore(
    spawn_text_node(
      state.render_entities,
      "Enter the quest name.",
      state.panel_x + 38,
      state.panel_y + 51,
      QUEST_LOG_BASE_Z + 8,
      180,
      16,
      color="#9a9a9a",
      size=11.0,
    ),
  )

  for tab in 0..<QUEST_LOG_TAB_COUNT {
    let texture = if tab == state.selected_tab {
      res.tab_enabled[tab]
    } else {
      res.tab_disabled[tab]
    }
    let entity = spawn_image_node(
      state.render_entities,
      texture,
      texture_draw_x(state.panel_x, texture),
      texture_draw_y(state.panel_y, texture),
      QUEST_LOG_BASE_Z + 10,
    )
    @selene_ui.buttons().set(entity, @selene_ui.Button::new())
    state.tab_buttons.push({ tab_index: tab, entity })
    @console.register_ui_entity(
      QUEST_LOG_DEBUG_PACKAGE,
      tab_debug_name(tab),
      entity,
    )
  }

  spawn_action_button(
    state,
    res.bt_min,
    texture_draw_x(state.panel_x, res.bt_min.normal),
    texture_draw_y(state.panel_y, res.bt_min.normal),
    QUEST_LOG_BASE_Z + 12,
    true,
    fn() { close_quest_log_ui() },
  )
  spawn_action_button(
    state,
    res.bt_search,
    texture_draw_x(state.panel_x, res.bt_search.normal),
    texture_draw_y(state.panel_y, res.bt_search.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.bt_my_level,
    texture_draw_x(state.panel_x, res.bt_my_level.normal),
    texture_draw_y(state.panel_y, res.bt_my_level.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.bt_all_level,
    texture_draw_x(state.panel_x, res.bt_all_level.normal),
    texture_draw_y(state.panel_y, res.bt_all_level.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.bt_my_location,
    texture_draw_x(state.panel_x, res.bt_my_location.normal),
    texture_draw_y(state.panel_y, res.bt_my_location.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.bt_all_location,
    texture_draw_x(state.panel_x, res.bt_all_location.normal),
    texture_draw_y(state.panel_y, res.bt_all_location.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )

  render_entries(state, @quest_log.get_snapshot())
}

///|
fn poll_ui_resource(state : QuestLogUiState) -> Bool {
  guard state.ui_resource is None else { return false }
  if state.ui_loading is None {
    state.ui_loading = Some(
      @io_service.submit_background_task(async fn() { load_quest_ui_resource() }),
    )
    return false
  }
  guard state.ui_loading is Some(future) else { return false }
  match future.poll() {
    Some(Ok(resource)) => {
      state.ui_resource = Some(resource)
      state.ui_loading = None
      true
    }
    Some(Err(err)) => {
      state.ui_loading = None
      @log.error("failed to load quest log ui resource", data={
        "error": err.to_string(),
      })
      false
    }
    None => false
  }
}

///|
fn process_click_events(state : QuestLogUiState) -> Bool {
  let mut dirty = false
  let click_events = @selene_ui.click_event_bus.read(state.click_reader)
  for event in click_events {
    guard event.button is @inputs.MouseButton::Left else { continue }
    let mut handled = false
    for tab in state.tab_buttons {
      if tab.entity == event.entity {
        if tab.tab_index != state.selected_tab {
          state.selected_tab = tab.tab_index
          dirty = true
        }
        handled = true
        break
      }
    }
    if handled {
      continue
    }
    for button in state.action_buttons {
      if button.entity == event.entity {
        if button.enabled {
          (button.on_click)()
        }
        handled = true
        break
      }
    }
    ignore(handled)
  }
  dirty
}

///|
fn update_button_visuals(state : QuestLogUiState) -> Unit {
  for button in state.action_buttons {
    let texture = if not(button.enabled) {
      button.resource.disabled
    } else {
      match @selene_ui.interactions().get(button.entity) {
        Some(@selene_ui.Interaction::Pressed) => button.resource.pressed
        Some(@selene_ui.Interaction::Hovered) => button.resource.mouse_over
        _ => button.resource.normal
      }
    }
    set_image_texture(button.entity, texture)
  }
}

///|
/// Opens the quest-log UI window.
pub fn open_quest_log_ui() -> Unit {
  let state = state()
  state.visible = true
}

///|
/// Closes quest-log UI and clears its entities.
pub fn close_quest_log_ui() -> Unit {
  let state = state()
  state.visible = false
  clear_render(state)
}

///|
/// Toggles quest-log UI visibility.
pub fn toggle_quest_log_ui() -> Unit {
  let state = state()
  state.visible = not(state.visible)
  if not(state.visible) {
    clear_render(state)
  }
}

///|
/// Returns whether quest-log UI is currently open.
pub fn is_quest_log_ui_open() -> Bool {
  state().visible
}

///|
/// Quest-log UI system.
pub fn quest_log_ui_system(_delta : Double) -> Unit {
  let state = state()
  guard @game_state.game_state.phase is @game_state.GamePhase::GameActive(..) else {
    close_quest_log_ui()
    return
  }

  if @inputs.is_just_pressed(@inputs.Code::KeyQ) {
    toggle_quest_log_ui()
    return
  }
  if not(state.visible) {
    return
  }
  if @inputs.is_just_pressed(@inputs.Code::Escape) {
    close_quest_log_ui()
    return
  }
  if state.selected_tab < 0 || state.selected_tab >= QUEST_LOG_TAB_COUNT {
    state.selected_tab = 0
  }
  let mut dirty = false
  if @inputs.is_just_pressed(@inputs.Code::Tab) {
    state.selected_tab = (state.selected_tab + 1) % QUEST_LOG_TAB_COUNT
    dirty = true
  }
  if poll_ui_resource(state) {
    dirty = true
  }
  let rev = @quest_log.revision()
  if rev != state.last_revision {
    state.last_revision = rev
    dirty = true
  }
  if process_click_events(state) {
    dirty = true
  }
  if dirty || state.render_entities.is_empty() {
    render_quest_log(state)
  }
  update_button_visuals(state)
}
