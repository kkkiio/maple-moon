///|
typealias ButtonState = @ui.ButtonState

///|
typealias UIElementType = @ui.UIElementType

///|
struct UINpcTalk {
  hooks : @ui.Hooks
  base : @ui.UIModel
  buttons : Array[@ui.UIButton]
  top : @graphics.Texture
  fill : @graphics.Texture
  bottom : @graphics.Texture
  nametag : @graphics.Texture
  mut speaker : @graphics.Texture
  mut content : NPCTalkContent?
  name : @graphics.Text
  mut height : Int
  offset : Int
  mut unit_rows : Int
  mut row_max : Int
  min_height : Int
  mut show_slider : Bool
  // slider:Slider
  mut t : TalkType?
  mut formatted_text_pos : Int
  mut timestep : Int
}

///|
pub fn UINpcTalk::const_type() -> UIElementType {
  UIElementType::NPC_TALK
}

///|
pub fn UINpcTalk::const_focused() -> Bool {
  true
}

///|
pub fn UINpcTalk::const_toggled() -> Bool {
  false
}

///|
struct NPCTalkContent {
  text_content : Array[@graphics.Text]
  text_button_content : Array[@ui.TextButton]
}

///|
let bid_all_level = 0

///|
let bid_close = 1

///|
let bid_my_level = 2

///|
let bid_next = 3

///|
let bid_no = 4

///|
let bid_ok = 5

///|
let bid_prev = 6

///|
let bid_qafter = 7

///|
let bid_qcno = 8

///|
let bid_qcyes = 9

///|
let bid_qgiveup = 10

///|
let bid_qno = 11

///|
let bid_qstart = 12

///|
let bid_qyes = 13

///|
let bid_yes = 14

///|
let bid_text_button = 15

///|
fn UINpcTalk::new(
  util_dlg_ex : @resource.NxNode,
  quest : @resource.NxNode,
  hooks : @ui.Hooks
) -> UINpcTalk {
  let base = @ui.UIModel::new(
    @struct.Point::default(),
    @struct.Point::default(),
  ) // update later
  let offset = 0
  let unit_rows = 0
  let row_max = 0
  let show_slider = false
  let formatted_text_pos = 0
  let timestep = 0
  let top = @graphics.Texture::from_resource(util_dlg_ex["t"])
  let fill = @graphics.Texture::from_resource(util_dlg_ex["c"])
  let bottom = @graphics.Texture::from_resource(util_dlg_ex["s"])
  let nametag = @graphics.Texture::from_resource(util_dlg_ex["bar"])
  let min_height = 8 * fill.height() + 14
  let buttons : Array[@ui.UIButton] = Array::new()
  buttons[bid_all_level] = @ui.MapleButton::from_resource(
    util_dlg_ex["BtAllLevel"],
  )
  buttons[bid_close] = @ui.MapleButton::from_resource(util_dlg_ex["BtClose"])
  buttons[bid_my_level] = @ui.MapleButton::from_resource(
    util_dlg_ex["BtMyLevel"],
  )
  buttons[bid_next] = @ui.MapleButton::from_resource(util_dlg_ex["BtNext"])
  buttons[bid_no] = @ui.MapleButton::from_resource(quest["BtNo"])
  buttons[bid_ok] = @ui.MapleButton::from_resource(util_dlg_ex["BtOK"])
  buttons[bid_prev] = @ui.MapleButton::from_resource(util_dlg_ex["BtPrev"])
  buttons[bid_qafter] = @ui.MapleButton::from_resource(util_dlg_ex["BtQAfter"])
  buttons[bid_qcno] = @ui.MapleButton::from_resource(util_dlg_ex["BtQCNo"])
  buttons[bid_qcyes] = @ui.MapleButton::from_resource(util_dlg_ex["BtQCYes"])
  buttons[bid_qgiveup] = @ui.MapleButton::from_resource(
    util_dlg_ex["BtQGiveup"],
  )
  buttons[bid_qno] = @ui.MapleButton::from_resource(util_dlg_ex["BtQNo"])
  buttons[bid_qstart] = @ui.MapleButton::from_resource(util_dlg_ex["BtQStart"])
  buttons[bid_qyes] = @ui.MapleButton::from_resource(util_dlg_ex["BtQYes"])
  buttons[bid_yes] = @ui.MapleButton::from_resource(util_dlg_ex["BtYes"])
  let name = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
    max_width=nametag.width(),
  )
  {
    hooks,
    base,
    buttons,
    offset,
    unit_rows,
    row_max,
    show_slider,
    formatted_text_pos,
    timestep,
    top,
    fill,
    bottom,
    nametag,
    min_height,
    t: None,
    name,
    height: max_height, // TODO: fit height to text
    speaker: @graphics.Texture::default(),
    content: None,
  }
}

