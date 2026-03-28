///|
priv struct QuestLogButtonResource {
  normal : @resource.NxTexture
  mouse_over : @resource.NxTexture
  pressed : @resource.NxTexture
  disabled : @resource.NxTexture
}

///|
priv struct QuestListUiResource {
  backgrnd : @resource.NxTexture
  backgrnd2 : @resource.NxTexture
  search_area : @resource.NxTexture
  tab_disabled : Array[@resource.NxTexture]
  tab_enabled : Array[@resource.NxTexture]
  quest_state_icons : Array[@resource.NxTexture]
  bt_search : QuestLogButtonResource
  bt_my_level : QuestLogButtonResource
  bt_all_level : QuestLogButtonResource
  bt_my_location : QuestLogButtonResource
  bt_all_location : QuestLogButtonResource
}

///|
priv struct QuestInfoUiResource {
  backgrnd : @resource.NxTexture
  backgrnd2 : @resource.NxTexture
  backgrnd3 : @resource.NxTexture
  summary : @resource.NxTexture
  bt_giveup : QuestLogButtonResource
  bt_navi : QuestLogButtonResource
  bt_helper : QuestLogButtonResource
}

///|
priv struct QuestLogUiResource {
  list : QuestListUiResource
  info : QuestInfoUiResource
  bt_min : QuestLogButtonResource
}

///|
priv struct TabButton {
  tab_index : Int
  entity : @entity.Entity
}

