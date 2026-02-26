///|
fn make_talk_message(c : TalkChoice) -> @server_proto.NpcTalkMoreMessage {
  match c {
    TalkChoice::SEND_SIMPLE(option~) =>
      match option {
        Some(option) =>
          {
            lastmsg: TalkType::SEND_SIMPLE.int_value(),
            response: 1,
            selection: Some(option),
          }
        None =>
          {
            lastmsg: TalkType::SEND_SIMPLE.int_value(),
            response: 0,
            selection: None,
          }
      }
    TalkChoice::SEND_YESNO(answer~) =>
      {
        lastmsg: TalkType::SEND_YESNO.int_value(),
        response: match answer {
          Some(true) => 1
          Some(false) => 0
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_NEXT(next~) =>
      {
        lastmsg: TalkType::SEND_NEXT.int_value(),
        response: match next {
          Some(_) => 1
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_PREV(prev~) =>
      {
        lastmsg: TalkType::SEND_PREV.int_value(),
        response: match prev {
          Some(_) => 1
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_OK(ok~) =>
      {
        lastmsg: TalkType::SEND_OK.int_value(),
        response: match ok {
          Some(_) => 1
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_NEXT_PREV(next~) =>
      {
        lastmsg: TalkType::SEND_NEXT_PREV.int_value(),
        response: match next {
          Some(true) => 1
          Some(false) => 0
          None => -1
        },
        selection: None,
      }
  }
}

///|
pub fn on_npc_talk_choice(c : TalkChoice) -> Unit {
  @game_server.send(make_talk_message(c))
}