///|
pub fn get_ui_model(self : UINpcTalk) -> @ui.UIModel {
  self.base
}

///|
impl @ui.UIElement for UINpcTalk with render(self) -> @ui.RuntimeState {
  let buttons = self.buttons
  fn draw() -> Unit {
    let mut drawpos = self.base.position
    self.top.draw(drawpos |> @graphics.DrawArgument::from_point)
    drawpos = drawpos.shift_y(self.top.height())
    self.fill.draw(
      @graphics.DrawArgument::new4(drawpos, @struct.Point::new(0, self.height)),
    )
    drawpos = drawpos.shift_y(self.height)
    self.bottom.draw(drawpos |> @graphics.DrawArgument::from_point)
    drawpos = drawpos.shift_y(self.bottom.height())
    for _, button in buttons {
      button.draw(self.base.position)
    }
    let speaker_y = (self.top.height() + self.height + self.bottom.height()) / 2
    let speaker_pos = self.base.position +
      @struct.Point::new(22, 11 + speaker_y)
    let center_pos = speaker_pos +
      @struct.Point::new(self.nametag.width() / 2, 0)
    self.speaker.draw(@graphics.DrawArgument::new14(center_pos, true))
    self.nametag.draw(speaker_pos |> @graphics.DrawArgument::from_point)
    self.name.draw(center_pos + @struct.Point::new(0, -4))
    match self.content {
      Some(content) =>
        if self.show_slider {
          let text_min_height = self.base.position.y + self.top.height() - 1
          let mut init_height = 19
          for element in content.text_content {
            element.draw(
              self.base.position +
              @struct.Point::new(162, init_height - self.offset * 248),
              text_y_clip=@struct.Range::new(
                  text_min_height,
                  text_min_height + self.height,
                )
                |> @option.some,
            )
            init_height += element.height()
          }
          for element in content.text_button_content {
            element.draw_in_range(
              self.base.position +
              @struct.Point::new(162, init_height - self.offset * 248),
              @struct.Range::new(text_min_height, text_min_height + self.height),
            )
            init_height += element.height()
          }
          // TODO: draw slider
        } else {
          let mut init_height = 19
          for element in content.text_content {
            element.draw(
              self.base.position + @struct.Point::new(166, init_height),
            )
            init_height += element.height()
          }
          for element in content.text_button_content {
            element.draw(
              self.base.position + @struct.Point::new(166, init_height),
            )
            init_height += element.height()
          }
        }
      None => ()
    }
  }

  {
    draw_fn: fn(_alpha) { draw() },
    buttons: buttons.mapi(fn(i, btn) {
      @ui.Button::new(btn, on_click=fn() { self.button_pressed(i) })
    }),
    sprites: [],
  }
}

///|
fn button_pressed(self : UINpcTalk, bid : Int) -> ButtonState {
  self.base.deactivate()
  match self.t {
    Some(t) =>
      match t {
        TalkType::SEND_NEXT | TalkType::SEND_OK =>
          if bid == bid_next {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          } else if bid == bid_prev {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          }
        TalkType::SEND_NEXT_PREV =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), -1).dispatch()
          } else if bid == bid_next {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          } else if bid == bid_prev {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          }
        TalkType::SEND_YESNO =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), -1).dispatch()
          } else if bid == bid_no {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else if bid == bid_yes {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          }
        TalkType::SEND_ACCEPT_DECLINE =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), -1).dispatch()
          } else if bid == bid_qno {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else if bid == bid_qyes {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          }
        TalkType::SEND_GET_TEXT => ()
        TalkType::SEND_GET_NUMBER =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else if bid == bid_ok {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          }
        TalkType::SEND_SIMPLE =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else {
            let btn = self.content.unwrap().text_button_content[bid -
              bid_text_button]
            new_npc_talk_more_packet_with_selection(btn.get_option_number()).dispatch()
          }
        _ => ()
      }
    None => ()
  }
  match self.content {
    Some(content) =>
      for _, element in content.text_button_content {
        self.buttons.remove(bid_text_button + element.get_option_number())
        |> ignore
      }
    None => ()
  }
  ButtonState::NORMAL
}

