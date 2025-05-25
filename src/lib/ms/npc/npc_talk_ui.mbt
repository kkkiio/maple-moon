///|
struct UINpcTalk {
  hooks : @ui.Hooks
  on_choice : (TalkChoice) -> Unit
  base : @ui.UIModel
  resource : NpcTalkResource
  mut speaker : @graphics.Texture
  mut content : NPCTalkContent?
  name : @graphics.Text
  mut height : Int
  min_height : Int
  // slider:Slider
  mut t : TalkType?
}

///|
pub fn UINpcTalk::const_focused() -> Bool {
  true
}

///|
struct NPCTalkContent {
  text_content : Array[@graphics.Text]
  text_button_content : Array[@ui.TextButton]
}

///|
pub enum TalkType {
  // SEND_TEXT_ONLY
  SEND_YESNO
  SEND_SIMPLE
  // SEND_ACCEPT_DECLINE
  SEND_OK
  SEND_NEXT
  SEND_NEXT_PREV
  SEND_PREV
  // SEND_GET_TEXT
  // SEND_GET_NUMBER
} derive(Show, Eq)

///|
pub fn TalkType::from_int(
  msgtype : Int,
  style_b0 : Int,
  style_b1 : Int
) -> TalkType? {
  match msgtype {
    0 => {
      let is_send_ok = style_b0 == 0 && style_b1 == 0
      let is_next_prev = style_b0 == 1 && style_b1 == 1
      let is_next = style_b0 == 0 && style_b1 == 1
      let is_prev = style_b0 == 1 && style_b1 == 0
      if is_send_ok {
        return Some(SEND_OK)
      }
      if is_next_prev {
        return Some(SEND_NEXT_PREV)
      }
      if is_next {
        return Some(SEND_NEXT)
      }
      if is_prev {
        return Some(SEND_PREV)
      }
      ...
      // return Some(SEND_TEXT_ONLY)
    }
    1 => return Some(SEND_YESNO)
    4 => return Some(SEND_SIMPLE)
    12 => ... // return Some(SEND_ACCEPT_DECLINE)
    _ => return None
  }
}

///|
pub fn int_value(self : TalkType) -> Int {
  match self {
    // SEND_TEXT_ONLY => 0
    SEND_YESNO => 1
    SEND_SIMPLE => 4
    // SEND_ACCEPT_DECLINE => 12
    // below are determined by 2 style bytes when msgtype = 0
    SEND_OK => 13
    SEND_NEXT => 14
    SEND_NEXT_PREV => 15
    SEND_PREV => 16
    // SEND_GET_TEXT => 17
    // SEND_GET_NUMBER => 18
  }
}

///|
pub fn hash(self : TalkType) -> Int {
  self.int_value()
}

