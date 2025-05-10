///| QuestLog stores information on the quest log of an individual character
struct QuestLog {
  started : Map[Int, String]
  in_progress : Map[Int, (Int, String)]
  completed : Map[Int, Int64]
} derive(Show)

///|
pub fn parse_questlog(recv : @net.InPacket) -> QuestLog! {
  let started_size = recv.read_short!()
  let started = {}
  let in_progress = {}
  let completed = {}
  let mut last_started : Int? = None
  for i in 0..<started_size {
    let quest_id = recv.read_short!()
    let progress_data = recv.read_string!()
    if started.contains(quest_id) {
      guard last_started is Some(successor_quest)
      in_progress[successor_quest] = (quest_id, progress_data)
    } else {
      started[quest_id] = progress_data
      last_started = Some(quest_id)
    }
  }
  let completed_size = recv.read_short!()
  for i in 0..<completed_size {
    let quest_id = recv.read_short!()
    let completion_time = recv.read_long!()
    completed[quest_id] = completion_time
  }
  { started, in_progress, completed }
}

// what does negative quest id mean?
// 29005: "", 27010: "9", 29014: "", 27019: "3", -31066: ""
