struct RecalculateStatsHandler {
  stage : Stage
}

pub fn RecalculateStatsHandler::new(stage : Stage) -> RecalculateStatsHandler {
  { stage, }
}

pub fn handle(self : RecalculateStatsHandler, _recv : @net.InPacket) -> Unit! {
  guard let Some(player) = self.stage.get_player() else { None => return  }
  player.recalc_stats(false)
  if false {
    fail!("WORKAROUND")
  }
}
