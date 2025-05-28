///|
priv trait QuestCheck: Show {
  check(Self, CheckContext) -> Result[Unit, String]
}

///|
priv struct CheckContext {
  player : @player.Player
  log : PlayerQuestLog
  quest_id : Int
  phase : Int
}

///|
priv struct MinLevelCheck {
  min_level : Int
} derive(Show)

///|
impl QuestCheck for MinLevelCheck with check(self, context) {
  let level = context.player.character.stats.get_stat(@maple_stat.Id::LEVEL)
  if level < self.min_level {
    return Err("Expected level at least \{self.min_level}, got \{level}")
  }
  Ok(())
}

///|
priv struct NpcCheck {
  npc : Int
} derive(Show)

///|
impl QuestCheck for NpcCheck with check(_self, _context) {
  // server will check if the player is near the npc
  Ok(())
}

///|
priv struct IntervalMinutesCheck {
  interval_minutes : Int
} derive(Show)

///|
impl QuestCheck for IntervalMinutesCheck with check(_self, _context) {
  Err("not implemented")
}

///| Checks if a character meets the progress conditions defined by the quest's infoEx data.
///
/// This method validates quest progress by comparing the character's current progress values
/// against the expected values defined in the quest's infoEx data. The progress values are
/// retrieved from either this quest or another quest specified by infoNumber.
priv struct InfoExCheck {
  info_ex : Array[InfoEx]
} derive(Show)

///|
impl QuestCheck for InfoExCheck with check(self, context) {
  if self.info_ex.is_empty() {
    return Ok(())
  }
  let progress_data = match context.log.get_quest(context.quest_id) {
    Some(InProgress(started_quest)) =>
      started_quest.get_phase_progress(context.phase)
    Some(Completed(_)) => return Err("Quest completed") // TODO: support repeatable quest
    None => return Err("Quest not started")
  }
  // I don't know how to parse progress_data...
  let expected_progress = self.info_ex.iter().map(fn(it) { it.value }).join("") // TODO: check if this is correct
  if expected_progress != progress_data {
    return Err("Expected progress \{expected_progress}, got \{progress_data}")
  }
  Ok(())
}

///|
priv struct QuestsStatusCheck {
  quest_status_map : Map[Int, QuestStatus]
} derive(Show)

///|
impl QuestCheck for QuestsStatusCheck with check(self, context) {
  for quest_id, expected_status in self.quest_status_map {
    let stated_quest = context.log.get_quest(quest_id)
    let quest_status = match stated_quest {
      Some(InProgress(_)) => QuestStatus::InProgress
      Some(Completed(_)) => QuestStatus::Completed
      None => QuestStatus::NotStarted
    }
    if quest_status != expected_status {
      return Err(
        "Expected quest \{quest_id} status \{expected_status}, got \{quest_status}",
      )
    }
  }
  Ok(())
}

///|
priv struct JobsCheck {
  jobs : Array[@job.JobId]
} derive(Show)

///|
impl QuestCheck for JobsCheck with check(self, context) {
  let player_job = context.player.stats.get_job().get_id()
  for job_id in self.jobs {
    if player_job == job_id || player_job == @job.JobId::GM {
      return Ok(())
    }
  }
  return Err("Expected job \{self.jobs}, got \{player_job}")
}

///|
priv struct MonsterHuntCheck {
  monster_hunts : Array[MonHuntCheck]
} derive(Show)

///|
impl QuestCheck for MonsterHuntCheck with check(self, context) {
  if self.monster_hunts.is_empty() {
    return Ok(())
  }
  let progress_data = match context.log.get_quest(context.quest_id) {
    Some(InProgress(started_quest)) =>
      started_quest.get_phase_progress(context.phase)
    Some(Completed(_)) => return Err("Quest completed") // TODO: support repeatable quest
    None => return Err("Quest not started")
  }
  if check_mob_progress_data?(progress_data) is Err(e) {
    return Err(e.to_string())
  }
  for i, monster_hunt in self.monster_hunts {
    // Each monster hunt uses 3 digits in the progress string
    let start_pos = i * 3
    let current_count = try
      @strconv.parse_int!(
        progress_data.substring(start=start_pos, end=start_pos + 3),
        base=10,
      ) catch {
      e => return Err("Invalid progress data: \{e}")
    }
    if current_count < monster_hunt.count {
      return Err(
        "Monster hunt incomplete: need \{monster_hunt.count} of monster \{monster_hunt.id}, have \{current_count}",
      )
    }
  }
  Ok(())
}

///| progress data is a 3-digit string that contains kill counts for each monster
fn check_mob_progress_data(progress_data : @string.StringView) -> Unit! {
  guard progress_data.iter().all(fn(it) { @char.is_ascii_digit(it) }) &&
    progress_data.length() % 3 == 0 else {
    fail!("Invalid progress data: \{progress_data}")
  }

}
