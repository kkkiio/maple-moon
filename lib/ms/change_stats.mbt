///|
struct ChangeStatsHandler {
  stat_handler_map : Map[
    @maple_stat.Id,
    (@maple_stat.Id, @net.InPacket) -> Bool!,
  ]
  recalc_stats_fn : () -> Unit
}

///|
fn handle_change_stats(
  self : ChangeStatsHandler,
  recv : @net.InPacket
) -> Unit! {
  recv.read_bool!() |> ignore // 'itemreaction'
  let updatemask = recv.read_int!()
  let mut recalculate = false
  for it in @maple_stat.codes {
    let (stat_id, stat_mask) = it
    if (updatemask & stat_mask) != 0 {
      match self.stat_handler_map[stat_id] {
        Some(handler) => {
          let res = handler!(stat_id, recv)
          recalculate = res || recalculate
        }
        None => @log.warn({ "stat": stat_id }, "unhandled stat")
      }
    }
  }
  if recalculate {
    (self.recalc_stats_fn)()
  }
}
