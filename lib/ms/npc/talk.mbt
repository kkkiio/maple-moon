pub enum TalkType {
  SEND_TEXT_ONLY
  SEND_YESNO
  SEND_SIMPLE
  SEND_ACCEPT_DECLINE
  SEND_OK
  SEND_NEXT
  SEND_NEXT_PREV
  SEND_PREV
  SEND_GET_TEXT
  SEND_GET_NUMBER
} derive(Show, Eq)

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
      return Some(SEND_TEXT_ONLY)
    }
    1 => return Some(SEND_YESNO)
    4 => return Some(SEND_SIMPLE)
    12 => return Some(SEND_ACCEPT_DECLINE)
    _ => return None
  }
}

pub fn int_value(self : TalkType) -> Int {
  match self {
    SEND_TEXT_ONLY => 0
    SEND_YESNO => 1
    SEND_SIMPLE => 4
    SEND_ACCEPT_DECLINE => 12
    // below are determined by 2 style bytes when msgtype = 0
    SEND_OK => 13
    SEND_NEXT => 14
    SEND_NEXT_PREV => 15
    SEND_PREV => 16
    SEND_GET_TEXT => 17
    SEND_GET_NUMBER => 18
  }
}

pub fn hash(self : TalkType) -> Int {
  self.int_value()
}

pub fn hash_combine(self : TalkType, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}
