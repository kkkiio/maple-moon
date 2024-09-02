struct UINpcTalk {
  base : UIElementBase
  buttons : UIButtons
  top : Texture
  fill : Texture
  bottom : Texture
  nametag : Texture
  mut speaker : Texture
  mut content : NPCTalkContent?
  name : Text
  mut height : Int
  offset : Int
  mut unit_rows : Int
  mut row_max : Int
  min_height : Int
  mut show_slider : Bool
  mut draw_text : Bool
  // slider:Slider
  mut t : @npc.TalkType?
  mut formatted_text : String
  mut formatted_text_pos : Int
  mut timestep : Int
}

pub fn UINpcTalk::const_type() -> UIElementType {
  UIElementType::NPC_TALK
}

pub fn UINpcTalk::const_focused() -> Bool {
  true
}

pub fn UINpcTalk::const_toggled() -> Bool {
  false
}

struct NPCTalkContent {
  text : Text
  text_content : Array[Text]
  text_button_content : Array[TextButton]
  line_color : ColorName
  selection : Int
}

let bid_all_level = 0

let bid_close = 1

let bid_my_level = 2

let bid_next = 3

let bid_no = 4

let bid_ok = 5

let bid_prev = 6

let bid_qafter = 7

let bid_qcno = 8

let bid_qcyes = 9

let bid_qgiveup = 10

let bid_qno = 11

let bid_qstart = 12

let bid_qyes = 13

let bid_yes = 14

let bid_text_button = 15

pub fn UINpcTalk::new() -> UINpcTalk {
  let base = UIElementBase::default()
  let offset = 0
  let unit_rows = 0
  let row_max = 0
  let show_slider = false
  let draw_text = false
  let formatted_text = ""
  let formatted_text_pos = 0
  let timestep = 0
  let ui_window2 = ui_loader().load_res(["UIWindow2.img"])
  let util_dlg_ex = ui_window2["UtilDlgEx"]
  let top = Texture::from_resource(util_dlg_ex["t"])
  let fill = Texture::from_resource(util_dlg_ex["c"])
  let bottom = Texture::from_resource(util_dlg_ex["s"])
  let nametag = Texture::from_resource(util_dlg_ex["bar"])
  let min_height = 8 * fill.height() + 14
  let buttons = UIButtons::default()
  buttons.buttons[bid_all_level] = MapleButton::from_resource(
    util_dlg_ex["BtAllLevel"],
  )
  buttons.buttons[bid_close] = MapleButton::from_resource(
    util_dlg_ex["BtClose"],
  )
  buttons.buttons[bid_my_level] = MapleButton::from_resource(
    util_dlg_ex["BtMyLevel"],
  )
  buttons.buttons[bid_next] = MapleButton::from_resource(util_dlg_ex["BtNext"])
  let quest = ui_window2["Quest"]
  buttons.buttons[bid_no] = MapleButton::from_resource(quest["BtNo"])
  buttons.buttons[bid_ok] = MapleButton::from_resource(util_dlg_ex["BtOK"])
  buttons.buttons[bid_prev] = MapleButton::from_resource(util_dlg_ex["BtPrev"])
  buttons.buttons[bid_qafter] = MapleButton::from_resource(
    util_dlg_ex["BtQAfter"],
  )
  buttons.buttons[bid_qcno] = MapleButton::from_resource(util_dlg_ex["BtQCNo"])
  buttons.buttons[bid_qcyes] = MapleButton::from_resource(
    util_dlg_ex["BtQCYes"],
  )
  buttons.buttons[bid_qgiveup] = MapleButton::from_resource(
    util_dlg_ex["BtQGiveup"],
  )
  buttons.buttons[bid_qno] = MapleButton::from_resource(util_dlg_ex["BtQNo"])
  buttons.buttons[bid_qstart] = MapleButton::from_resource(
    util_dlg_ex["BtQStart"],
  )
  buttons.buttons[bid_qyes] = MapleButton::from_resource(util_dlg_ex["BtQYes"])
  buttons.buttons[bid_yes] = MapleButton::from_resource(util_dlg_ex["BtYes"])
  let name = Text::new(
    FontId::A11M,
    TextAlignment::CENTER,
    ColorName::WHITE,
    nametag.width(),
  )
  {
    base,
    buttons,
    offset,
    unit_rows,
    row_max,
    show_slider,
    draw_text,
    formatted_text,
    formatted_text_pos,
    timestep,
    top,
    fill,
    bottom,
    nametag,
    min_height,
    t: None,
    name,
    height: 0,
    speaker: Texture::default(),
    content: None,
  }
}

pub fn get_ui_element_base(self : UINpcTalk) -> UIElementBase {
  self.base
}