///|
priv struct QuestEntryButton {
  tab_index : Int
  entry_index : Int
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
priv struct TextRun {
  text : String
  color : String
  bold : Bool
  underline : Bool
}

///|
priv struct TextStyleState {
  color : String
  bold : Bool
  underline : Bool
}

///|
priv struct QuestLogUiState {
  mut visible : Bool
  mut selected_tab : Int
  mut selected_in_progress_index : Int
  mut selected_completed_index : Int
  panel_x : Int
  panel_y : Int
  mut last_revision : Int
  mut ui_resource : QuestLogUiResource?
  mut ui_loading : @utils.Future[Result[QuestLogUiResource, Error]]?
  render_entities : Array[@entity.Entity]
  tab_buttons : Array[TabButton]
  quest_entry_buttons : Array[QuestEntryButton]
  action_buttons : Array[ActionButton]
  mut selected_forfeit_quest_id : Int?
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
}

///|
let states_by_world_ref : Ref[Map[UInt, QuestLogUiState]] = Ref::new(Map::new())

///|
fn make_initial_state() -> QuestLogUiState {
  {
    visible: false,
    selected_tab: 0,
    selected_in_progress_index: 0,
    selected_completed_index: 0,
    panel_x: 300,
    panel_y: 160,
    last_revision: -1,
    ui_resource: None,
    ui_loading: None,
    render_entities: [],
    tab_buttons: [],
    quest_entry_buttons: [],
    action_buttons: [],
    selected_forfeit_quest_id: None,
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
const LEFT_PANEL_WIDTH : Int = 295

///|
fn tab_debug_name(tab_index : Int) -> String {
  match tab_index {
    0 => "tab.in_progress"
    1 => "tab.completed"
    _ => abort("invalid quest-log tab index: \{tab_index}")
  }
}

///|
fn quest_row_debug_name(tab_index : Int, row_index : Int) -> String {
  let tab = if tab_index == 0 { "in_progress" } else { "completed" }
  "row.\{tab}.\{row_index}"
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
  let source = ui_image_source_from_texture(texture)
  @selene_ui.UiImage::new(
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    texture.i,
    source=Some(source),
  )
}

///|
fn ui_image_source_from_texture(
  texture : @resource.NxTexture,
) -> @render2d_types.ImageRegion2D {
  {
    position: @selene_math.Vec2D(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
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
fn set_text_style(entity : @entity.Entity, run : TextRun) -> Unit {
  @selene_ui.text_fonts().set(
    entity,
    @selene_ui.TextFont::new(family="Menlo", size=12.0, bold=run.bold),
  )
  @selene_ui.text_colors().set(
    entity,
    @selene_ui.TextColor::from_css(run.color),
  )
}

///|
fn spawn_rich_text_block(
  entities : Array[@entity.Entity],
  runs : Array[TextRun],
  x : Int,
  y : Int,
  z : Int,
  width : Int,
  height : Int,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(x.to_double(), y.to_double()),
      size=@selene_math.Vec2D(width.to_double(), height.to_double()),
      overflow_x=@selene_ui.Overflow::Clip,
      overflow_y=@selene_ui.Overflow::Clip,
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout::new(
      align=@selene_math.Left,
      baseline=@selene_math.Top,
      line_height=1.22,
      wrap=@selene_ui.TextWrap::WordWrap,
      overflow=@selene_ui.TextOverflow::Clip,
    ),
  )
  let spans : Array[@selene_ui.TextSpan] = runs.map(fn(run) {
    @selene_ui.TextSpan::new(
      run.text,
      font=Some(
        @selene_ui.TextFont::new(family="Menlo", size=12.0, bold=run.bold),
      ),
      color=Some(@selene_ui.TextColor::from_css(run.color)),
      bold=run.bold,
      underline=run.underline,
    )
  })
  @selene_ui.texts().set(entity, @selene_ui.Text::from_spans(spans))
  let first = runs
    .get(0)
    .unwrap_or({ text: "", color: "#0b1f2a", bold: false, underline: false })
  set_text_style(entity, first)
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
fn parse_quest_state_icons(src : Json) -> Array[@resource.NxTexture] raise {
  guard src is Object(obj) else { fail("invalid list.questState") }
  let icon0 = match obj.get("0") {
    Some(v) => v
    None => fail("missing questState.0")
  }
  let icon1 = match obj.get("1") {
    Some(v) => v
    None => fail("missing questState.1")
  }
  [@json.from_json(icon0), @json.from_json(icon1)]
}

///|
fn parse_quest_ui_resource(json : Json) -> QuestLogUiResource raise {
  match json {
    {
      "BtMin": bt_min,
      "list": {
        "backgrnd": list_backgrnd,
        "backgrnd2": list_backgrnd2,
        "searchArea": search_area,
        "Tab": { "disabled": tab_disabled, "enabled": tab_enabled, .. },
        "questState": quest_state,
        "BtSearch": bt_search,
        "BtMyLevel": bt_my_level,
        "BtAllLevel": bt_all_level,
        "BtMyLocation": bt_my_location,
        "BtAllLocation": bt_all_location,
        ..
      },
      "quest_info": {
        "backgrnd": info_backgrnd,
        "backgrnd2": info_backgrnd2,
        "backgrnd3": info_backgrnd3,
        "summary": summary,
        "BtGiveup": bt_giveup,
        "BtNavi": bt_navi,
        "BtArlim": bt_helper,
        ..
      },
      ..
    } =>
      {
        bt_min: parse_button_resource(bt_min, "BtMin"),
        list: {
          backgrnd: @json.from_json(list_backgrnd),
          backgrnd2: @json.from_json(list_backgrnd2),
          search_area: @json.from_json(search_area),
          tab_disabled: parse_tab_textures(tab_disabled, "Tab.disabled"),
          tab_enabled: parse_tab_textures(tab_enabled, "Tab.enabled"),
          quest_state_icons: parse_quest_state_icons(quest_state),
          bt_search: parse_button_resource(bt_search, "BtSearch"),
          bt_my_level: parse_button_resource(bt_my_level, "BtMyLevel"),
          bt_all_level: parse_button_resource(bt_all_level, "BtAllLevel"),
          bt_my_location: parse_button_resource(bt_my_location, "BtMyLocation"),
          bt_all_location: parse_button_resource(
            bt_all_location, "BtAllLocation",
          ),
        },
        info: {
          backgrnd: @json.from_json(info_backgrnd),
          backgrnd2: @json.from_json(info_backgrnd2),
          backgrnd3: @json.from_json(info_backgrnd3),
          summary: @json.from_json(summary),
          bt_giveup: parse_button_resource(bt_giveup, "BtGiveup"),
          bt_navi: parse_button_resource(bt_navi, "BtNavi"),
          bt_helper: parse_button_resource(bt_helper, "BtArlim"),
        },
      }
    _ => fail("invalid UIWindow2 Quest json")
  }
}

///|
async fn load_quest_ui_resource() -> QuestLogUiResource {
  let raw : Json = @resource.get_async_loader("ui_window_2").load_resource([
    "Quest",
  ])
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
  for row in state.quest_entry_buttons {
    @console.unregister_ui_entity(row.entity)
  }
  clear_entities(state.render_entities)
  state.tab_buttons.clear()
  state.quest_entry_buttons.clear()
  state.action_buttons.clear()
  state.selected_forfeit_quest_id = None
}

///|
fn current_selected_index(state : QuestLogUiState, tab : Int) -> Int {
  if tab == 0 {
    state.selected_in_progress_index
  } else {
    state.selected_completed_index
  }
}

///|
fn set_current_selected_index(
  state : QuestLogUiState,
  tab : Int,
  index : Int,
) -> Unit {
  if tab == 0 {
    state.selected_in_progress_index = index
  } else {
    state.selected_completed_index = index
  }
}

///|
fn clamp_selected_indexes(
  state : QuestLogUiState,
  snapshot : @quest_log.QuestLogSnapshot,
) -> Unit {
  let in_progress_len = snapshot.in_progress.length()
  let completed_len = snapshot.completed.length()
  if in_progress_len <= 0 {
    state.selected_in_progress_index = 0
  } else if state.selected_in_progress_index >= in_progress_len {
    state.selected_in_progress_index = in_progress_len - 1
  }
  if completed_len <= 0 {
    state.selected_completed_index = 0
  } else if state.selected_completed_index >= completed_len {
    state.selected_completed_index = completed_len - 1
  }
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
fn color_for_tag(tag : Char) -> String? {
  match tag {
    'b' => Some("#2a61d8")
    'r' => Some("#d64545")
    'k' => Some("#0b1f2a")
    'd' => Some("#7f4db8")
    'g' => Some("#2f8f5b")
    _ => None
  }
}

///|
fn apply_style_tag(style : TextStyleState, tag : Char) -> TextStyleState? {
  if color_for_tag(tag) is Some(color) {
    Some({ ..style, color, })
  } else {
    match tag {
      'e' => Some({ ..style, bold: true })
      'u' => Some({ ..style, underline: true })
      'n' => Some({ ..style, bold: false, underline: false })
      _ => None
    }
  }
}

///|
fn current_player_name() -> String {
  if @player.get_player() is Some(player) {
    let name = player.get_stats().get_name()
    if not(name.is_empty()) {
      return name
    }
  }
  "Player"
}

///|
fn replace_pair_tag_runtime(tag : Char, payload : StringView) -> String? {
  let raw = payload.to_string()
  match tag {
    't' => Some(@markup_text.resolve_item_name(payload)) catch { _ => None }
    'c' => {
      let item_id = @strconv.parse_int(raw) catch { _ => -1 }
      if item_id < 0 {
        None
      } else {
        Some(@inventory.inventory.val.get_item_count(item_id).to_string())
      }
    }
    'p' => Some(@markup_text.resolve_npc_name(payload)) catch { _ => None }
    'o' => Some(@markup_text.resolve_mob_name(payload)) catch { _ => None }
    'm' => Some(@markup_text.resolve_map_name(payload)) catch { _ => None }
    'h' => Some(current_player_name())
    _ => None
  }
}

///|
fn push_run(
  runs : Array[TextRun],
  text : String,
  style : TextStyleState,
) -> Unit {
  if text.is_empty() {
    return
  }
  runs.push({
    text,
    color: style.color,
    bold: style.bold,
    underline: style.underline,
  })
}

///|
fn parse_rich_text_runs_core(
  raw : String,
  pair_replacer : (Char, StringView) -> String?,
) -> Array[TextRun] {
  let runs : Array[TextRun] = []
  let mut style : TextStyleState = {
    color: "#0b1f2a",
    bold: false,
    underline: false,
  }
  let mut rest : StringView = raw[:]
  while true {
    guard rest.find("#") is Some(mark_pos) else {
      push_run(runs, rest.to_string(), style)
      break
    }
    if mark_pos > 0 {
      push_run(runs, rest.view(end_offset=mark_pos).to_string(), style)
    }
    if mark_pos + 1 >= rest.length() {
      push_run(runs, "#", style)
      break
    }
    let tag = rest.get_char(mark_pos + 1).unwrap_or('#')
    if apply_style_tag(style, tag) is Some(next_style) {
      style = next_style
      rest = rest.view(start_offset=mark_pos + 2)
      continue
    }
    let payload_part = rest.view(start_offset=mark_pos + 2)
    if payload_part.find("#") is Some(end_pos) {
      let payload = payload_part.view(end_offset=end_pos)
      if pair_replacer(tag, payload) is Some(replaced) {
        push_run(runs, replaced, style)
      } else {
        push_run(runs, "#\{tag}\{payload.to_string()}#", style)
      }
      rest = payload_part.view(start_offset=end_pos + 1)
      continue
    }
    // Keep unknown or incomplete tags as raw text.
    push_run(runs, rest.view(start_offset=mark_pos).to_string(), style)
    break
  }
  runs
}

///|
fn parse_rich_text_runs(raw : String) -> Array[TextRun] {
  parse_rich_text_runs_core(raw, replace_pair_tag_runtime)
}

///|
fn render_entries(
  state : QuestLogUiState,
  snapshot : @quest_log.QuestLogSnapshot,
  list_res : QuestListUiResource,
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
            250,
            20,
            color="#777777",
          ),
        )
        return
      }
      for i, entry in snapshot.in_progress {
        if i >= 11 {
          break
        }
        let selected = i == state.selected_in_progress_index
        let icon = if selected {
          list_res.quest_state_icons[1]
        } else {
          list_res.quest_state_icons[0]
        }
        let icon_entity = spawn_image_node(
          state.render_entities,
          icon,
          left,
          top + i * line_height + 3,
          QUEST_LOG_BASE_Z + 28,
        )
        @selene_ui.buttons().set(icon_entity, @selene_ui.Button::new())
        let icon_button = { tab_index: 0, entry_index: i, entity: icon_entity }
        state.quest_entry_buttons.push(icon_button)
        @console.register_ui_entity(
          QUEST_LOG_DEBUG_PACKAGE,
          quest_row_debug_name(0, i * 2),
          icon_entity,
        )
        let label = if selected {
          "> [\{entry.quest_id}] \{entry.name}"
        } else {
          "  [\{entry.quest_id}] \{entry.name}"
        }
        let text_entity = spawn_text_node(
          state.render_entities,
          label,
          left + 14,
          top + i * line_height,
          QUEST_LOG_BASE_Z + 30,
          245,
          20,
          color=if selected { "#ffffff" } else { "#0b1f2a" },
        )
        @selene_ui.buttons().set(text_entity, @selene_ui.Button::new())
        let text_button = { tab_index: 0, entry_index: i, entity: text_entity }
        state.quest_entry_buttons.push(text_button)
        @console.register_ui_entity(
          QUEST_LOG_DEBUG_PACKAGE,
          quest_row_debug_name(0, i * 2 + 1),
          text_entity,
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
            250,
            20,
            color="#777777",
          ),
        )
        return
      }
      for i, entry in snapshot.completed {
        if i >= 11 {
          break
        }
        let selected = i == state.selected_completed_index
        let icon = if selected {
          list_res.quest_state_icons[1]
        } else {
          list_res.quest_state_icons[0]
        }
        let icon_entity = spawn_image_node(
          state.render_entities,
          icon,
          left,
          top + i * line_height + 3,
          QUEST_LOG_BASE_Z + 28,
        )
        @selene_ui.buttons().set(icon_entity, @selene_ui.Button::new())
        let icon_button = { tab_index: 1, entry_index: i, entity: icon_entity }
        state.quest_entry_buttons.push(icon_button)
        @console.register_ui_entity(
          QUEST_LOG_DEBUG_PACKAGE,
          quest_row_debug_name(1, i * 2),
          icon_entity,
        )
        let label = if selected {
          "> [\{entry.quest_id}] \{entry.name}"
        } else {
          "  [\{entry.quest_id}] \{entry.name}"
        }
        let text_entity = spawn_text_node(
          state.render_entities,
          label,
          left + 14,
          top + i * line_height,
          QUEST_LOG_BASE_Z + 30,
          245,
          20,
          color=if selected { "#ffffff" } else { "#0b1f2a" },
        )
        @selene_ui.buttons().set(text_entity, @selene_ui.Button::new())
        let text_button = { tab_index: 1, entry_index: i, entity: text_entity }
        state.quest_entry_buttons.push(text_button)
        @console.register_ui_entity(
          QUEST_LOG_DEBUG_PACKAGE,
          quest_row_debug_name(1, i * 2 + 1),
          text_entity,
        )
      }
    }
    _ => abort("invalid quest-log tab index: \{state.selected_tab}")
  }
}

///|
fn selected_in_progress_entry(
  state : QuestLogUiState,
  snapshot : @quest_log.QuestLogSnapshot,
) -> @quest_log.QuestLogEntryInProgress? {
  if snapshot.in_progress.is_empty() {
    None
  } else {
    snapshot.in_progress.get(state.selected_in_progress_index)
  }
}

///|
fn selected_completed_entry(
  state : QuestLogUiState,
  snapshot : @quest_log.QuestLogSnapshot,
) -> @quest_log.QuestLogEntryCompleted? {
  if snapshot.completed.is_empty() {
    None
  } else {
    snapshot.completed.get(state.selected_completed_index)
  }
}

///|
fn render_detail_panel(
  state : QuestLogUiState,
  snapshot : @quest_log.QuestLogSnapshot,
  info_res : QuestInfoUiResource,
) -> Unit {
  let panel_x = state.panel_x + LEFT_PANEL_WIDTH - 1
  let panel_y = state.panel_y
  ignore(
    spawn_image_node(
      state.render_entities,
      info_res.backgrnd,
      texture_draw_x(panel_x, info_res.backgrnd),
      texture_draw_y(panel_y, info_res.backgrnd),
      QUEST_LOG_BASE_Z,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      info_res.backgrnd2,
      texture_draw_x(panel_x, info_res.backgrnd2),
      texture_draw_y(panel_y, info_res.backgrnd2),
      QUEST_LOG_BASE_Z + 1,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      info_res.backgrnd3,
      texture_draw_x(panel_x, info_res.backgrnd3),
      texture_draw_y(panel_y, info_res.backgrnd3),
      QUEST_LOG_BASE_Z + 5,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      info_res.summary,
      texture_draw_x(panel_x, info_res.summary),
      texture_draw_y(panel_y + 100, info_res.summary),
      QUEST_LOG_BASE_Z + 5,
    ),
  )

  let title_x = panel_x + 20
  let title_y = panel_y + 20
  if state.selected_tab == 0 {
    if selected_in_progress_entry(state, snapshot) is Some(entry) {
      state.selected_forfeit_quest_id = Some(entry.quest_id)
      ignore(
        spawn_text_node(
          state.render_entities,
          "[\{entry.quest_id}] \{entry.name}",
          title_x,
          title_y,
          QUEST_LOG_BASE_Z + 30,
          220,
          22,
          color="#f4ffff",
          size=14.0,
        ),
      )
      ignore(
        spawn_text_node(
          state.render_entities,
          "In Progress · Phase \{entry.phase}",
          title_x,
          title_y + 22,
          QUEST_LOG_BASE_Z + 30,
          220,
          18,
          color="#dff8ff",
          size=12.0,
        ),
      )
      let detail_text = if entry.progress_data.is_empty() {
        entry.phase_description
      } else {
        "\{entry.phase_description}\n\n\{entry.progress_data}"
      }
      let runs = parse_rich_text_runs(detail_text)
      ignore(
        spawn_rich_text_block(
          state.render_entities,
          runs,
          panel_x + 20,
          panel_y + 150,
          QUEST_LOG_BASE_Z + 30,
          240,
          176,
        ),
      )
    } else {
      state.selected_forfeit_quest_id = None
      ignore(
        spawn_text_node(
          state.render_entities,
          "No quest selected.",
          title_x,
          title_y,
          QUEST_LOG_BASE_Z + 30,
          220,
          22,
          color="#e6f4fb",
          size=14.0,
        ),
      )
    }
  } else {
    state.selected_forfeit_quest_id = None
    if selected_completed_entry(state, snapshot) is Some(entry) {
      ignore(
        spawn_text_node(
          state.render_entities,
          "[\{entry.quest_id}] \{entry.name}",
          title_x,
          title_y,
          QUEST_LOG_BASE_Z + 30,
          220,
          22,
          color="#f4ffff",
          size=14.0,
        ),
      )
      ignore(
        spawn_text_node(
          state.render_entities,
          "Completed",
          title_x,
          title_y + 22,
          QUEST_LOG_BASE_Z + 30,
          220,
          18,
          color="#dff8ff",
          size=12.0,
        ),
      )
      ignore(
        spawn_rich_text_block(
          state.render_entities,
          [
            {
              text: "Quest completed at timestamp: \{entry.completion_time}",
              color: "#0b1f2a",
              bold: false,
              underline: false,
            },
          ],
          panel_x + 20,
          panel_y + 150,
          QUEST_LOG_BASE_Z + 30,
          240,
          176,
        ),
      )
    } else {
      ignore(
        spawn_text_node(
          state.render_entities,
          "No quest selected.",
          title_x,
          title_y,
          QUEST_LOG_BASE_Z + 30,
          220,
          22,
          color="#e6f4fb",
          size=14.0,
        ),
      )
    }
  }

  let can_forfeit = state.selected_tab == 0 &&
    state.selected_forfeit_quest_id is Some(_)
  spawn_action_button(
    state,
    info_res.bt_giveup,
    texture_draw_x(panel_x + 200, info_res.bt_giveup.normal),
    texture_draw_y(panel_y + 360, info_res.bt_giveup.normal),
    QUEST_LOG_BASE_Z + 18,
    can_forfeit,
    fn() {
      if state.selected_forfeit_quest_id is Some(quest_id) {
        if @quest_log.forfeit(quest_id) is Err(err) {
          @log.warn("quest forfeit rejected", data={
            "quest_id": quest_id,
            "error": err,
          })
        }
      }
    },
  )
  spawn_action_button(
    state,
    info_res.bt_navi,
    texture_draw_x(panel_x + 128, info_res.bt_navi.normal),
    texture_draw_y(panel_y + 360, info_res.bt_navi.normal),
    QUEST_LOG_BASE_Z + 18,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    info_res.bt_helper,
    texture_draw_x(panel_x + 52, info_res.bt_helper.normal),
    texture_draw_y(panel_y + 360, info_res.bt_helper.normal),
    QUEST_LOG_BASE_Z + 18,
    false,
    fn() { () },
  )
}

///|
fn render_quest_log(state : QuestLogUiState) -> Unit {
  clear_render(state)
  guard state.ui_resource is Some(res) else { return }
  let list_x = state.panel_x
  let list_y = state.panel_y
  ignore(
    spawn_image_node(
      state.render_entities,
      res.list.backgrnd,
      texture_draw_x(list_x, res.list.backgrnd),
      texture_draw_y(list_y, res.list.backgrnd),
      QUEST_LOG_BASE_Z,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      res.list.backgrnd2,
      texture_draw_x(list_x, res.list.backgrnd2),
      texture_draw_y(list_y, res.list.backgrnd2),
      QUEST_LOG_BASE_Z + 1,
    ),
  )
  ignore(
    spawn_image_node(
      state.render_entities,
      res.list.search_area,
      texture_draw_x(list_x, res.list.search_area),
      texture_draw_y(list_y, res.list.search_area),
      QUEST_LOG_BASE_Z + 5,
    ),
  )
  ignore(
    spawn_text_node(
      state.render_entities,
      "Enter the quest name.",
      list_x + 38,
      list_y + 51,
      QUEST_LOG_BASE_Z + 8,
      180,
      16,
      color="#9a9a9a",
      size=11.0,
    ),
  )

  for tab in 0..<QUEST_LOG_TAB_COUNT {
    let texture = if tab == state.selected_tab {
      res.list.tab_enabled[tab]
    } else {
      res.list.tab_disabled[tab]
    }
    let entity = spawn_image_node(
      state.render_entities,
      texture,
      texture_draw_x(list_x, texture),
      texture_draw_y(list_y, texture),
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
    texture_draw_x(list_x, res.bt_min.normal),
    texture_draw_y(list_y, res.bt_min.normal),
    QUEST_LOG_BASE_Z + 12,
    true,
    fn() { close_quest_log_ui() },
  )
  spawn_action_button(
    state,
    res.list.bt_search,
    texture_draw_x(list_x, res.list.bt_search.normal),
    texture_draw_y(list_y, res.list.bt_search.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.list.bt_my_level,
    texture_draw_x(list_x, res.list.bt_my_level.normal),
    texture_draw_y(list_y, res.list.bt_my_level.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.list.bt_all_level,
    texture_draw_x(list_x, res.list.bt_all_level.normal),
    texture_draw_y(list_y, res.list.bt_all_level.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.list.bt_my_location,
    texture_draw_x(list_x, res.list.bt_my_location.normal),
    texture_draw_y(list_y, res.list.bt_my_location.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )
  spawn_action_button(
    state,
    res.list.bt_all_location,
    texture_draw_x(list_x, res.list.bt_all_location.normal),
    texture_draw_y(list_y, res.list.bt_all_location.normal),
    QUEST_LOG_BASE_Z + 12,
    false,
    fn() { () },
  )

  let snapshot = @quest_log.get_snapshot()
  clamp_selected_indexes(state, snapshot)
  render_entries(state, snapshot, res.list)
  render_detail_panel(state, snapshot, res.info)
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
    for row in state.quest_entry_buttons {
      if row.entity == event.entity {
        if row.tab_index == state.selected_tab {
          let prev = current_selected_index(state, row.tab_index)
          if prev != row.entry_index {
            set_current_selected_index(state, row.tab_index, row.entry_index)
            dirty = true
          }
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
          dirty = true
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
pub fn quest_log_ui_system(_world : @ecs.World) -> Unit {
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

///|
test "parse rich text style tags" {
  let runs = parse_rich_text_runs_core(
    "#bBlue #rRed #kBlack #eBold#n Normal #uUnderline#n",
    fn(_tag, _payload) { None },
  )
  assert_true(runs.length() > 3)
}

///|
test "parse rich text reference and unknown tags" {
  let runs = parse_rich_text_runs_core("#t123# #c123# #L0#Option#l", fn(
    tag,
    payload,
  ) {
    match tag {
      't' => Some("ITEM-\{payload.to_string()}")
      'c' => Some("7")
      _ => None
    }
  })
  let buf = StringBuilder::new()
  for run in runs {
    buf.write_string(run.text)
  }
  let text = buf.to_string()
  inspect(text, content="ITEM-123 7 #L0#Option#l")
}
