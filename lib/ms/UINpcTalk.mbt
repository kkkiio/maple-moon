struct UINpcTalk {
  base : UIElementBase
  buttons : UIButtons[Buttons]
  top : Texture
  fill : Texture
  bottom : Texture
  nametag : Texture
  mut speaker : Texture
  content : NPCTalkContent
  // name:Text
  mut height : Int
  offset : Int
  unit_rows : Int
  row_max : Int
  min_height : Int
  mut show_slider : Bool
  mut draw_text : Bool
  // slider:Slider
  t : @npc.TalkType?
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

struct NPCTalkContent {} derive(Default)

enum Buttons {
  ALL_LEVEL
  CLOSE
  MY_LEVEL
  NEXT
  NO
  OK
  PREV
  QAFTER
  QCNO
  QCYES
  QGIVEUP
  QNO
  QSTART
  QYES
  YES
  TEXT_BUTTON
} derive(Eq, Hash, Show)

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
  buttons.buttons[Buttons::ALL_LEVEL] = MapleButton::from_resource(
    util_dlg_ex["BtAllLevel"],
  )
  buttons.buttons[Buttons::CLOSE] = MapleButton::from_resource(
    util_dlg_ex["BtClose"],
  )
  buttons.buttons[Buttons::MY_LEVEL] = MapleButton::from_resource(
    util_dlg_ex["BtMyLevel"],
  )
  buttons.buttons[Buttons::NEXT] = MapleButton::from_resource(
    util_dlg_ex["BtNext"],
  )
  let quest = ui_window2["Quest"]
  buttons.buttons[Buttons::NO] = MapleButton::from_resource(quest["BtNo"])
  buttons.buttons[Buttons::OK] = MapleButton::from_resource(util_dlg_ex["BtOK"])
  buttons.buttons[Buttons::PREV] = MapleButton::from_resource(
    util_dlg_ex["BtPrev"],
  )
  buttons.buttons[Buttons::QAFTER] = MapleButton::from_resource(
    util_dlg_ex["BtQAfter"],
  )
  buttons.buttons[Buttons::QCNO] = MapleButton::from_resource(
    util_dlg_ex["BtQCNo"],
  )
  buttons.buttons[Buttons::QCYES] = MapleButton::from_resource(
    util_dlg_ex["BtQCYes"],
  )
  buttons.buttons[Buttons::QGIVEUP] = MapleButton::from_resource(
    util_dlg_ex["BtQGiveup"],
  )
  buttons.buttons[Buttons::QNO] = MapleButton::from_resource(
    util_dlg_ex["BtQNo"],
  )
  buttons.buttons[Buttons::QSTART] = MapleButton::from_resource(
    util_dlg_ex["BtQStart"],
  )
  buttons.buttons[Buttons::QYES] = MapleButton::from_resource(
    util_dlg_ex["BtQYes"],
  )
  buttons.buttons[Buttons::YES] = MapleButton::from_resource(
    util_dlg_ex["BtYes"],
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
    height: 0,
    speaker: Texture::default(),
    content: NPCTalkContent::default(),
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
  // self.name.draw(center_pos + Point::new(0, -4))
  if self.show_slider {
    let text_min_height = self.base.position.y + self.top.height() - 1
    let init_height = 19
    // TODO: draw text
  } else {
    let init_height = 19
    // TODO: draw text
  }
}

pub fn update(self : UINpcTalk) -> Unit {
  self.base.update()
  self.buttons.update()
  // TODO: update text
}

fn button_pressed(self : UINpcTalk, bid : Buttons) -> ButtonState {
  self.base.deactivate()
  match self.t {
    Some(t) =>
      match t {
        @npc.TalkType::SEND_NEXT | @npc.TalkType::SEND_OK =>
          match bid {
            Buttons::NEXT =>
              new_npc_talk_more_packet(t.int_value(), 1).dispatch()
            Buttons::PREV =>
              new_npc_talk_more_packet(t.int_value(), 0).dispatch()
            _ => ()
          }
        @npc.TalkType::SEND_NEXT_PREV =>
          match bid {
            Buttons::CLOSE =>
              new_npc_talk_more_packet(t.int_value(), -1).dispatch()
            Buttons::NEXT =>
              new_npc_talk_more_packet(t.int_value(), 1).dispatch()
            Buttons::PREV =>
              new_npc_talk_more_packet(t.int_value(), 0).dispatch()
            _ => ()
          }
        @npc.TalkType::SEND_YESNO =>
          match bid {
            Buttons::CLOSE =>
              new_npc_talk_more_packet(t.int_value(), -1).dispatch()
            Buttons::NO => new_npc_talk_more_packet(t.int_value(), 0).dispatch()
            Buttons::YES =>
              new_npc_talk_more_packet(t.int_value(), 1).dispatch()
            _ => ()
          }
        @npc.TalkType::SEND_ACCEPT_DECLINE =>
          match bid {
            Buttons::CLOSE =>
              new_npc_talk_more_packet(t.int_value(), -1).dispatch()
            Buttons::QNO =>
              new_npc_talk_more_packet(t.int_value(), 0).dispatch()
            Buttons::QYES =>
              new_npc_talk_more_packet(t.int_value(), 1).dispatch()
            _ => ()
          }
        @npc.TalkType::SEND_GET_TEXT => ()
        @npc.TalkType::SEND_GET_NUMBER =>
          match bid {
            Buttons::CLOSE =>
              new_npc_talk_more_packet(t.int_value(), 0).dispatch()
            Buttons::OK => new_npc_talk_more_packet(t.int_value(), 1).dispatch()
            _ => ()
          }

        //             case TalkType::SEND_SIMPLE:
        //                 // Type = 4
        //                 switch (buttonid) {
        //                     case Buttons::CLOSE:
        //                         fn_npc_talk_more(type_, 0);
        //                         break;
        //                     default:
        //                         fn_npc_talk_more(content_.text_button_content_[buttonid -
        //                                                                        Buttons::TEXT_BUTTON].get_option_number());
        //                         break;
        //                 }
        //                 break;
        @npc.TalkType::SEND_SIMPLE =>
          match bid {
            Buttons::CLOSE =>
              new_npc_talk_more_packet(t.int_value(), 0).dispatch()
            _ =>
              // new_npc_talk_more_packet(self.t.int_value(), self.t.text_button_content().get(bid - Buttons::TEXT_BUTTON).unwrap().get_option_number()).dispatch()
              // TODO: content
              ()
          }
        _ => ()
      }
    None => ()
  }
  //         for (auto &element: content_.text_button_content_) {
  //             auto it = buttons_.find(Buttons::TEXT_BUTTON + element.get_option_number());
  //             if (it != buttons_.end()) {
  //                 buttons_.erase(it);
  //             }
  //         }
  //TODO:content

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
    if self.draw_text {
      self.draw_text = false
      // self.content.text.change_text(self.formatted_text)
    } else {
      // for element in self.content.text_button_content.iter() {
      //   if element.bounds(self.base.position).contains(cursorpos) {
      //     self.button_pressed(
      //       Buttons::TEXT_BUTTON + element.get_option_number(),
      //     )
      //     break
      //   }
      // }
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

fn format_text(self : UINpcTalk, tx : String, npcid : Int) -> String {
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
  let t = @npc.TalkType::from_int(msgtype, style_b0, style_b1)
  self.timestep = 0
  self.draw_text = true
  self.formatted_text_pos = 0
  self.formatted_text = self.format_text(tx, npcid)
  // self.content = convert_npc_text(self.formatted_text)

  //         for (auto &element: content_.text_button_content_) {
  //             buttons_[Buttons::TEXT_BUTTON +
  //                      element.get_option_number()] = std::make_unique<TextButton>(element);
  //         }

  //         content_.text_ = Text(Text::Font::A18M,
  //                               Text::Alignment::LEFT,
  //                               Color::Name::DARKGREY,
  //                               formatted_text_,
  //                               320);

  //         int16_t text_height = content_.text_.height();

  //         content_.text_.change_text("");

  if speakerbyte == 0 {
    let strid = @string_format.extend_id(npcid, 7) + ".img"
    self.speaker = npc_loader().load_res([strid, "stand", "0"])
      |> Texture::from_resource
    let namestr = string_loader()
      .load_res(["Npc.img", npcid.to_string(), "name"])
      .get_string()
    // TODO: name
  } else {
    self.speaker = Texture::default()
    // TODO: name
  }
  self.height = self.min_height + 20
  self.show_slider = false

  //         if (text_height > min_height_) {
  //             if (text_height > MAX_HEIGHT_) {
  //                 height_ = MAX_HEIGHT_;
  //                 show_slider_ = true;
  //                 row_max_ = text_height / 248 + 1;
  //                 unit_rows_ = 1;

  //                 int16_t slider_y = top_.height() - 7;
  //                 slider_ = Slider(Slider::Type::DEFAULT_SILVER,
  //                                  Range<int16_t>(slider_y, slider_y + height_),
  //                                  top_.width() - 26,
  //                                  unit_rows_,
  //                                  row_max_,
  //                                  onmoved_);
  //             } else {
  //                 height_ = text_height;
  //             }
  //         }

  //         reset_content_pos();

  for _, button in self.buttons.buttons {
    button.get_button_base().set_active(false)
    button.get_button_base().set_state(ButtonState::NORMAL)
  }
  let y_cord = self.height + 48
  self.buttons.buttons[Buttons::CLOSE]
  .unwrap()
  .get_button_base()
  ..set_position(Point::new(9, y_cord))
  .set_active(true)
  match t {
    Some(t) =>
      match t {
        @npc.TalkType::SEND_OK =>
          self.buttons.buttons[Buttons::OK]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(469, y_cord))
          .set_active(true)
        @npc.TalkType::SEND_YESNO => {
          let yes_position = Point::new(389, y_cord)
          self.buttons.buttons[Buttons::YES]
          .unwrap()
          .get_button_base()
          ..set_position(yes_position)
          .set_active(true)
          self.buttons.buttons[Buttons::NO]
          .unwrap()
          .get_button_base()
          ..set_position(yes_position + Point::new(65, 0))
          .set_active(true)
        }
        @npc.TalkType::SEND_NEXT =>
          self.buttons.buttons[Buttons::NEXT]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(461, y_cord - 30))
          .set_active(true)
        @npc.TalkType::SEND_PREV =>
          self.buttons.buttons[Buttons::PREV]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(367, y_cord))
          .set_active(true)
        @npc.TalkType::SEND_NEXT_PREV => {
          self.buttons.buttons[Buttons::NEXT]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(461, y_cord - 30))
          .set_active(true)
          self.buttons.buttons[Buttons::PREV]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(367, y_cord))
          .set_active(true)
        }
        @npc.TalkType::SEND_ACCEPT_DECLINE => {
          self.buttons.buttons[Buttons::QYES]
          .unwrap()
          .get_button_base()
          ..set_position(Point::new(386, y_cord))
          .set_active(true)
          self.buttons.buttons[Buttons::QNO]
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