///|
pub fn hash_combine(self : TalkType, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
pub enum TalkChoice {
  SEND_YESNO(answer~ : Bool?)
  SEND_SIMPLE(option~ : Int?)
  SEND_OK(ok~ : Unit?)
  SEND_NEXT(next~ : Unit?)
  SEND_NEXT_PREV(next~ : Bool?)
  SEND_PREV(prev~ : Unit?)
}

///|
pub(all) struct NpcTalkResource {
  top : @graphics.Texture
  fill : @graphics.Texture
  bottom : @graphics.Texture
  nametag : @graphics.Texture
  bt_yes : @ui.MapleButtonResource
  bt_no : @ui.MapleButtonResource
  bt_ok : @ui.MapleButtonResource
  bt_next : @ui.MapleButtonResource
  bt_prev : @ui.MapleButtonResource
  bt_close : @ui.MapleButtonResource
  bt_qstart : @ui.MapleButtonResource
  bt_qyes : @ui.MapleButtonResource
  bt_qno : @ui.MapleButtonResource
  bt_qcyes : @ui.MapleButtonResource
  bt_qcno : @ui.MapleButtonResource
  bt_qgiveup : @ui.MapleButtonResource
  bt_qafter : @ui.MapleButtonResource
  bt_my_level : @ui.MapleButtonResource
  bt_all_level : @ui.MapleButtonResource
}

///|
pub fn NpcTalkResource::from_resource(
  util_dlg_ex : @resource.NxNode
) -> NpcTalkResource {
  let top = @graphics.Texture::from_resource(util_dlg_ex["t"])
  let fill = @graphics.Texture::from_resource(util_dlg_ex["c"])
  let bottom = @graphics.Texture::from_resource(util_dlg_ex["s"])
  let nametag = @graphics.Texture::from_resource(util_dlg_ex["nametag"])
  let bt_yes = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtYes"])
  let bt_no = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtNo"])
  let bt_ok = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtOK"])
  let bt_next = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtNext"])
  let bt_prev = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtPrev"])
  let bt_close = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtClose"])
  let bt_qstart = @ui.MapleButtonResource::from_resource(
    util_dlg_ex["BtQStart"],
  )
  let bt_qyes = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtQYes"])
  let bt_qno = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtQNo"])
  let bt_qcyes = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtQCYes"])
  let bt_qcno = @ui.MapleButtonResource::from_resource(util_dlg_ex["BtQCNo"])
  let bt_qgiveup = @ui.MapleButtonResource::from_resource(
    util_dlg_ex["BtQGiveup"],
  )
  let bt_qafter = @ui.MapleButtonResource::from_resource(
    util_dlg_ex["BtQAfter"],
  )
  let bt_my_level = @ui.MapleButtonResource::from_resource(
    util_dlg_ex["BtMyLevel"],
  )
  let bt_all_level = @ui.MapleButtonResource::from_resource(
    util_dlg_ex["BtAllLevel"],
  )
  {
    top,
    fill,
    bottom,
    nametag,
    bt_yes,
    bt_no,
    bt_ok,
    bt_next,
    bt_prev,
    bt_close,
    bt_qstart,
    bt_qyes,
    bt_qno,
    bt_qcyes,
    bt_qcno,
    bt_qgiveup,
    bt_qafter,
    bt_my_level,
    bt_all_level,
  }
}

///|
pub fn UINpcTalk::new(
  resource : NpcTalkResource,
  hooks : @ui.Hooks,
  on_choice~ : (TalkChoice) -> Unit = fn(_) {  }
) -> UINpcTalk {
  let base = @ui.UIModel::new(
    @struct.Point::default(),
    @struct.Point::default(),
  )
  let name = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
    max_width=resource.nametag.width(),
  )
  let height = 0
  let min_height = 8 * resource.fill.height() + 14
  let speaker = @graphics.Texture::default()
  {
    hooks,
    on_choice,
    base,
    resource,
    speaker,
    content: None,
    name,
    height,
    min_height,
    t: None,
  }
}

///|
pub impl @ui.Widget for UINpcTalk with get_ui_model(self) -> @ui.UIModel {
  self.base
}

///|
pub impl @ui.Widget for UINpcTalk with render(self) -> @ui.RenderSpec {
  let render_elements = []
  let offset = @struct.Point::default()
  // Add top texture
  render_elements.push(
    @ui.TextureUI(self.resource.top)
    |> @ui.StaticUI::new(pos=offset)
    |> @ui.RenderElement::Static,
  )
  let offset = offset.shift_y(self.resource.top.height())

  // Add fill texture
  render_elements.push(
    @ui.TextureUI(self.resource.fill)
    |> @ui.StaticUI::new(pos=offset, stretch=@struct.Point::new(0, self.height))
    |> @ui.RenderElement::Static,
  )
  let offset = offset.shift_y(self.height)

  // Add bottom texture
  render_elements.push(
    @ui.TextureUI(self.resource.bottom)
    |> @ui.StaticUI::new(pos=offset)
    |> @ui.RenderElement::Static,
  )

  // Add speaker image and nametag
  let speaker_y = (
      self.resource.top.height() + self.height + self.resource.bottom.height()
    ) /
    2
  let speaker_pos = @struct.Point::new(22, 11 + speaker_y)
  let center_pos = speaker_pos +
    @struct.Point::new(self.resource.nametag.width() / 2, 0)
  render_elements.push(
    @ui.TextureUI(self.speaker)
    |> @ui.StaticUI::new_ex(
      args=@graphics.DrawArgument::new(pos=center_pos, flip=true),
    )
    |> @ui.RenderElement::Static,
  )
  render_elements.push(
    @ui.TextureUI(self.resource.nametag)
    |> @ui.StaticUI::new(pos=speaker_pos)
    |> @ui.RenderElement::Static,
  )
  render_elements.push(
    @ui.TextUI(self.name)
    |> @ui.StaticUI::new(pos=center_pos + @struct.Point::new(0, -4))
    |> @ui.RenderElement::Static,
  )

