///|
pub fn make_change_stats_handler(
  stat_handler_map : Map[@maple_stat.Id, @game_mod.StatHandler],
  recalc_stats_fn : () -> Unit
) -> (@net.Opcode, (@net.InPacket) -> Unit) {
  @net.make_handler(
    @net.CHANGE_STATS,
    fn(recv : @net.InPacket) { parse_stat_changes!(stat_handler_map, recv) },
    fn(changes : StatChanges) {
      handle_change_stats(stat_handler_map, changes, recalc_stats_fn)
    },
    log_recv=true,
  )
}

///|
type StatChanges Map[@maple_stat.Id, Int] derive(Show)

///|
fn parse_stat_changes(
  stat_handler_map : Map[@maple_stat.Id, @game_mod.StatHandler],
  recv : @net.InPacket
) -> StatChanges! {
  recv.read_bool!() |> ignore // 'itemreaction'
  let updatemask = recv.read_int!()
  let changes = {}
  for it in @maple_stat.codes {
    let (stat_id, stat_mask) = it
    if (updatemask & stat_mask) != 0 {
      match stat_handler_map[stat_id] {
        Some(it) => {
          let { parse_fn, .. } = it
          let res = parse_fn!(recv)
          changes[stat_id] = res
        }
        None => @log.warn({ "stat": stat_id }, "unhandled stat")
      }
    }
  }
  StatChanges(changes)
}

///|
fn handle_change_stats(
  stat_handler_map : Map[@maple_stat.Id, @game_mod.StatHandler],
  changes : StatChanges,
  recalc_stats_fn : () -> Unit
) -> Unit {
  let updatemask = changes._
  let mut recalculate = false
  for stat_id, v in changes._ {
    match stat_handler_map[stat_id] {
      Some(it) => {
        let { update_fn, .. } = it
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