pub fn draw(self : UINpcTalk, inter : Double) -> Unit {
  let mut drawpos = self.base.position
  self.top.draw(drawpos |> DrawArgument::from_point)
  drawpos = drawpos.shift_y(self.top.height())
  self.fill.draw(DrawArgument::new4(drawpos, Point::new(0, self.height)))
  drawpos = drawpos.shift_y(self.height)
  self.bottom.draw(drawpos |> DrawArgument::from_point)
  drawpos = drawpos.shift_y(self.bottom.height())
  self.buttons.draw(inter, self.base.position)
  let speaker_y = (self.top.height() + self.height + self.bottom.height()) / 2
  let speaker_pos = self.base.position + Point::new(22, 11 + speaker_y)
  let center_pos = speaker_pos + Point::new(self.nametag.width() / 2, 0)
  self.speaker.draw(DrawArgument::new5(center_pos, true))
  self.nametag.draw(speaker_pos |> DrawArgument::from_point)
  self.name.draw(speaker_pos.shift_y(1))
  match self.content {
    Some(content) =>
      if self.show_slider {
        let text_min_height = self.base.position.y + self.top.height() - 1
        let mut init_height = 19
        for element in content.text_content {
          element.draw(
            self.base.position +
            Point::new(162, init_height - self.offset * 248),
            text_y_clip=Range::new(
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
            Point::new(162, init_height - self.offset * 248),
            Range::new(text_min_height, text_min_height + self.height),
          )
          init_height += element.height()
        }
        // TODO: draw slider
      } else {
        let mut init_height = 19
        for element in content.text_button_content {
          element.draw(self.base.position + Point::new(166, init_height))
          init_height += element.height()
        }
        for element in content.text_content {
          element.draw(self.base.position + Point::new(166, init_height))
          init_height += element.height()
        }
      }
    None => ()
  }
}

pub fn update(self : UINpcTalk) -> Unit {
  self.base.update()
  self.buttons.update()
  // TODO: show text gradually when open NPC dialog
}

fn button_pressed(self : UINpcTalk, bid : Int) -> ButtonState {
  self.base.deactivate()
  match self.t {
    Some(t) =>
      match t {
        @npc.TalkType::SEND_NEXT | @npc.TalkType::SEND_OK =>
          if bid == bid_next {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          } else if bid == bid_prev {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          }
        @npc.TalkType::SEND_NEXT_PREV =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), -1).dispatch()
          } else if bid == bid_next {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          } else if bid == bid_prev {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          }
        @npc.TalkType::SEND_YESNO =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), -1).dispatch()
          } else if bid == bid_no {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else if bid == bid_yes {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          }
        @npc.TalkType::SEND_ACCEPT_DECLINE =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), -1).dispatch()
          } else if bid == bid_qno {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else if bid == bid_qyes {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          }
        @npc.TalkType::SEND_GET_TEXT => ()
        @npc.TalkType::SEND_GET_NUMBER =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else if bid == bid_ok {
            new_npc_talk_more_packet(t.int_value(), 1).dispatch()
          }
        @npc.TalkType::SEND_SIMPLE =>
          if bid == bid_close {
            new_npc_talk_more_packet(t.int_value(), 0).dispatch()
          } else {
            let btn = self.content.unwrap().text_button_content[bid -
              bid_text_button]
            new_npc_talk_more_packet_with_selection(btn.option_number).dispatch()
          }
        _ => ()
      }
    None => ()
  }
  match self.content {
    Some(content) =>
      for _, element in content.text_button_content {
        self.buttons.buttons.remove(bid_text_button + element.option_number)
      }
    None => ()
  }
  ButtonState::NORMAL
}

pub fn send_cursor(
  self : UINpcTalk,
  clicked : Bool,
  cursorpos : Point[Int]
) -> CursorState {
  let cursor_relative = cursorpos - self.base.position
  // TODO: check slider
  let estate = self.buttons.send_cursor(
    self.base.position,
    fn(bid) { self.button_pressed(bid) },
    clicked,
    cursorpos,
  )
  if estate == CursorState::CLICKING && clicked {
    match self.content {
      Some(content) =>
        if self.draw_text {
          self.draw_text = false
          content.text.change_text(self.formatted_text)
        } else {
          for element in content.text_button_content.iter() {
            if element.bounds(self.base.position).contains(cursorpos) {
              self.button_pressed(bid_text_button + element.option_number)
              |> ignore
              break
            }
          }
        }
      None => ()
    }
  }
  estate
}

pub fn remove_cursor(self : UINpcTalk) -> Unit {
  self.buttons.remove_cursor()
}

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

pub fn get_type(self : UINpcTalk) -> UIElementType {
  UIElementType::NPC_TALK
}

