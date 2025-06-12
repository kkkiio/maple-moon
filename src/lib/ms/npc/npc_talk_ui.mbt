///|
struct UINpcTalk {
  string_loader : @resource.SyncLoader
  hooks : @ui.Hooks
  base : @ui.UIModel
  resource : NpcTalkResource
  name_loader : @markup_text.RefRender
  mut speaker : @graphics.Texture
  mut content : NPCTalkContent?
  name : @graphics.Text
  mut height : Int
  min_height : Int
  // slider:Slider
  mut talk_action : TalkAction?
}

///|
pub fn UINpcTalk::const_focused() -> Bool {
  true
}

///|
priv struct NPCTalkContent {
  text_content : Array[@graphics.Text]
  selections : Array[(ColorName, Int, String)]
}

///|
pub enum TalkType {
  // SEND_TEXT_ONLY
  SEND_YESNO
  SEND_SIMPLE
  // SEND_ACCEPT_DECLINE
  SEND_OK // 0 0 0
  SEND_NEXT // 0 0 1
  SEND_NEXT_PREV // 0 1 1
  SEND_PREV // 0 1 0
  // SEND_GET_TEXT
  // SEND_GET_NUMBER
} derive(Show, Eq, ToJson)

///|
pub fn TalkType::from_int(
  msgtype : Int,
  style_b0 : Int,
  style_b1 : Int
) -> TalkType? {
  match msgtype {
    0 =>
      match (style_b0, style_b1) {
        (0, 0) => return Some(SEND_OK)
        (0, 1) => return Some(SEND_NEXT)
        (1, 0) => return Some(SEND_PREV)
        (1, 1) => return Some(SEND_NEXT_PREV)
        _ => return None
      }
    // return Some(SEND_TEXT_ONLY)
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
pub impl Hash for TalkType with hash_combine(self, hasher) {
  hasher.combine(self.int_value())
}

///|
pub(all) enum TalkChoice {
  SEND_YESNO(answer~ : Bool?)
  SEND_SIMPLE(option~ : Int?)
  SEND_OK(ok~ : Unit?)
  SEND_NEXT(next~ : Unit?)
  SEND_NEXT_PREV(next~ : Bool?)
  SEND_PREV(prev~ : Unit?)
} derive(Show)

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
  string_loader : @resource.SyncLoader,
  name_loader : @markup_text.RefRender
) -> UINpcTalk {
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
    string_loader,
    hooks,
    base: hooks.ui_model,
    resource,
    name_loader,
    speaker,
    content: None,
    name,
    height,
    min_height,
    talk_action: None,
  }
}

///|
pub impl @ui.Widget for UINpcTalk with render(self) -> @ui.RenderSpec {
  let render_elements = []
  guard self.content is Some(content) else { return { render_elements, } }
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
  let speaker_pos = @struct.Point::new(100, 11 + speaker_y)
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
  let mut init_height = 19
  for element in content.text_content {
    render_elements.push(
      @ui.TextUI(element)
      |> @ui.StaticUI::new(pos=@struct.Point::new(166, init_height))
      |> @ui.RenderElement::Static,
    )
    init_height += element.height()
  }
  // Add buttons
  let y_cord = self.height + 48
  let btn_close = @ui.MapleButton::new(
    self.resource.bt_close,
    pos=@struct.Point::new(9, y_cord),
  )
  @log.debug({ "talk_action": self.talk_action }, "render talk action")
  fn new_btn(btn, on_click) {
    btn
    |> @ui.Button::new(on_click=fn() {
      on_click()
      None
    })
    |> @ui.Button::as_interactable
  }