///|
// pub fn send_cursor(
//   self : UINpcTalk,
//   clicked : Bool,
//   cursorpos : @struct.Point[Int]
// ) -> CursorState {
//   // TODO: check slider
//   let estate = @ui.send_cursor_to_buttons(
//     self.buttons.iter2(),
//     self.base.position,
//     fn(bid) { self.button_pressed(bid) },
//     clicked,
//     cursorpos,
//   )
//   if estate == CursorState::CLICKING && clicked {
//     match self.content {
//       Some(content) =>
//         for element in content.text_button_content.iter() {
//           if element.bounds(self.base.position).contains(cursorpos) {
//             self.button_pressed(bid_text_button + element.get_option_number())
//             |> ignore
//             break
//           }
//         }
//       None => ()
//     }
//   }
//   estate
// }

///|
pub fn remove_cursor(self : UINpcTalk) -> Unit {
  @ui.remove_cursor(self.buttons.iter().map(fn(b) { b.get_button_base() }))
}

///|
pub fn send_key(
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
  self.timestep = 0
  self.formatted_text_pos = 0
  let content = convert_npc_text!(tx, npcid, player_name)
  self.content = content |> @option.some
  for element in content.text_button_content {
    self.buttons[bid_text_button + element.get_option_number()] = element
  }
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
  self.show_slider = false
  self.reset_content_pos()
  for i, button in self.buttons {
    if i < bid_text_button { // enable selection buttons
      button.get_button_base().set_active(false)
    }
    button.get_button_base().set_state(ButtonState::NORMAL)
  }
  let y_cord = self.height + 48
  self.buttons[bid_close]
  .get_button_base()
  ..set_position(@struct.Point::new(9, y_cord))
  .set_active(true)
  match self.t {
    Some(t) =>
      match t {
        TalkType::SEND_OK =>
          self.buttons[bid_ok]
          .get_button_base()
          ..set_position(@struct.Point::new(469, y_cord))
          .set_active(true)
        TalkType::SEND_YESNO => {
          let yes_position = @struct.Point::new(389, y_cord)
          self.buttons[bid_yes]
          .get_button_base()
          ..set_position(yes_position)
          .set_active(true)
          self.buttons[bid_no]
          .get_button_base()
          ..set_position(yes_position + @struct.Point::new(65, 0))
          .set_active(true)
        }
        TalkType::SEND_NEXT =>
          self.buttons[bid_next]
          .get_button_base()
          ..set_position(@struct.Point::new(461, y_cord - 30))
          .set_active(true)
        TalkType::SEND_PREV =>
          self.buttons[bid_prev]
          .get_button_base()
          ..set_position(@struct.Point::new(367, y_cord))
          .set_active(true)
        TalkType::SEND_NEXT_PREV => {
          self.buttons[bid_next]
          .get_button_base()
          ..set_position(@struct.Point::new(461, y_cord - 30))
          .set_active(true)
          self.buttons[bid_prev]
          .get_button_base()
          ..set_position(@struct.Point::new(367, y_cord))
          .set_active(true)
        }
        TalkType::SEND_ACCEPT_DECLINE => {
          self.buttons[bid_qyes]
          .get_button_base()
          ..set_position(@struct.Point::new(386, y_cord))
          .set_active(true)
          self.buttons[bid_qno]
          .get_button_base()
          ..set_position(@struct.Point::new(451, y_cord))
          .set_active(true)
        }
        _ => ()
      }
    None => ()
  }
  self.base.position = @struct.Point::new(
    400 - self.top.width() / 2,
    240 - self.height / 2,
  )
  self.base.dimension = @struct.Point::new(self.top.width(), self.height + 120)
  (self.hooks.on_state_changed)()
}

///|
fn reset_content_pos(self : UINpcTalk) -> Unit {
  let content = match self.content {
    Some(content) => content
    None => return
  }
  if self.show_slider {
    let mut init_height = 19
    for element in content.text_content {
      init_height += element.height()
    }
    for element in content.text_button_content {
      element
      .get_button_base()
      .set_position(@struct.Point::new(162, init_height - self.offset * 248))
      init_height += element.height()
    }
  } else {
    let mut init_height = 19
    for element in content.text_content {
      init_height += element.height()
    }
    for element in content.text_button_content {
      element
      .get_button_base()
      .set_position(@struct.Point::new(166, init_height))
      init_height += element.height()
    }
  }
}

///|
fn new_npc_talk_more_packet(lastmsg : Int, response : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NPC_TALK_MORE)
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
let max_height = 248

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