fn format_text(tx : String, npcid : Int) -> String {
  let mut formatted_text = tx
  let begin = formatted_text.index_of("#p")
  if begin >= 0 {
    let end = formatted_text.index_of("#", from=begin + 1)
    if end >= 0 {
      let namestr = string_loader()
        .load_res(["Npc.img", npcid.to_string(), "name"])
        .get_string()
      formatted_text = formatted_text.substring(end=begin) +
        namestr +
        formatted_text.substring(start=end)
    }
  }
  let begin = formatted_text.index_of("#h")
  if begin >= 0 {
    let end = formatted_text.index_of("#", from=begin + 1)
    if end >= 0 {
      let charstr = Stage::get().get_player().get_name()
      formatted_text = formatted_text.substring(end=begin) +
        charstr +
        formatted_text.substring(start=end)
    }
  }
  let begin = formatted_text.index_of("#t")
  if begin >= 0 {
    let end = formatted_text.index_of("#", from=begin + 1)
    if end >= 0 {
      let b = begin + 2
      let itemid = @strconv.parse_int?(formatted_text.substring(start=b, ~end)).unwrap()
      let itemname = string_loader()
        .load_res(["Consume.img", itemid.to_string(), "name"])
        .get_string()
      formatted_text = formatted_text.substring(end=begin) +
        itemname +
        formatted_text.substring(start=end)
    }
  }
  let mut begin = 0
  while true {
    begin = formatted_text.index_of("#m", from=begin)
    if begin < 0 {
      break
    }
    let end = formatted_text.index_of("#", from=begin + 1)
    if end < 0 {
      break
    }
    let b = begin + 2
    let mapid = @strconv.parse_int?(formatted_text.substring(start=b, ~end)).unwrap()
    let map_info = get_map_info_by_id(mapid)
    formatted_text = formatted_text.substring(end=begin) +
      map_info.name +
      formatted_text.substring(start=end)
    begin = end
  }
  formatted_text
}

pub fn change_text(
  self : UINpcTalk,
  npcid : Int,
  msgtype : Int,
  style_b0 : Int,
  style_b1 : Int,
  speakerbyte : Int,
  tx : String
) -> Unit {
  self.t = @npc.TalkType::from_int(msgtype, style_b0, style_b1)
  self.timestep = 0
  self.draw_text = true
  self.formatted_text_pos = 0
  self.formatted_text = format_text(tx, npcid)
  let content = convert_npc_text(self.formatted_text)
  self.content = content |> @option.some
  for element in content.text_button_content {
    self.buttons.buttons[bid_text_button + element.option_number] = element
  }
  let text_height = content.text.height()
  content.text.change_text("")
  if speakerbyte == 0 {
    let strid = @string_format.extend_id(npcid, 7) + ".img"
    self.speaker = npc_loader().load_res([strid, "stand", "0"])
      |> Texture::from_resource
    let namestr = string_loader()
      .load_res(["Npc.img", npcid.to_string(), "name"])
      .get_string()
    self.name.change_text(namestr)
  } else {
    self.speaker = Texture::default()
    self.name.change_text("")
  }
  self.height = self.min_height + 20
  self.show_slider = false
  if text_height > self.min_height {
    if text_height > max_height {
      self.height = max_height
      self.show_slider = true
      self.row_max = text_height / 248 + 1
      self.unit_rows = 1
      let slider_y = self.top.height() - 7
      // TODO: update slider
      //                 slider_ = Slider(Slider::Type::DEFAULT_SILVER,
      //                                  Range<int16_t>(slider_y, slider_y + height_),
      //                                  top_.width() - 26,
      //                                  unit_rows_,
      //                                  row_max_,
      //                                  onmoved_);
    } else {
      self.height = text_height
    }
  }
  self.reset_content_pos()
  for _, button in self.buttons.buttons {
    button.get_button_base().set_active(false)
    button.get_button_base().set_state(ButtonState::NORMAL)
  }
  let y_cord = self.height + 48
  self.buttons.buttons[bid_close]
  .unwrap()
  .get_button_base()
  ..set_position(Point::new(9, y_cord))
  .set_active(true)
  match self.t {
    Some(t) =>
      match t {
        @npc.TalkType::SEND_OK =>
          self.buttons.buttons[bid_ok]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(469, y_cord))
          .set_active(true)
        @npc.TalkType::SEND_YESNO => {
          let yes_position = Point::new(389, y_cord)
          self.buttons.buttons[bid_yes]
          .unwrap()
          .get_button_base()
          ..set_position(yes_position)
          .set_active(true)
          self.buttons.buttons[bid_no]
          .unwrap()
          .get_button_base()
          ..set_position(yes_position + Point::new(65, 0))
          .set_active(true)
        }
        @npc.TalkType::SEND_NEXT =>
          self.buttons.buttons[bid_next]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(461, y_cord - 30))
          .set_active(true)
        @npc.TalkType::SEND_PREV =>
          self.buttons.buttons[bid_prev]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(367, y_cord))
          .set_active(true)
        @npc.TalkType::SEND_NEXT_PREV => {
          self.buttons.buttons[bid_next]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(461, y_cord - 30))
          .set_active(true)
          self.buttons.buttons[bid_prev]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(367, y_cord))
          .set_active(true)
        }
        @npc.TalkType::SEND_ACCEPT_DECLINE => {
          self.buttons.buttons[bid_qyes]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(386, y_cord))
          .set_active(true)
          self.buttons.buttons[bid_qno]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(451, y_cord))
          .set_active(true)
        }
        _ => ()
      }
    None => ()
  }
  self.base.position = Point::new(
    400 - self.top.width() / 2,
    240 - self.height / 2,
  )
  self.base.dimension = Point::new(self.top.width(), self.height + 120)
}

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
      .set_position(Point::new(162, init_height - self.offset * 248))
      init_height += element.height()
    }
  } else {
    let mut init_height = 19
    for element in content.text_content {
      init_height += element.height()
    }
    for element in content.text_button_content {
      element.get_button_base().set_position(Point::new(166, init_height))
      init_height += element.height()
    }
  }
}

