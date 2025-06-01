///|
pub fn make_change_stats_handler(
  stat_handler_map : Map[@maple_stat.Id, @game_mod.StatHandler],
  recalc_stats_fn : () -> Unit
) -> (@net.Opcode, (@net.InPacket) -> Unit) {
  @net.make_handler(@net.CHANGE_STATS, parse_stat_changes, fn(
    changes : StatChanges
  ) {
    handle_change_stats(stat_handler_map, changes, recalc_stats_fn)
  })
}

///|
priv type StatChanges Map[@maple_stat.Id, Int] derive(Show, ToJson)

///|
fn parse_stat_changes(recv : @net.InPacket) -> StatChanges! {
  recv.read_bool!() |> ignore // 'itemreaction'
  let updatemask = recv.read_uint!()
  let changes = {}
  for stat_id in @maple_stat.all_stats {
    let stat_mask = stat_id.int_value().reinterpret_as_uint()
    if (updatemask & stat_mask) != 0 {
      let res = parse_value!(recv, stat_id)
      changes[stat_id] = res
    }
  }
  recv.check_finished!()
  StatChanges(changes)
}

///|
fn handle_change_stats(
  stat_handler_map : Map[@maple_stat.Id, @game_mod.StatHandler],
  changes : StatChanges,
  recalc_stats_fn : () -> Unit
) -> Unit {
  let mut recalculate = false
  for stat_id, v in changes._ {
    match stat_handler_map.get(stat_id) {
      Some(update_fn) => {
        let res = update_fn(v)
        recalculate = res || recalculate
      }
      None => @log.warn({ "stat": stat_id }, "unhandled stat")
    }
  }
  if recalculate {
    recalc_stats_fn()
  }
}

///|
fn parse_value(recv : @net.InPacket, id : @maple_stat.Id) -> Int! {
  match id {
    @maple_stat.Id::SKIN => recv.read_byte!()
    @maple_stat.Id::FACE => recv.read_int!()
    @maple_stat.Id::HAIR => recv.read_int!()
    @maple_stat.Id::LEVEL => recv.read_byte!()
    @maple_stat.Id::JOB => recv.read_short!()
    @maple_stat.Id::STR => recv.read_short!()
    @maple_stat.Id::DEX => recv.read_short!()
    @maple_stat.Id::INT => recv.read_short!()
    @maple_stat.Id::LUK => recv.read_short!()
    @maple_stat.Id::HP => recv.read_short!()
    @maple_stat.Id::MAXHP => {
      let res = recv.read_short!()
      // if res <= 0 {
      //   fail!("invalid maxhp=\{res}")
      // }
      res
    }
    @maple_stat.Id::MP => recv.read_short!()
    @maple_stat.Id::MAXMP => recv.read_short!()
    @maple_stat.Id::AP => recv.read_short!()
    @maple_stat.Id::SP => recv.read_short!()
    @maple_stat.Id::EXP => recv.read_int!()
    @maple_stat.Id::FAME => recv.read_short!()
    @maple_stat.Id::MESO => recv.read_int!()
    @maple_stat.Id::PET => recv.read_int!()
    @maple_stat.Id::GACHAEXP => recv.read_int!()
  }
}

///|
test "parse stat changes" {
  let recv = b"\x1f\x00\x01\xd0\xfc\x01\x00\x07\x29\x00\x06\x00\x84\x00\x84\x00\x47\x00\x47\x00\x00\x00\x00\x00\x19\x00\x00\x00"
    |> @net.InPacket::new()
  inspect!(
    recv.read_ushort!() |> @net.Opcode::from_int!(),
    content="CHANGE_STATS",
  )
  let changes = parse_stat_changes!(recv)
  @json.inspect!(changes, content={
    "LEVEL": 7,
    "STR": 41,
    "DEX": 6,
    "HP": 132,
    "MAXHP": 132,
    "MP": 71,
    "MAXMP": 71,
    "AP": 0,
    "SP": 0,
    "EXP": 25,
  })
}
