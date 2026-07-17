///|
using @npc {type TalkArgs}

///|
pub(all) struct NpcTalkResource {
  window_slice : @ui.UiSliceResource
  bar : @res.NxTexture
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
  normal : @res.NxTexture
  mouse_over : @res.NxTexture
  pressed : @res.NxTexture
  disabled : @res.NxTexture
}

///|
fn json_to_texture(json : Json) -> @res.NxTexture raise {
  @json.from_json(json)
}

///|
fn first_frame_texture(
  animation : @res.NxAnimation,
  label : String,
) -> @res.NxTexture raise {
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
  window_slice : @ui.UiSliceResource,
) -> NpcTalkResource raise {
  match util_dlg_ex {
    {
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
        window_slice,
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
priv struct NpcTalkSpeakerResource {
  npc_id : Int
  name : String
  portrait_material : @selene_ui.UiMaterialHandle
  image_path : String
  source_x : Int
  source_y : Int
  width : Int
  height : Int
  pivot_x : Int
  pivot_y : Int
}

///|
priv struct NpcTalkSpeakerLayout {
  portrait_x : Int
  portrait_y : Int
  portrait_width : Int
  portrait_height : Int
  bar_x : Int
  bar_y : Int
  bar_width : Int
  bar_height : Int
}

///|
priv struct UINpcTalk {
  resource : NpcTalkResource
  args : TalkArgs
  content : NPCTalkContent
  speaker : NpcTalkSpeakerResource?
  entities : Array[@entity.Entity]
  buttons : Array[ActionButton]
  selection_buttons : Array[SelectionButton]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
  navigation_reader : @event.EventReader[@selene_ui.UiNavigationEvent]
  mut window_pos : Point[Int]
  mut body_height : Int
  mut speaker_layout : NpcTalkSpeakerLayout?
}

///|
const NPC_TALK_Z : Int = @graphics.UI_ZINDEX + 100

///|
const NPC_TALK_INPUT_OWNER : String = "npc_talk"

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
let npc_talk_ui_ref : Ref[UINpcTalk?] = Ref(None)

///|
let npc_talk_resource_ref : Ref[NpcTalkResource?] = Ref(None)

///|
let npc_talk_speaker_cache : Map[Int, NpcTalkSpeakerResource] = Map([])

///|
let npc_talk_loading_ref : Ref[@utils.Future[Result[NpcTalkResource, Error]]?] = Ref(
  None,
)

///|
let npc_talk_pending_args_ref : Ref[TalkArgs?] = Ref(None)

///|
fn init {
  @console.register_state_section("npc_talk", describe_npc_talk_ui)
  @console.register_command("npc_talk_select", fn(args) {
    guard !args.is_empty() else {
      return { "ok": false, "code": "INVALID_ARGUMENTS" }
    }
    let option = @string.parse_int(args[0]) catch {
      _ => return { "ok": false, "code": "INVALID_OPTION" }
    }
    guard npc_talk_ui_ref.val is Some(ui) else {
      return { "ok": false, "code": "NPC_TALK_NOT_OPEN" }
    }
    match ui.args.talk_action {
      SEND_SIMPLE(callback) => {
        if option == -1 {
          close_npc_talk_ui()
          callback(None)
          return { "ok": true, "code": "DIALOGUE_CLOSED" }
        }
        for button in ui.selection_buttons {
          guard button.option == option else { continue }
          close_npc_talk_ui()
          callback(Some(option))
          return { "ok": true, "code": "SELECTION_SENT", "option": option }
        }
        { "ok": false, "code": "OPTION_NOT_FOUND", "option": option }
      }
      SEND_YESNO(callback) => {
        guard option == 1 || option == 0 || option == -1 else {
          return { "ok": false, "code": "INVALID_DIALOGUE_RESPONSE" }
        }
        close_npc_talk_ui()
        callback(
          if option == 1 {
            Some(true)
          } else if option == 0 {
            Some(false)
          } else {
            None
          },
        )
        { "ok": true, "code": "DIALOGUE_RESPONSE_SENT", "option": option }
      }
      SEND_NEXT(callback) | SEND_OK(callback) => {
        guard option == 1 || option == -1 else {
          return { "ok": false, "code": "INVALID_DIALOGUE_RESPONSE" }
        }
        close_npc_talk_ui()
        callback(if option == 1 { Some(()) } else { None })
        { "ok": true, "code": "DIALOGUE_RESPONSE_SENT", "option": option }
      }
      SEND_NEXT_PREV(callback) => {
        guard option == 1 || option == 0 || option == -1 else {
          return { "ok": false, "code": "INVALID_DIALOGUE_RESPONSE" }
        }
        close_npc_talk_ui()
        callback(
          if option == 1 {
            Some(true)
          } else if option == 0 {
            Some(false)
          } else {
            None
          },
        )
        { "ok": true, "code": "DIALOGUE_RESPONSE_SENT", "option": option }
      }
      SEND_PREV(callback) => {
        guard option == 0 || option == -1 else {
          return { "ok": false, "code": "INVALID_DIALOGUE_RESPONSE" }
        }
        close_npc_talk_ui()
        callback(if option == 0 { Some(()) } else { None })
        { "ok": true, "code": "DIALOGUE_RESPONSE_SENT", "option": option }
      }
    }
  })
}

///|
fn current_player_name() -> String {
  if @player.get_player() is Some(player) {
    let name = player.get_stats().get_name()
    if !name.is_empty() {
      return name
    }
  }
  "Player"
}

///|
fn load_npc_talk_resource() -> NpcTalkResource {
  let src : Json = @res.require_json("res://UI/UIWindow2.img/UtilDlgEx.json")
  let window_slice = @ui.load_ui_slice_resource(
    "res://UI/UIWindow2.img/UtilDlgEx/slice.json",
  )
  ignore(@game_ui_font.load())
  NpcTalkResource::from_resource(src, window_slice) catch {
    _ => abort("invalid UtilDlgEx NPC talk resource")
  }
}

///|
fn load_npc_talk_speaker_resource(npc_id : Int) -> NpcTalkSpeakerResource raise {
  if npc_talk_speaker_cache.get(npc_id) is Some(cached) {
    return cached
  }
  let npc_key = npc_id.to_string()
  let npc_path = @utils.stoi_left_pad0(npc_id, 7) + ".img"
  let mut mx_path = "res://Npc/" + npc_path + "/mx.json"
  let mut mx_source = @res.load_json(mx_path)
  match mx_source {
    { "info": { "link": String(link), .. }, .. } => {
      mx_path = "res://Npc/" + link + ".img/mx.json"
      mx_source = @res.load_json(mx_path)
    }
    _ => ()
  }
  guard mx_source is { "animations_path": String(animations_ref), .. } else {
    fail("npc \{npc_id} resource has no animations_path")
  }
  let animations_path = @res.resolve_ref(mx_path, animations_ref)
  let animations = @res.load_json(animations_path)
  guard animations
    is {
      "frames": Array(frames),
      "meta": {
        "image": String(image_ref),
        "frameTags": Array(tags),
        "slices": Array(slices),
        ..
      },
      ..
    } else {
    fail("npc \{npc_id} animation is missing frames or metadata")
  }
  let mut stand_frame_index : Int? = None
  for tag in tags {
    if tag
      is {
        "name": "stand",
        "from": Number(first, ..),
        "direction": "forward",
        ..
      } {
      stand_frame_index = Some(first.to_int())
      break
    }
  }
  guard stand_frame_index is Some(frame_index) &&
    frames.get(frame_index)
    is Some(
      {
        "frame": {
          "x": Number(source_x, ..),
          "y": Number(source_y, ..),
          "w": Number(width, ..),
          "h": Number(height, ..),
          ..
        },
        "spriteSourceSize": {
          "x": Number(sprite_x, ..),
          "y": Number(sprite_y, ..),
          ..
        },
        ..
      }
    ) else {
    fail("npc \{npc_id} animation has no valid stand frame")
  }
  let mut pivot : (Int, Int)? = None
  for slice in slices {
    if slice
      is {
        "name": "anchor_stand",
        "keys": [
          {
            "bounds": {
              "x": Number(bounds_x, ..),
              "y": Number(bounds_y, ..),
              ..
            },
            "pivot": { "x": Number(pivot_x, ..), "y": Number(pivot_y, ..), .. },
            ..
          },
          ..,
        ],
        ..
      } {
      pivot = Some(
        (
          pivot_x.to_int() - (sprite_x.to_int() - bounds_x.to_int()),
          pivot_y.to_int() - (sprite_y.to_int() - bounds_y.to_int()),
        ),
      )
      break
    }
  }
  guard pivot is Some((pivot_x, pivot_y)) else {
    fail("npc \{npc_id} animation has no anchor_stand pivot")
  }
  let npc_strings = @res.load_json("res://String/Npc.img.json")
  guard npc_strings is Object(entries) &&
    entries.get(npc_key) is Some({ "name": String(name), .. }) else {
    fail("npc \{npc_id} has no display name")
  }
  let image_path = @res.resolve_ref(animations_path, image_ref)
  let image = @res.require_image(image_path)
  let source : @render2d_types.ImageRegion2D = {
    position: @selene_math.Vec2(source_x, source_y),
    size: @selene_math.Vec2(width, height),
  }
  let portrait_material = @selene_ui.register_ui_material_asset(
    @selene_ui.UiMaterialAsset::from_draw(fn(context) {
      @render2d.push_ui_image_to_camera(context.target_camera_entity_id, {
        image,
        destination: context.rect,
        source: Some(source),
        transform: @selene_math.Transform::flip_x(
          context.rect.size[@selene_math.X],
        ),
        uv_transform: @selene_math.Transform::identity(),
        repeat: @selene_math.NoRepeat,
        alpha_mode: @render.AlphaMode2D::Blend,
        blend_mode: @render.BlendMode2D::Alpha,
        color: @selene_ui.rgba(255, 255, 255, 1.0),
      })
    }),
  )
  let loaded = {
    npc_id,
    name,
    portrait_material,
    image_path,
    source_x: source_x.to_int(),
    source_y: source_y.to_int(),
    width: width.to_int(),
    height: height.to_int(),
    pivot_x,
    pivot_y,
  }
  npc_talk_speaker_cache.set(npc_id, loaded)
  loaded
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
      if !has_z {
        z_min = NPC_TALK_Z
        z_max = NPC_TALK_Z
      }
      let window_w = ui.resource.window_slice.width
      let window_h = ui.resource.window_slice.top +
        ui.body_height +
        ui.resource.window_slice.bottom
      let window_left = ui.window_pos.x
      let window_top = ui.window_pos.y
      let window_right = window_left + window_w
      let window_bottom = window_top + window_h
      let body_lines : Array[Json] = ui.content.body_lines.map(fn(line) {
        line.map(fn(run) { run.text }).join("").to_json()
      })
      let action = match ui.args.talk_action {
        SEND_YESNO(_) => "yes_no"
        SEND_SIMPLE(_) => "simple"
        SEND_OK(_) => "ok"
        SEND_NEXT(_) => "next"
        SEND_NEXT_PREV(_) => "next_previous"
        SEND_PREV(_) => "previous"
      }
      let selections : Array[Json] = ui.content.selections.map(fn(selection) {
        {
          "option": selection.option.to_json(),
          "text": selection.lines
          .map(fn(line) { line.map(fn(run) { run.text }).join("") })
          .join("\n")
          .to_json(),
        }
      })
      let speaker_json : Json = match (ui.speaker, ui.speaker_layout) {
        (Some(speaker), Some(layout)) =>
          {
            "npc_id": speaker.npc_id.to_json(),
            "name": speaker.name.to_json(),
            "portrait_source": {
              "path": speaker.image_path.to_json(),
              "x": speaker.source_x.to_json(),
              "y": speaker.source_y.to_json(),
              "w": speaker.width.to_json(),
              "h": speaker.height.to_json(),
            },
            "portrait_rect": {
              "left": layout.portrait_x.to_json(),
              "top": layout.portrait_y.to_json(),
              "right": (layout.portrait_x + layout.portrait_width).to_json(),
              "bottom": (layout.portrait_y + layout.portrait_height).to_json(),
            },
            "bar_rect": {
              "left": layout.bar_x.to_json(),
              "top": layout.bar_y.to_json(),
              "right": (layout.bar_x + layout.bar_width).to_json(),
              "bottom": (layout.bar_y + layout.bar_height).to_json(),
            },
          }
        _ => Json::null()
      }
      {
        "open": true,
        "action": action,
        "body_lines": body_lines,
        "selections": selections.to_json(),
        "speaker": speaker_json,
        "font": {
          "address": @game_ui_font.ADDRESS,
          "family": @game_ui_font.FAMILY,
          "size": @game_ui_font.SIZE,
        },
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
  @keymap.set_gameplay_input_suppressed(NPC_TALK_INPUT_OWNER, false)
  npc_talk_pending_args_ref.val = None
  match npc_talk_ui_ref.val {
    Some(ui) => {
      if @selene_ui.focused_entity() is Some(focused) {
        for entity in ui.entities {
          if entity == focused {
            @selene_ui.blur()
            break
          }
        }
      }
      ui.destroy()
      npc_talk_ui_ref.val = None
    }
    None => ()
  }
}

///|
pub fn open_npc_talk_ui(args : TalkArgs) -> Unit {
  close_npc_talk_ui()
  @keymap.set_gameplay_input_suppressed(NPC_TALK_INPUT_OWNER, true)
  if npc_talk_resource_ref.val is None && npc_talk_loading_ref.val is None {
    npc_talk_loading_ref.val = Some(
      @io_service.submit_background_task(fn() { load_npc_talk_resource() }),
    )
  }
  npc_talk_pending_args_ref.val = Some(args)
}

///|
fn cancel_npc_talk(args : TalkArgs) -> Unit {
  close_npc_talk_ui()
  match args.talk_action {
    SEND_YESNO(callback) => callback(None)
    SEND_SIMPLE(callback) => callback(None)
    SEND_OK(callback) | SEND_NEXT(callback) | SEND_PREV(callback) =>
      callback(None)
    SEND_NEXT_PREV(callback) => callback(None)
  }
}

///|
pub fn npc_talk_ui_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase() is @game_state.GamePhase::GameActive(..) else {
    close_npc_talk_ui()
    return
  }
  if @keymap.is_just_pressed(@keymap.Action::UI(@keymap.UiActionId::CANCEL)) {
    match npc_talk_ui_ref.val {
      Some(ui) => {
        cancel_npc_talk(ui.args)
        return
      }
      None =>
        match npc_talk_pending_args_ref.val {
          Some(args) => {
            cancel_npc_talk(args)
            return
          }
          None => ()
        }
    }
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
      @keymap.set_gameplay_input_suppressed(NPC_TALK_INPUT_OWNER, false)
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
  let speaker = match args.speaker {
    @npc.Speaker::NPC_LEFT =>
      Some(load_npc_talk_speaker_resource(args.npc_id)) catch {
        err => {
          npc_talk_pending_args_ref.val = None
          @keymap.set_gameplay_input_suppressed(NPC_TALK_INPUT_OWNER, false)
          @log.error("failed to load npc talk speaker", data={
            "npc_id": args.npc_id,
            "error": err.to_string(),
          })
          return
        }
      }
    _ => None
  }
  let content = convert_npc_text(args.str) catch {
    err => {
      npc_talk_pending_args_ref.val = None
      @keymap.set_gameplay_input_suppressed(NPC_TALK_INPUT_OWNER, false)
      @log.error("failed to parse npc talk text", data={
        "error": err.to_string(),
      })
      return
    }
  }
  npc_talk_pending_args_ref.val = None
  let ui = UINpcTalk(resource, args, content, speaker)
  ui.rebuild_scene()
  if @keymap.active_input_method() is @keymap.InputMethod::Gamepad(_) {
    if !ui.selection_buttons.is_empty() {
      @selene_ui.focus(ui.selection_buttons[0].entity)
    } else if !ui.buttons.is_empty() {
      @selene_ui.focus(ui.buttons[0].entity)
    }
  }
  npc_talk_ui_ref.val = Some(ui)
}

///|
fn UINpcTalk::UINpcTalk(
  resource : NpcTalkResource,
  args : TalkArgs,
  content : NPCTalkContent,
  speaker : NpcTalkSpeakerResource?,
) -> UINpcTalk {
  {
    resource,
    args,
    content,
    speaker,
    entities: [],
    buttons: [],
    selection_buttons: [],
    click_reader: @event.EventReader(),
    navigation_reader: @event.EventReader(),
    window_pos: Default::default(),
    body_height: FIXED_BODY_HEIGHT,
    speaker_layout: None,
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
  self.speaker_layout = None
  self.body_height = self.measure_body_height()
  self.window_pos = Point(
    400 - self.resource.window_slice.width / 2,
    240 - self.body_height / 2,
  )
  self.spawn_window()
  self.spawn_speaker()
  self.spawn_body_text()
  self.spawn_action_buttons()
}

///|
fn UINpcTalk::measure_body_height(self : UINpcTalk) -> Int {
  let body_line_count = @cmp.maximum(1, self.content.body_lines.length())
  let selection_line_count = self.content.selections.fold(init=0, fn(
    acc,
    selection,
  ) {
    acc + @cmp.maximum(1, selection.lines.length())
  })
  let selection_count = self.content.selections.length()
  let line_pixel_height = 17
  let selection_gap_total = if selection_count <= 1 {
    0
  } else {
    (selection_count - 1) * LINE_GAP
  }
  let selection_start_gap = if selection_count == 0 { 0 } else { LINE_GAP }
  let needed = (body_line_count + selection_line_count) * line_pixel_height +
    selection_gap_total +
    selection_start_gap +
    10
  @cmp.maximum(FIXED_BODY_HEIGHT, needed)
}

///|
fn UINpcTalk::spawn_window(self : UINpcTalk) -> Unit {
  let window_height = self.resource.window_slice.top +
    self.body_height +
    self.resource.window_slice.bottom
  ignore(
    self.spawn_material_node(
      self.resource.window_slice.material,
      self.window_pos.x,
      self.window_pos.y,
      self.resource.window_slice.width,
      window_height,
      NPC_TALK_Z,
    ),
  )
}

///|
fn UINpcTalk::spawn_speaker(self : UINpcTalk) -> Unit {
  guard self.speaker is Some(speaker) else { return }
  let window_height = self.resource.window_slice.top +
    self.body_height +
    self.resource.window_slice.bottom
  let bar_x = self.window_pos.x + 22
  let bar_y = self.window_pos.y + 11 + window_height / 2
  let portrait_center_x = bar_x + self.resource.bar.w / 2
  let portrait_x = portrait_center_x - (speaker.width - speaker.pivot_x)
  let portrait_y = bar_y - speaker.pivot_y
  ignore(
    self.spawn_material_node(
      speaker.portrait_material,
      portrait_x,
      portrait_y,
      speaker.width,
      speaker.height,
      NPC_TALK_Z + 2,
    ),
  )
  ignore(self.spawn_image_node(self.resource.bar, bar_x, bar_y, NPC_TALK_Z + 3))
  let name_entity = @entity.Entity()
  self.entities.push(name_entity)
  @selene_ui.nodes().set(
    name_entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(bar_x.to_double(), bar_y.to_double()),
      size=@selene_math.Vec2(
        self.resource.bar.w.to_double(),
        self.resource.bar.h.to_double(),
      ),
    ),
  )
  @selene_ui.z_indexes().set(name_entity, @selene_ui.ZIndex(NPC_TALK_Z + 4))
  @selene_ui.texts().set(name_entity, @selene_ui.Text(speaker.name))
  @selene_ui.text_fonts().set(name_entity, @game_ui_font.text_font())
  @selene_ui.text_colors().set(
    name_entity,
    @selene_ui.TextColor::from_css("white"),
  )
  @selene_ui.text_layouts().set(
    name_entity,
    @selene_ui.TextLayout(
      align=@selene_math.Center,
      baseline=@selene_math.Center,
    ),
  )
  self.speaker_layout = Some({
    portrait_x,
    portrait_y,
    portrait_width: speaker.width,
    portrait_height: speaker.height,
    bar_x,
    bar_y,
    bar_width: self.resource.bar.w,
    bar_height: self.resource.bar.h,
  })
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
  texture : @res.NxTexture,
  fit? : @selene_ui.ImageFit = @selene_ui.ImageFit::None,
) -> @selene_ui.UiImage {
  let source = ui_image_source_from_texture(texture)
  @selene_ui.UiImage::from_image(
    @selene_math.Vec2(texture.w.to_double(), texture.h.to_double()),
    @res.require_image(texture.i),
    fit~,
    source=Some(source),
  )
}

///|
fn ui_image_source_from_texture(
  texture : @res.NxTexture,
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
fn UINpcTalk::set_image_texture(
  self : UINpcTalk,
  entity : @entity.Entity,
  texture : @res.NxTexture,
  fit? : @selene_ui.ImageFit = @selene_ui.ImageFit::None,
) -> Unit {
  ignore(self)
  @selene_ui.ui_images().set(entity, ui_image_from_texture(texture, fit~))
}

///|
fn UINpcTalk::spawn_image_node(
  self : UINpcTalk,
  texture : @res.NxTexture,
  x : Int,
  y : Int,
  z : Int,
  fit? : @selene_ui.ImageFit = @selene_ui.ImageFit::None,
  width? : Int = texture.w,
  height? : Int = texture.h,
) -> @entity.Entity {
  let entity = @entity.Entity()
  self.entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(width.to_double(), height.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex(z))
  self.set_image_texture(entity, texture, fit~)
  entity
}

///|
fn UINpcTalk::spawn_material_node(
  self : UINpcTalk,
  material : @selene_ui.UiMaterialHandle,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  z : Int,
) -> @entity.Entity {
  let entity = @entity.Entity()
  self.entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(width.to_double(), height.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex(z))
  @selene_ui.material_nodes().set(entity, @selene_ui.MaterialNode(material))
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
  @selene_ui.buttons().set(entity, @selene_ui.Button())
  self.buttons.push({ resource, entity, enabled: true, on_click })
}

///|
fn UINpcTalk::update(self : UINpcTalk) -> Unit {
  let focused = @selene_ui.focused_entity()
  for button in self.buttons {
    let texture = if !button.enabled {
      button.resource.disabled
    } else if focused == Some(button.entity) {
      button.resource.mouse_over
    } else {
      match @selene_ui.interactions().get(button.entity) {
        Some(@selene_ui.Interaction::Pressed) => button.resource.pressed
        Some(@selene_ui.Interaction::Hovered) => button.resource.mouse_over
        _ => button.resource.normal
      }
    }
    self.set_image_texture(button.entity, texture)
    if focused == Some(button.entity) {
      @selene_ui.outlines().set(
        button.entity,
        @selene_ui.Outline(
          @selene_ui.Val::px(2.0),
          @selene_ui.BorderColor::from_css("#fff4a8").color,
        ),
      )
    } else {
      @selene_ui.outlines().remove(button.entity)
    }
  }
  for button in self.selection_buttons {
    if focused == Some(button.entity) {
      @selene_ui.outlines().set(
        button.entity,
        @selene_ui.Outline(
          @selene_ui.Val::px(2.0),
          @selene_ui.BorderColor::from_css("#fff4a8").color,
        ),
      )
    } else {
      @selene_ui.outlines().remove(button.entity)
    }
  }
  for event in @selene_ui.navigation_event_bus.read(self.navigation_reader) {
    guard event.direction is @selene_ui.UiNavigationDirection::Cancel else {
      continue
    }
    guard event.entity is Some(focused) else { continue }
    let mut owns_focus = false
    for entity in self.entities {
      if entity == focused {
        owns_focus = true
        break
      }
    }
    guard owns_focus else { continue }
    cancel_npc_talk(self.args)
    return
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
  @cmp.maximum(
    1,
    self.resource.window_slice.width - CONTENT_X - CONTENT_RIGHT_PADDING,
  )
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
  @selene_ui.text_fonts().set(entity, @game_ui_font.text_font(bold=run.bold))
  @selene_ui.text_colors().set(
    entity,
    @selene_ui.TextColor::from_css(run.color.css_name()),
  )
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
  let entity = @entity.Entity()
  self.entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(width.to_double(), height.to_double()),
      overflow_x=@selene_ui.Overflow::Clip,
      overflow_y=@selene_ui.Overflow::Clip,
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex(z))
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout(
      align=@selene_math.Left,
      baseline=@selene_math.Top,
      line_height=TEXT_LINE_HEIGHT,
      wrap=@selene_ui.TextWrap::WordWrap,
      overflow=@selene_ui.TextOverflow::Clip,
    ),
  )
  if clickable {
    @selene_ui.buttons().set(entity, @selene_ui.Button())
  }
  let spans : Array[@selene_ui.TextSpan] = runs.map(fn(run) {
    @selene_ui.TextSpan(
      run.text,
      font=Some(@game_ui_font.text_font(bold=run.bold)),
      color=Some(@selene_ui.TextColor::from_css(run.color.css_name())),
      bold=run.bold,
      underline=run.underline,
    )
  })
  @selene_ui.texts().set(entity, @selene_ui.Text::from_spans(spans))
  let first = runs
    .get(0)
    .unwrap_or(TextRun::{
      text: "",
      color: ColorName::BLACK,
      bold: false,
      underline: false,
    })
  set_text_style(entity, first)
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
          (text.to_owned() == "\r\n" || text.to_owned() == "\n") {
          ""
        } else {
          text.to_owned()
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
        opening_selection = Some((@string.parse_int(payload.to_owned()), []))
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
        let mut raw = text.to_owned()
        if trim_end_newline && i == nodes.length() - 1 {
          raw = raw.trim_end(chars="\n").to_owned()
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
      if !part.is_empty() {
        let line = lines[lines.length() - 1]
        line.push({ ..run, text: part.to_owned() })
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
  while !trimmed.is_empty() && trimmed.last().unwrap_or([]).is_empty() {
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
  .concat([|
    ('L', @markup_text.MarkupType::Pair),
    ('l', @markup_text.MarkupType::SelfClosing),
  |])
  |> Map::from_iter

///|
pub(all) suberror ParseTalkError {
  ParseTalkError(String)
} derive(Debug)

///|
using @struct {type ColorName, type Point}