  // Add content if exists
  match self.content {
    Some(content) => {
      let mut init_height = 19
      for element in content.text_content {
        render_elements.push(
          @ui.TextUI(element)
          |> @ui.StaticUI::new(pos=@struct.Point::new(166, init_height))
          |> @ui.RenderElement::Static,
        )
        init_height += element.height()
      }
      for element in content.text_button_content {
        render_elements.push(
          element
          |> @ui.Button::new(on_click=fn() {
            (self.on_choice)(
              TalkChoice::SEND_SIMPLE(option=Some(element.get_option_number())),
            )
            None
          })
          |> @ui.Button::as_interactable,
        )
      }
    }
    None => ()
  }
  // Add buttons
  let y_cord = self.height + 48
  let btn_close = @ui.MapleButton::new(
    self.resource.bt_close,
    pos=@struct.Point::new(9, y_cord),
  )
  match self.t {
    Some(t) =>
      match t {
        TalkType::SEND_YESNO => {
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_yes,
              pos=@struct.Point::new(389, y_cord),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_YESNO(answer=Some(true)))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_no,
              pos=@struct.Point::new(461, y_cord),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_YESNO(answer=Some(false)))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            btn_close
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_YESNO(answer=None))
              None
            })
            |> @ui.Button::as_interactable,
          )
        }
        TalkType::SEND_NEXT => {
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_next,
              pos=@struct.Point::new(461, y_cord - 30),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_NEXT(next=Some(())))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            btn_close
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_NEXT(next=None))
              None
            })
            |> @ui.Button::as_interactable,
          )
        }
        TalkType::SEND_PREV => {
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_prev,
              pos=@struct.Point::new(367, y_cord),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_PREV(prev=Some(())))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            btn_close
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_PREV(prev=None))
              None
            })
            |> @ui.Button::as_interactable,
          )
        }
        TalkType::SEND_NEXT_PREV => {
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_next,
              pos=@struct.Point::new(461, y_cord - 30),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_NEXT_PREV(next=Some(true)))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_prev,
              pos=@struct.Point::new(367, y_cord),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_NEXT_PREV(next=Some(false)))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            btn_close
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_NEXT_PREV(next=None))
              None
            })
            |> @ui.Button::as_interactable,
          )
        }
        TalkType::SEND_OK => {
          render_elements.push(
            @ui.MapleButton::new(
              self.resource.bt_ok,
              pos=@struct.Point::new(469, y_cord),
            )
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_OK(ok=Some(())))
              None
            })
            |> @ui.Button::as_interactable,
          )
          render_elements.push(
            btn_close
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_OK(ok=None))
              None
            })
            |> @ui.Button::as_interactable,
          )
        }
        TalkType::SEND_SIMPLE =>
          // options handled in content, add close
          render_elements.push(
            btn_close
            |> @ui.Button::new(on_click=fn() {
              (self.on_choice)(TalkChoice::SEND_SIMPLE(option=None))
              None
            })
            |> @ui.Button::as_interactable,
          )
      }
    None => ()
  }
  { render_elements, }
}

///|
pub impl @ui.Widget for UINpcTalk with send_key(
  self : UINpcTalk,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  match self.t {
    Some(t) =>
      if pressed && escape {
        self.base.deactivate()
        new_npc_talk_more_packet(t.int_value(), 0).dispatch()
      }
    None => ()
  }
}

///|
struct Attributes {
  npcid : Int
  msgtype : Int
  style_b0 : Int
  style_b1 : Int
  speakerbyte : Int
  tx : String
  player_name : String
}

///|
pub fn change_text(
  self : UINpcTalk,
  npcid : Int,
  msgtype : Int,
  style_b0 : Int,
  style_b1 : Int,
  speakerbyte : Int,
  tx : String,
  player_name : String
) -> Unit! {
  self.t = TalkType::from_int(msgtype, style_b0, style_b1)
  let content = convert_npc_text!(tx, npcid, player_name)
  self.content = content |> @option.some
  if speakerbyte == 0 {
    let strid = @string_format.extend_id(npcid, 7) + ".img"
    self.speaker = npc_loader().load_res([strid, "stand", "0"])
      |> @graphics.Texture::from_resource
    let namestr = @resource.string_loader()
      .load_res(["Npc.img", npcid.to_string(), "name"])
      .get_string()
    self.name.change_text(namestr)
  } else {
    self.speaker = @graphics.Texture::default()
    self.name.change_text("")
  }
  self.height = self.min_height + 20
  self.reset_content_pos()
  self.base.position = @struct.Point::new(
    400 - self.resource.top.width() / 2,
    240 - self.height / 2,
  )
  self.base.dimension = @struct.Point::new(
    self.resource.top.width(),
    self.height + 120,
  )
  (self.hooks.on_state_changed)()
}