  match self.talk_action {
    Some(SEND_YESNO(callback)) =>
      render_elements
      ..push(
        new_btn(
          @ui.MapleButton::new(
            self.resource.bt_yes,
            pos=Point::new(389, y_cord),
          ),
          fn() { callback(Some(true)) },
        ),
      )
      ..push(
        new_btn(
          @ui.MapleButton::new(self.resource.bt_no, pos=Point::new(461, y_cord)),
          fn() { callback(Some(false)) },
        ),
      )
      ..push(new_btn(btn_close, fn() { callback(None) }))
    Some(SEND_NEXT(callback)) =>
      render_elements
      ..push(
        new_btn(
          @ui.MapleButton::new(
            self.resource.bt_next,
            pos=Point::new(461, y_cord - 30),
          ),
          fn() { callback(Some(())) },
        ),
      )
      ..push(new_btn(btn_close, fn() { callback(None) }))
    Some(SEND_PREV(callback)) =>
      render_elements
      ..push(
        new_btn(
          @ui.MapleButton::new(
            self.resource.bt_prev,
            pos=Point::new(367, y_cord - 30),
          ),
          fn() { callback(Some(())) },
        ),
      )
      ..push(new_btn(btn_close, fn() { callback(None) }))
    Some(SEND_NEXT_PREV(callback)) =>
      render_elements
      ..push(
        new_btn(
          @ui.MapleButton::new(
            self.resource.bt_prev,
            pos=Point::new(367, y_cord - 30),
          ),
          fn() { callback(Some(false)) },
        ),
      )
      ..push(
        new_btn(
          @ui.MapleButton::new(
            self.resource.bt_next,
            pos=Point::new(461, y_cord - 30),
          ),
          fn() { callback(Some(true)) },
        ),
      )
      ..push(new_btn(btn_close, fn() { callback(None) }))
    Some(SEND_OK(callback)) =>
      render_elements
      ..push(
        new_btn(
          @ui.MapleButton::new(self.resource.bt_ok, pos=Point::new(469, y_cord)),
          fn() { callback(Some(())) },
        ),
      )
      ..push(new_btn(btn_close, fn() { callback(None) }))
    Some(SEND_SIMPLE(callback)) => {
      for selection in content.selections {
        let element = @ui.TextButton::new(
          @graphics.Text::new(
            text=selection.2,
            @graphics.FontId::A13M,
            @graphics.TextAlignment::LEFT,
            selection.0,
            max_width=320,
          ),
          selection.1,
        )
        element
        .get_button_base()
        .set_position(@struct.Point::new(166, init_height))
        init_height += element.height()
        render_elements.push(
          new_btn(element, fn() { callback(Some(selection.1)) }),
        )
      }
      render_elements..push(new_btn(btn_close, fn() { callback(None) }))
    }
    None => ()
  }
  { render_elements, }
}

///|
pub fn change_text(
  self : UINpcTalk,
  npcid : Int,
  talk_action : TalkAction,
  speakerbyte : Speaker,
  tx : String
) -> Unit! {
  self.talk_action = Some(talk_action)
  let content = convert_npc_text!(tx, self.name_loader)
  self.content = content |> @option.some
  if speakerbyte is Speaker::NPC_LEFT {
    let strid = @string_format.extend_id(npcid, 7) + ".img"
    self.speaker = self.string_loader.load_res([strid, "stand", "0"])
      |> @graphics.Texture::from_resource
    let namestr = self.string_loader
      .load_res(["Npc.img", npcid.to_string(), "name"])
      .get_string()
    self.name.change_text(namestr)
  } else {
    self.speaker = @graphics.Texture::default()
    self.name.change_text("")
  }
  self.height = self.min_height + 20
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
priv struct NpcTalkMorePacket {
  lastmsg : TalkType
  response : Int
  selection : Int?
} derive(Show)

///|
impl @net.OutMessage for NpcTalkMorePacket with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::NPC_TALK_MORE)
  p
  ..write_byte(self.lastmsg.int_value().to_byte())
  ..write_byte(self.response.to_byte())
  match self.selection {
    Some(selection) => p.write_int(selection)
    None => ()
  }
  p
}

///|
// fn new_npc_talk_more_packet_with_response(response : String) -> @net.OutPacket {
//   new_npc_talk_more_packet(2, 1)..write_string(response)
// }

///|
fn new_npc_talk_more_packet_with_selection(
  selection : Int
) -> NpcTalkMorePacket {
  { lastmsg: SEND_SIMPLE, response: 1, selection: Some(selection) }
}

///|
fn new_npc_talk_more_packet(
  lastmsg : TalkType,
  response : Int
) -> NpcTalkMorePacket {
  { lastmsg, response, selection: None }
}

///|
fn convert_npc_text(
  raw_text : String,
  name_loader : @markup_text.RefRender
) -> NPCTalkContent! {
  let content = parse_talk_content!(
    raw_text,
    mod_provider=fn(_, v) { name_loader.get_mob_name(v) },
    npc_provider=fn(_, v) { name_loader.get_npc_name(v) },
    map_provider=fn(_, v) { name_loader.get_map_name!(v).to_string() },
    item_provider=fn(_, v) { name_loader.get_item_name(v).to_string() },
    player_name_provider=fn(_, _) { name_loader.get_player_name() },
  )
  {
    text_content: [
      @graphics.Text::new(
        text="<div style='line-height: normal;'>\{content.text_html}</div>",
        @graphics.FontId::A13M,
        @graphics.TextAlignment::LEFT,
        @struct.ColorName::DARKGREY,
        max_width=320,
      ),
    ],
    selections: content.selections,
  }
}

///|
typealias @struct.Point