pub fn is_in_range(self : UINpcTalk, cursorpos : Point[Int]) -> Bool {
  self.base.is_in_range(cursorpos)
}

pub fn toggle_active(self : UINpcTalk) -> Unit {
  self.base.toggle_active()
}

pub fn doubleclick(self : UINpcTalk, cursorpos : Point[Int]) -> Unit {

}

fn new_npc_talk_more_packet(lastmsg : Int, response : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NPC_TALK_MORE)
  ..write_byte(lastmsg.to_byte())
  ..write_byte(response.to_byte())
}

fn new_npc_talk_more_packet_with_response(response : String) -> @net.OutPacket {
  new_npc_talk_more_packet(2, 1)..write_string(response)
}

fn new_npc_talk_more_packet_with_selection(selection : Int) -> @net.OutPacket {
  new_npc_talk_more_packet(4, 1)..write_int(selection)
}

fn get_map_info_by_id(mapid : Int) -> NxMapInfo {
  let map_category = get_map_category(mapid)
  let map_info = string_loader().load_res(
    ["Map.img", map_category, mapid.to_string()],
  )
  {
    description: map_info["mapDesc"].get_string(),
    name: map_info["mapName"].get_string(),
    street_name: map_info["streetName"].get_string(),
    full_name: map_info["streetName"].get_string() +
    " : " +
    map_info["mapName"].get_string(),
  }
}

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

struct NxMapInfo {
  description : String
  name : String
  street_name : String
  full_name : String
}

fn convert_npc_text(formatted_text : String) -> NPCTalkContent {
  let s = formatted_text
  let t = s.replace_all(old="\r\n", new="\n").replace_all(old="\r", new="\n")
  let builder = {
    text_content: [],
    text_button_content: [],
    line_color: ColorName::BLACK,
    selection: 0,
  }
  for line in t.split("\n") {
    builder.set_content(line)
  }
  let text = Text::new(
    FontId::A18M,
    TextAlignment::LEFT,
    ColorName::DARKGREY,
    320,
    text=formatted_text,
  )
  {
    text,
    text_content: builder.text_content,
    text_button_content: builder.text_button_content,
    line_color: builder.line_color,
    selection: builder.selection,
  }
}

let max_height = 248

struct NPCTalkContentBuilder {
  text_content : Array[Text]
  text_button_content : Array[TextButton]
  mut line_color : ColorName
  mut selection : Int
}

fn set_content(self : NPCTalkContentBuilder, line : String) -> Unit {
  match try_parse_button_selection(line) {
    Some(selection) => {
      if line.contains("#b") {
        self.line_color = ColorName::BLUE
      }
      self.selection = selection
      let button = TextButton::new(
        Text::new(
          FontId::A18M,
          TextAlignment::LEFT,
          self.line_color,
          320,
          text=line,
        ),
        self.selection,
      )
      self.text_button_content.push(button)
    }
    None => {
      self.text_content.push(
        Text::new(
          FontId::A18M,
          TextAlignment::LEFT,
          ColorName::DARKGREY,
          320,
          text=line,
        ),
      )
      if line.ends_with("#b") {
        self.line_color = ColorName::BLUE
      }
    }
  }
}

fn try_parse_button_selection(line : String) -> Int? {
  let placeholder_start = line.index_of("#L")
  if placeholder_start < 0 {
    return None
  }
  let digit_start = placeholder_start + 2
  let digits = if digit_start + 2 < line.length() &&
    line[digit_start + 2] == '#' {
    line.substring(start=digit_start, end=digit_start + 2)
  } else if digit_start + 1 < line.length() && line[digit_start + 1] == '#' {
    line.substring(start=digit_start, end=digit_start + 1)
  } else {
    return None
  }
  @strconv.parse_int?(digits, base=10).to_option()
}
