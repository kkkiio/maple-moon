///|
fn make_talk_packet(c : TalkChoice) -> @net.OutPacket {
  match c {
    TalkChoice::SEND_SIMPLE(option~) =>
      match option {
        Some(option) => new_npc_talk_more_packet_with_selection(option)
        None => new_npc_talk_more_packet(TalkType::SEND_SIMPLE.int_value(), 0)
      }
    TalkChoice::SEND_YESNO(answer~) =>
      new_npc_talk_more_packet(
        TalkType::SEND_YESNO.int_value(),
        match answer {
          Some(true) => 1
          Some(false) => 0
          None => -1
        },
      )
    TalkChoice::SEND_NEXT(next~) =>
      new_npc_talk_more_packet(
        TalkType::SEND_NEXT.int_value(),
        match next {
          Some(_) => 1
          None => -1
        },
      )
    TalkChoice::SEND_PREV(prev~) =>
      new_npc_talk_more_packet(
        TalkType::SEND_PREV.int_value(),
        match prev {
          Some(_) => 1
          None => -1
        },
      )
    TalkChoice::SEND_OK(ok~) =>
      new_npc_talk_more_packet(
        TalkType::SEND_OK.int_value(),
        match ok {
          Some(_) => 1
          None => -1
        },
      )
    // TalkChoice::SEND_NEXT_PREV(next~) =>
    //   new_npc_talk_more_packet(
    //     TalkType::SEND_NEXT_PREV.int_value(),
    //     match next {
    //       Some(true) => 1
    //       Some(false) => 0
    //       None => -1
    //     },
    //   )
  }
}
