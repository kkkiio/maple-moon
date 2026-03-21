///|
using @npc {type TalkArgs}

///|
pub(all) struct NpcTalkResource {
  top : @resource.NxTexture
  fill : @resource.NxTexture
  bottom : @resource.NxTexture
  bar : @resource.NxTexture
  bt_yes : NpcTalkButtonResource
  bt_no : NpcTalkButtonResource
  bt_ok : NpcTalkButtonResource
  bt_next : NpcTalkButtonResource
  bt_prev : NpcTalkButtonResource
  bt_close : NpcTalkButtonResource
  bt_qstart : NpcTalkButtonResource
  bt_qyes : NpcTalkButtonResource
  bt_qno : NpcTalkButtonResource
  bt_qcyes : NpcTalkButtonResource
  bt_qcno : NpcTalkButtonResource
  bt_qgiveup : NpcTalkButtonResource
  bt_qafter : NpcTalkButtonResource
  bt_my_level : NpcTalkButtonResource
  bt_all_level : NpcTalkButtonResource
}

///|
pub(all) struct NpcTalkButtonResource {
  normal : @resource.NxTexture
  mouse_over : @resource.NxTexture
  pressed : @resource.NxTexture
  disabled : @resource.NxTexture
}

///|
fn json_to_texture(json : Json) -> @resource.NxTexture raise {
  @json.from_json(json)
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
fn json_to_button_resource(
  json : Json,
  label : String,
) -> NpcTalkButtonResource raise {
  let button : @ui.NxMapleButton = @json.from_json(json)
  {
    normal: first_frame_texture(button.normal, "\{label}.normal"),
    mouse_over: first_frame_texture(button.mouse_over, "\{label}.mouseOver"),
    pressed: first_frame_texture(button.pressed, "\{label}.pressed"),
    disabled: first_frame_texture(button.disabled, "\{label}.disabled"),
  }
}

///|
pub fn NpcTalkResource::from_resource(
  util_dlg_ex : Json,
) -> NpcTalkResource raise {
  match util_dlg_ex {
    {
      "t": top,
      "c": fill,
      "s": bottom,
      "bar": bar,
      "BtYes": bt_yes,
      "BtNo": bt_no,
      "BtOK": bt_ok,
      "BtNext": bt_next,
      "BtPrev": bt_prev,
      "BtClose": bt_close,
      "BtQStart": bt_qstart,
      "BtQYes": bt_qyes,
      "BtQNo": bt_qno,
      "BtQCYes": bt_qcyes,
      "BtQCNo": bt_qcno,
      "BtQGiveup": bt_qgiveup,
      "BtQAfter": bt_qafter,
      "BtMyLevel": bt_my_level,
      "BtAllLevel": bt_all_level,
      ..
    } =>
      {
        top: json_to_texture(top),
        fill: json_to_texture(fill),
        bottom: json_to_texture(bottom),
        bar: json_to_texture(bar),
        bt_yes: json_to_button_resource(bt_yes, "BtYes"),
        bt_no: json_to_button_resource(bt_no, "BtNo"),
        bt_ok: json_to_button_resource(bt_ok, "BtOK"),
        bt_next: json_to_button_resource(bt_next, "BtNext"),
        bt_prev: json_to_button_resource(bt_prev, "BtPrev"),
        bt_close: json_to_button_resource(bt_close, "BtClose"),
        bt_qstart: json_to_button_resource(bt_qstart, "BtQStart"),
        bt_qyes: json_to_button_resource(bt_qyes, "BtQYes"),
        bt_qno: json_to_button_resource(bt_qno, "BtQNo"),
        bt_qcyes: json_to_button_resource(bt_qcyes, "BtQCYes"),
        bt_qcno: json_to_button_resource(bt_qcno, "BtQCNo"),
        bt_qgiveup: json_to_button_resource(bt_qgiveup, "BtQGiveup"),
        bt_qafter: json_to_button_resource(bt_qafter, "BtQAfter"),
        bt_my_level: json_to_button_resource(bt_my_level, "BtMyLevel"),
        bt_all_level: json_to_button_resource(bt_all_level, "BtAllLevel"),
      }
    _ => fail("invalid UtilDlgEx json")
  }
}

///|
priv struct TextRun {
  text : String
  color : ColorName
  bold : Bool
  underline : Bool
}

///|
priv struct SelectionLine {
  option : Int
  lines : Array[Array[TextRun]]
}

///|
priv struct NPCTalkContent {
  body_lines : Array[Array[TextRun]]
  selections : Array[SelectionLine]
}

///|
priv struct SelectionButton {
  entity : @entity.Entity
  option : Int
}

///|
priv struct ActionButton {
  resource : NpcTalkButtonResource
  entity : @entity.Entity
  enabled : Bool
  on_click : () -> Unit
}

///|
priv struct UINpcTalk {
  resource : NpcTalkResource
  args : TalkArgs
  content : NPCTalkContent
  entities : Array[@entity.Entity]
  buttons : Array[ActionButton]
  selection_buttons : Array[SelectionButton]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
  mut window_pos : Point[Int]
  mut body_height : Int
}

///|
const NPC_TALK_Z : Int = @graphics.UI_ZINDEX + 100

///|
const CONTENT_X = 166

///|
const CONTENT_Y = 19

///|
const LINE_GAP = 4

///|
const FIXED_BODY_HEIGHT = 76

///|
const CONTENT_RIGHT_PADDING = 36

///|
const TEXT_LINE_HEIGHT = 1.25

///|
let npc_talk_ui_ref : Ref[UINpcTalk?] = Ref::new(None)

///|
let npc_talk_resource_ref : Ref[NpcTalkResource?] = Ref::new(None)

///|
let npc_talk_loading_ref : Ref[@utils.Future[Result[NpcTalkResource, Error]]?] = Ref::new(
  None,
)

///|
let npc_talk_pending_args_ref : Ref[TalkArgs?] = Ref::new(None)

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
async fn load_npc_talk_resource() -> NpcTalkResource {
  let src : Json = @resource.get_ui_window_2_loader().load_resource([
    "UtilDlgEx",
  ])
  NpcTalkResource::from_resource(src)
}

///|
/// Store a parsed NPC talk resource in the shared runtime cache.
pub fn cache_npc_talk_resource(resource : NpcTalkResource) -> Unit {
  npc_talk_loading_ref.val = None
  npc_talk_resource_ref.val = Some(resource)
}

///|
pub fn is_npc_talk_ui_open() -> Bool {
  npc_talk_ui_ref.val is Some(_)
}

///|
/// Describe the currently open NPC talk UI for blackbox assertions.
pub fn describe_npc_talk_ui() -> Json {
  match npc_talk_ui_ref.val {
    Some(ui) => {
      let mut has_z = false
      let mut z_min = 0
      let mut z_max = 0
      fn update_z(z : Int) -> Unit {
        if has_z {
          if z < z_min {
            z_min = z
          }
          if z > z_max {
            z_max = z
          }
        } else {
          has_z = true
          z_min = z
          z_max = z
        }
      }
      for entity in ui.entities {
        match @selene_ui.z_indexes().get(entity) {
          Some(z) => update_z(z.value)
          None => ()
        }
      }
      if not(has_z) {
        z_min = NPC_TALK_Z
        z_max = NPC_TALK_Z
      }
      let window_w = ui.resource.top.w
      let window_h = ui.resource.top.h + ui.body_height + ui.resource.bottom.h
      let window_left = ui.window_pos.x
      let window_top = ui.window_pos.y
      let window_right = window_left + window_w
      let window_bottom = window_top + window_h
      let body_lines : Array[Json] = ui.content.body_lines.map(fn(line) {
        line.map(fn(run) { run.text }).join("").to_json()
      })
      let selections : Array[Json] = ui.content.selections.map(fn(selection) {
        {
          "option": selection.option.to_json(),
          "text": selection.lines
          .map(fn(line) { line.map(fn(run) { run.text }).join("") })
          .join("\n")
          .to_json(),
        }
      })
      {
        "open": true,
        "body_lines": body_lines,
        "selections": selections.to_json(),
        "button_count": ui.buttons.length().to_json(),
        "choice_area_count": ui.selection_buttons.length().to_json(),
        "window_pos": {
          "x": ui.window_pos.x.to_json(),
          "y": ui.window_pos.y.to_json(),
        },
        "window_size": { "w": window_w.to_json(), "h": window_h.to_json() },
        "window_rect": {
          "left": window_left.to_json(),
          "top": window_top.to_json(),
          "right": window_right.to_json(),
          "bottom": window_bottom.to_json(),
        },
        "z_range": { "min": z_min.to_json(), "max": z_max.to_json() },
        "body_height": ui.body_height.to_json(),
      }
    }
    None => { "open": false }
  }
}

///|
pub fn close_npc_talk_ui() -> Unit {
  npc_talk_pending_args_ref.val = None
  match npc_talk_ui_ref.val {
    Some(ui) => {
      ui.destroy()
      npc_talk_ui_ref.val = None
    }
    None => ()
  }
}

///|
pub fn open_npc_talk_ui(args : TalkArgs) -> Unit {
  close_npc_talk_ui()
  if npc_talk_resource_ref.val is None && npc_talk_loading_ref.val is None {
    npc_talk_loading_ref.val = Some(
      @io_service.submit_background_task(async fn() { load_npc_talk_resource() }),
    )
  }
  npc_talk_pending_args_ref.val = Some(args)
}

///|
pub fn npc_talk_ui_system(_delta : Double) -> Unit {
  guard @game_state.game_state.phase is @game_state.GamePhase::GameActive(..) else {
    close_npc_talk_ui()
    return
  }
  poll_npc_talk_resource()
  poll_npc_talk_open_request()
  match npc_talk_ui_ref.val {
    Some(ui) => ui.update()
    None => ()
  }
}

///|
fn poll_npc_talk_resource() -> Unit {
  guard npc_talk_resource_ref.val is None else { return }
  guard npc_talk_loading_ref.val is Some(future) else { return }
  match future.poll() {
    Some(Ok(resource)) => {
      npc_talk_loading_ref.val = None
      npc_talk_resource_ref.val = Some(resource)
    }
    Some(Err(err)) => {
      npc_talk_loading_ref.val = None
      npc_talk_pending_args_ref.val = None
      @log.error("failed to load npc talk resource", data={
        "error": err.to_string(),
      })
    }
    None => ()
  }
}

///|
fn poll_npc_talk_open_request() -> Unit {
  guard npc_talk_ui_ref.val is None else { return }
  guard npc_talk_pending_args_ref.val is Some(args) else { return }
  guard npc_talk_resource_ref.val is Some(resource) else { return }
  let content = convert_npc_text(args.str) catch {
    err => {
      npc_talk_pending_args_ref.val = None
      @log.error("failed to parse npc talk text", data={
        "error": err.to_string(),
      })
      return
    }
  }
  npc_talk_pending_args_ref.val = None
  let ui = UINpcTalk::new(resource, args, content)
  ui.rebuild_scene()
  npc_talk_ui_ref.val = Some(ui)
}

///|
fn UINpcTalk::new(
  resource : NpcTalkResource,
  args : TalkArgs,
  content : NPCTalkContent,
) -> UINpcTalk {
  {
    resource,
    args,
    content,
    entities: [],
    buttons: [],
    selection_buttons: [],
    click_reader: @event.EventReader::new(),
    window_pos: Point::default(),
    body_height: FIXED_BODY_HEIGHT,
  }
}

///|
fn UINpcTalk::destroy(self : UINpcTalk) -> Unit {
  self.buttons.clear()
  self.selection_buttons.clear()
  for entity in self.entities {
    entity.destroy()
  }
  self.entities.clear()
}

///|
fn UINpcTalk::rebuild_scene(self : UINpcTalk) -> Unit {
  self.destroy()
  self.body_height = self.measure_body_height()
  self.window_pos = Point::new(
    400 - self.resource.top.w / 2,
    240 - self.body_height / 2,
  )
  self.spawn_window()
  self.spawn_nameplate()
  self.spawn_body_text()
  self.spawn_action_buttons()
}

///|
fn UINpcTalk::measure_body_height(self : UINpcTalk) -> Int {
  ignore(self)
  FIXED_BODY_HEIGHT
}

///|
fn UINpcTalk::spawn_window(self : UINpcTalk) -> Unit {
  let fill_height = self.body_height
  ignore(
    self.spawn_image_node(
      self.resource.top,
      self.window_pos.x,
      self.window_pos.y,
      NPC_TALK_Z,
    ),
  )
  ignore(
    self.spawn_image_node(
      self.resource.fill,
      self.window_pos.x,
      self.window_pos.y + self.resource.top.h,
      NPC_TALK_Z,
      fit=@selene_ui.ImageFit::Stretch,
      width=self.resource.fill.w,
      height=fill_height,
    ),
  )
  ignore(
    self.spawn_image_node(
      self.resource.bottom,
      self.window_pos.x,
      self.window_pos.y + self.resource.top.h + fill_height,
      NPC_TALK_Z,
    ),
  )
}

///|
fn UINpcTalk::spawn_nameplate(self : UINpcTalk) -> Unit {
  let speaker_y = (
      self.resource.top.h + self.body_height + self.resource.bottom.h
    ) /
    2
  let speaker_pos = self.window_pos + Point::new(100, 11 + speaker_y)
  ignore(
    self.spawn_image_node(
      self.resource.bar,
      speaker_pos.x,
      speaker_pos.y,
      NPC_TALK_Z + 2,
    ),
  )
}

///|
fn UINpcTalk::spawn_body_text(self : UINpcTalk) -> Unit {
  let x = self.window_pos.x + CONTENT_X
  let y = self.window_pos.y + CONTENT_Y
  let width = self.content_width()
  let total_height = @cmp.maximum(1, self.body_height - 10)
  let selection_count = self.content.selections.length()
  let selection_gap_total = if selection_count <= 1 {
    0
  } else {
    (selection_count - 1) * LINE_GAP
  }
  let selection_slot_height = if selection_count == 0 {
    0
  } else {
    @cmp.maximum(
      16,
      total_height / @cmp.maximum(1, selection_count + 1) - LINE_GAP,
    )
  }
  let selection_total_height = if selection_count == 0 {
    0
  } else {
    selection_slot_height * selection_count + selection_gap_total
  }
  let body_height = @cmp.maximum(1, total_height - selection_total_height)
  ignore(
    self.spawn_rich_text_block(
      flatten_text_lines(self.content.body_lines),
      x,
      y,
      width,
      body_height,
      NPC_TALK_Z + 4,
    ),
  )
  let selection_start_gap = if selection_count == 0 { 0 } else { LINE_GAP }
  let mut selection_y = y + body_height + selection_start_gap
  for selection in self.content.selections {
    let entity = self.spawn_rich_text_block(
      flatten_text_lines(selection.lines),
      x,
      selection_y,
      width,
      selection_slot_height,
      NPC_TALK_Z + 5,
      clickable=true,
    )
    self.selection_buttons.push({ entity, option: selection.option })
    selection_y += selection_slot_height + LINE_GAP
  }
}

///|
fn UINpcTalk::spawn_action_buttons(self : UINpcTalk) -> Unit {
  let y = self.window_pos.y + self.body_height + 48
  let close_x = self.window_pos.x + 9
  fn spawn_callback(
    button : NpcTalkButtonResource,
    x : Int,
    y : Int,
    callback,
  ) {
    ignore(self.spawn_action_button(button, x, y, callback))
  }
  match self.args.talk_action {
    SEND_YESNO(callback) => {
      spawn_callback(self.resource.bt_yes, self.window_pos.x + 389, y, fn() {
        close_npc_talk_ui()
        callback(Some(true))
      })
      spawn_callback(self.resource.bt_no, self.window_pos.x + 461, y, fn() {
        close_npc_talk_ui()
        callback(Some(false))
      })
      spawn_callback(self.resource.bt_close, close_x, y, fn() {
        close_npc_talk_ui()
        callback(None)
      })
    }
    SEND_NEXT(callback) => {
      spawn_callback(self.resource.bt_next, self.window_pos.x + 461, y - 30, fn() {
        close_npc_talk_ui()
        callback(Some(()))
      })
      spawn_callback(self.resource.bt_close, close_x, y, fn() {
        close_npc_talk_ui()
        callback(None)
      })
    }
    SEND_PREV(callback) => {
      spawn_callback(self.resource.bt_prev, self.window_pos.x + 367, y - 30, fn() {
        close_npc_talk_ui()
        callback(Some(()))
      })
      spawn_callback(self.resource.bt_close, close_x, y, fn() {
        close_npc_talk_ui()
        callback(None)
      })
    }
    SEND_NEXT_PREV(callback) => {
      spawn_callback(self.resource.bt_prev, self.window_pos.x + 367, y - 30, fn() {
        close_npc_talk_ui()
        callback(Some(false))
      })
      spawn_callback(self.resource.bt_next, self.window_pos.x + 461, y - 30, fn() {
        close_npc_talk_ui()
        callback(Some(true))
      })
      spawn_callback(self.resource.bt_close, close_x, y, fn() {
        close_npc_talk_ui()
        callback(None)
      })
    }
    SEND_OK(callback) => {
      spawn_callback(self.resource.bt_ok, self.window_pos.x + 469, y, fn() {
        close_npc_talk_ui()
        callback(Some(()))
      })
      spawn_callback(self.resource.bt_close, close_x, y, fn() {
        close_npc_talk_ui()
        callback(None)
      })
    }
    SEND_SIMPLE(callback) =>
      spawn_callback(self.resource.bt_close, close_x, y, fn() {
        close_npc_talk_ui()
        callback(None)
      })
  }
}

///|
fn ui_image_from_texture(
  texture : @resource.NxTexture,
  fit? : @selene_ui.ImageFit = @selene_ui.ImageFit::None,
) -> @selene_ui.UiImage {
  @selene_ui.UiImage::new(
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    texture.i,
    fit~,
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
fn UINpcTalk::set_image_texture(
  self : UINpcTalk,
  entity : @entity.Entity,
  texture : @resource.NxTexture,
  fit? : @selene_ui.ImageFit = @selene_ui.ImageFit::None,
) -> Unit {
  ignore(self)
  @selene_ui.ui_images().set(entity, ui_image_from_texture(texture, fit~))
  @selene_ui.ui_image_regions().set(
    entity,
    ui_image_region_from_texture(texture),
  )
}

///|
fn UINpcTalk::spawn_image_node(
  self : UINpcTalk,
  texture : @resource.NxTexture,
  x : Int,
  y : Int,
  z : Int,
  fit? : @selene_ui.ImageFit = @selene_ui.ImageFit::None,
  width? : Int = texture.w,
  height? : Int = texture.h,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  self.entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(x.to_double(), y.to_double()),
      size=@selene_math.Vec2D(width.to_double(), height.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  self.set_image_texture(entity, texture, fit~)
  entity
}

///|
fn UINpcTalk::spawn_action_button(
  self : UINpcTalk,
  resource : NpcTalkButtonResource,
  x : Int,
  y : Int,
  on_click : () -> Unit,
) -> Unit {
  let entity = self.spawn_image_node(resource.normal, x, y, NPC_TALK_Z + 8)
  @selene_ui.buttons().set(entity, @selene_ui.Button::new())
  self.buttons.push({ resource, entity, enabled: true, on_click })
}

///|
fn UINpcTalk::update(self : UINpcTalk) -> Unit {
  for button in self.buttons {
    let texture = if not(button.enabled) {
      button.resource.disabled
    } else {
      match @selene_ui.interactions().get(button.entity) {
        Some(@selene_ui.Interaction::Pressed) => button.resource.pressed
        Some(@selene_ui.Interaction::Hovered) => button.resource.mouse_over
        _ => button.resource.normal
      }
    }
    self.set_image_texture(button.entity, texture)
  }
  let click_events = @selene_ui.click_event_bus.read(self.click_reader)
  for event in click_events {
    guard event.button is @inputs.MouseButton::Left else { continue }
    let mut handled = false
    for button in self.buttons {
      if button.entity == event.entity {
        handled = true
        (button.on_click)()
        break
      }
    }
    if handled {
      continue
    }
    guard self.args.talk_action is SEND_SIMPLE(callback) else { continue }
    match self.selection_button_option(event.entity) {
      Some(option) => {
        close_npc_talk_ui()
        callback(Some(option))
      }
      None => ()
    }
  }
}

///|
fn UINpcTalk::content_width(self : UINpcTalk) -> Int {
  @cmp.maximum(1, self.resource.top.w - CONTENT_X - CONTENT_RIGHT_PADDING)
}

///|
fn UINpcTalk::selection_button_option(
  self : UINpcTalk,
  entity : @entity.Entity,
) -> Int? {
  for button in self.selection_buttons {
    if button.entity == entity {
      return Some(button.option)
    }
  }
  None
}

///|
fn flatten_text_lines(lines : Array[Array[TextRun]]) -> Array[TextRun] {
  let flattened : Array[TextRun] = []
  for i, line in lines {
    for run in line {
      flattened.push(run)
    }
    if i + 1 < lines.length() {
      flattened.push(TextRun::{
        text: "\n",
        color: ColorName::BLACK,
        bold: false,
        underline: false,
      })
    }
  }
  flattened
}

///|
fn set_text_style(entity : @entity.Entity, run : TextRun) -> Unit {
  @selene_ui.text_fonts().set(
    entity,
    @selene_ui.TextFont::new(family="Menlo", size=13.0, bold=run.bold),
  )
  @selene_ui.text_colors().set(
    entity,
    @selene_ui.TextColor::from_css(run.color.css_name()),
  )
  if run.underline {
    @selene_ui.underlines().set(entity, @selene_ui.Underline::new())
    @selene_ui.underline_colors().set(
      entity,
      @selene_ui.UnderlineColor::new(
        @selene_ui.parse_color(run.color.css_name()),
      ),
    )
  }
}

///|
fn UINpcTalk::spawn_rich_text_block(
  self : UINpcTalk,
  runs : Array[TextRun],
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  z : Int,
  clickable? : Bool = false,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  self.entities.push(entity)
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
      line_height=TEXT_LINE_HEIGHT,
      wrap=@selene_ui.TextWrap::WordWrap,
      overflow=@selene_ui.TextOverflow::Clip,
    ),
  )
  if clickable {
    @selene_ui.buttons().set(entity, @selene_ui.Button::new())
  }
  let first = runs
    .get(0)
    .unwrap_or(TextRun::{
      text: "",
      color: ColorName::BLACK,
      bold: false,
      underline: false,
    })
  @selene_ui.texts().set(entity, @selene_ui.Text::new(first.text))
  set_text_style(entity, first)
  for i in 1..<runs.length() {
    let run = runs[i]
    let child = entity.spawn_child()
    @selene_ui.text_spans().set(child, @selene_ui.TextSpan::new(run.text))
    set_text_style(child, run)
  }
  entity
}

///|
fn convert_npc_text(raw_text : String) -> NPCTalkContent raise {
  let tag_replace_map : Map[
    Char,
    (@markup_text.Style, StringView) -> Array[TextRun] raise,
  ] = {
    'o': (style, value) => {
      resolve_reference(style, value, v => @markup_text.resolve_mob_name(v))
    },
    'p': (style, value) => {
      resolve_reference(style, value, v => @markup_text.resolve_npc_name(v))
    },
    'm': (style, value) => {
      resolve_reference(style, value, v => @markup_text.resolve_map_name(v))
    },
    't': (style, value) => {
      resolve_reference(style, value, v => @markup_text.resolve_item_name(v))
    },
    'h': fn(style, _value) {
      [
        TextRun::{
          text: current_player_name(),
          color: style.color,
          bold: style.bold,
          underline: style.underline,
        },
      ]
    },
  }
  let selections = []
  let body_lines = [[]]
  let mut opening_selection : (Int, Array[@markup_text.Node])? = None
  let mut trim_newline = false
  let mut current_style : @markup_text.Style = {
    color: ColorName::BLACK,
    bold: false,
    underline: false,
  }
  let nodes = @markup_text.parse_markup(raw_text, tag_map)
  for node in nodes {
    match node {
      Text(text) => {
        if opening_selection is Some((_, selection_nodes)) {
          selection_nodes.push(node)
          continue
        }
        let normalized = if trim_newline &&
          (text.to_string() == "\r\n" || text.to_string() == "\n") {
          ""
        } else {
          text.to_string()
        }
        trim_newline = false
        append_runs_to_lines(
          body_lines,
          text_runs_for_text(normalized, current_style),
        )
      }
      Tag('L', payload) => {
        if opening_selection is Some((index, selection_nodes)) {
          selections.push({
            option: index,
            lines: trim_trailing_blank_lines(
              build_runs_from_nodes(
                selection_nodes,
                current_style,
                tag_replace_map,
                trim_end_newline=true,
              ),
            ),
          })
        }
        opening_selection = Some((@strconv.parse_int(payload.to_string()), []))
      }
      Tag('l', _) => {
        guard opening_selection is Some((index, selection_nodes)) else {
          raise ParseTalkError("selection close without open")
        }
        opening_selection = None
        selections.push({
          option: index,
          lines: trim_trailing_blank_lines(
            build_runs_from_nodes(
              selection_nodes, current_style, tag_replace_map,
            ),
          ),
        })
        trim_newline = true
      }
      Tag(tag, payload) => {
        if opening_selection is Some((_, selection_nodes)) {
          selection_nodes.push(node)
          continue
        }
        current_style = apply_style_or_append_runs(
          body_lines, current_style, tag, payload, tag_replace_map,
        )
      }
    }
  }
  if opening_selection is Some((index, selection_nodes)) {
    selections.push({
      option: index,
      lines: trim_trailing_blank_lines(
        build_runs_from_nodes(
          selection_nodes,
          current_style,
          tag_replace_map,
          trim_end_newline=true,
        ),
      ),
    })
  }
  { body_lines: trim_trailing_blank_lines(body_lines), selections }
}

///|
fn apply_style_or_append_runs(
  body_lines : Array[Array[TextRun]],
  current_style : @markup_text.Style,
  tag : Char,
  payload : StringView,
  tag_replace_map : Map[
    Char,
    (@markup_text.Style, StringView) -> Array[TextRun] raise,
  ],
) -> @markup_text.Style raise {
  if @markup_text.font_weight_tag_map.get(tag) is Some(bold) {
    { ..current_style, bold, }
  } else if @markup_text.underline_tag_map.get(tag) is Some(underline) {
    { ..current_style, underline, }
  } else if @markup_text.color_map.get(tag) is Some(color) {
    { ..current_style, color, }
  } else {
    match tag_replace_map.get(tag) {
      Some(replace) => {
        append_runs_to_lines(body_lines, replace(current_style, payload))
        current_style
      }
      None =>
        // TODO: richer Maple-specific text effects are not implemented yet for sprite.Text.
        current_style
    }
  }
}

///|
fn build_runs_from_nodes(
  nodes : Array[@markup_text.Node],
  style : @markup_text.Style,
  tag_replace_map : Map[
    Char,
    (@markup_text.Style, StringView) -> Array[TextRun] raise,
  ],
  trim_end_newline? : Bool = false,
) -> Array[Array[TextRun]] raise {
  let lines = [[]]
  let mut current_style = style
  for i, node in nodes {
    match node {
      Text(text) => {
        let mut raw = text.to_string()
        if trim_end_newline && i == nodes.length() - 1 {
          raw = raw.trim_end(chars="\n").to_string()
        }
        append_runs_to_lines(lines, text_runs_for_text(raw, current_style))
      }
      Tag(tag, payload) =>
        current_style = apply_style_or_append_runs(
          lines, current_style, tag, payload, tag_replace_map,
        )
    }
  }
  lines
}

///|
fn resolve_reference(
  style : @markup_text.Style,
  value : StringView,
  provider : (StringView) -> String raise,
) -> Array[TextRun] raise {
  [
    TextRun::{
      text: provider(value),
      color: style.color,
      bold: style.bold,
      underline: style.underline,
    },
  ]
}

///|
fn text_runs_for_text(
  raw_text : String,
  style : @markup_text.Style,
) -> Array[TextRun] {
  if raw_text.is_empty() {
    return []
  }
  [
    TextRun::{
      text: raw_text,
      color: style.color,
      bold: style.bold,
      underline: style.underline,
    },
  ]
}

///|
fn append_runs_to_lines(
  lines : Array[Array[TextRun]],
  runs : Array[TextRun],
) -> Unit {
  for run in runs {
    let parts = run.text
      .replace_all(old="\r\n", new="\n")
      .split("\n")
      .to_array()
    for i, part in parts {
      if not(part.is_empty()) {
        let line = lines[lines.length() - 1]
        line.push({ ..run, text: part.to_string() })
      }
      if i + 1 < parts.length() {
        lines.push([])
      }
    }
  }
}

///|
fn trim_trailing_blank_lines(
  lines : Array[Array[TextRun]],
) -> Array[Array[TextRun]] {
  let trimmed = lines.copy()
  while not(trimmed.is_empty()) && trimmed.last().unwrap_or([]).is_empty() {
    trimmed.pop() |> ignore
  }
  if trimmed.is_empty() {
    [[]]
  } else {
    trimmed
  }
}

///|
let tag_map : Map[Char, @markup_text.MarkupType] = @markup_text.common_tags
  .iter()
  .concat(
    [
      ('L', @markup_text.MarkupType::Pair),
      ('l', @markup_text.MarkupType::SelfClosing),
    ].iter(),
  )
  |> Map::from_iter

///|
pub(all) suberror ParseTalkError {
  ParseTalkError(String)
} derive(Show)

///|
using @struct {type ColorName, type Point}