///|
fn reset_content_pos(self : UINpcTalk) -> Unit {
  let content = match self.content {
    Some(content) => content
    None => return
  }
  let mut init_height = 19
  for element in content.text_content {
    init_height += element.height()
  }
  for element in content.text_button_content {
    element.get_button_base().set_position(@struct.Point::new(166, init_height))
    init_height += element.height()
  }
}

///|
fn new_npc_talk_more_packet(lastmsg : Int, response : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.ClientOpcode::NPC_TALK_MORE)
  ..write_byte(lastmsg.to_byte())
  ..write_byte(response.to_byte())
}

///|
// fn new_npc_talk_more_packet_with_response(response : String) -> @net.OutPacket {
//   new_npc_talk_more_packet(2, 1)..write_string(response)
// }

///|
fn new_npc_talk_more_packet_with_selection(selection : Int) -> @net.OutPacket {
  new_npc_talk_more_packet(4, 1)..write_int(selection)
}

///|
fn get_map_info_by_id(mapid : Int) -> NxMapInfo {
  let map_category = get_map_category(mapid)
  let map_info = @resource.string_loader().load_res([
    "Map.img",
    map_category,
    mapid.to_string(),
  ])
  {
    // description: map_info["mapDesc"].get_string(),
    // street_name: map_info["streetName"].get_string(),
    // full_name: map_info["streetName"].get_string() +
    // " : " +
    // map_info["mapName"].get_string(),
    name: map_info["mapName"].get_string(),
  }
}

///|
fn get_map_category(mapid : Int) -> String {
  if mapid < 100000000 {
    return "maple"
  }
  if mapid < 200000000 {
    return "victoria"
  }
  if mapid < 300000000 {
    return "ossyria"
  }
  if mapid < 540000000 {
    return "elin"
  }
  if mapid < 600000000 {
    return "singapore"
  }
  if mapid < 670000000 {
    return "MasteriaGL"
  }
  if mapid < 682000000 {
    let prefix3 = mapid / 1000000 * 1000000
    let prefix4 = mapid / 100000 * 100000
    if prefix3 == 674000000 || prefix4 == 680100000 || prefix4 == 889100000 {
      return "etc"
    }
    if prefix3 == 677000000 {
      return "Episode1GL"
    }
    return "weddingGL"
  }
  if mapid < 683000000 {
    return "HalloweenGL"
  }
  if mapid < 800000000 {
    return "event"
  }
  if mapid < 900000000 {
    return "jp"
  }
  return "etc"
}

///|
struct NxMapInfo {
  // description : String
  name : String
  // street_name : String
  // full_name : String
}

///|
fn convert_npc_text(
  raw_text : String,
  npcid : Int,
  player_name : String
) -> NPCTalkContent! {
  @log.debug({ "raw_text": raw_text }, "npc talk")
  let content = parse_talk_content!(
    raw_text,
    new_variable_context(npcid, player_name),
  )
  // @log.debug({ "raw_text": raw_text, "content": content }, "npc talk")
  let text_button_content = []
  match content.selections {
    Some(selections) =>
      for selection in selections.selections {
        let button = @ui.TextButton::new(
          @graphics.Text::new(
            text=selection.1,
            @graphics.FontId::A18M,
            @graphics.TextAlignment::LEFT,
            selections.color,
            max_width=320,
          ),
          selection.0,
        )
        text_button_content.push(button)
      }
    None => ()
  }
  {
    text_content: [
      @graphics.Text::new(
        text=content.text_html,
        @graphics.FontId::A18M,
        @graphics.TextAlignment::LEFT,
        @struct.ColorName::DARKGREY,
        max_width=320,
      ),
    ],
    text_button_content,
  }
}

///|
fn new_variable_context(npcid : Int, player_name : String) -> VariableContext {
  {
    fn_map: {
      'p': fn(_v) {
        @resource.string_loader()
        .load_res(["Npc.img", npcid.to_string(), "name"])
        .get_string()
      },
      'h': fn(_v) { player_name },
      't': fn(v) {
        let itemid = try {
          @strconv.parse_int!(v)
        } catch {
          @strconv.StrConvError(_) =>
            raise ParseTalkError("invalid item id: \{v}")
        }
        let itemname = @resource.string_loader()
          .load_res(["Consume.img", itemid.to_string(), "name"])
          .get_string()
        itemname
      },
      'm': fn(v) {
        let mapid = try {
          @strconv.parse_int!(v)
        } catch {
          @strconv.StrConvError(_) =>
            raise ParseTalkError("invalid map id: \{v}")
        }
        let map_info = get_map_info_by_id(mapid)
        map_info.name
      },
    },
  }
}
