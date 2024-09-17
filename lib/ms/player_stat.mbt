struct RecalculateStatsHandler {
  stage : Stage
}

pub fn RecalculateStatsHandler::new(stage : Stage) -> RecalculateStatsHandler {
  { stage, }
}

pub fn handle(self : RecalculateStatsHandler, _recv : @net.InPacket) -> Unit! {
  self.stage.get_player().unwrap().recalc_stats!(false)
}
