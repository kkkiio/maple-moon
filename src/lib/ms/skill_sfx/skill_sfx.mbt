///|
pub(all) enum SkillSfxStage {
  Use
  Hit
} derive(Eq, Show)

///|
pub(all) struct SkillSfxEvent {
  skill_id : Int
  stage : SkillSfxStage
  path : String
} derive(Eq, Show)

///|
pub fn SkillSfxEvent::skill_id(self : SkillSfxEvent) -> Int {
  self.skill_id
}

///|
pub fn SkillSfxEvent::stage(self : SkillSfxEvent) -> SkillSfxStage {
  self.stage
}

///|
pub fn SkillSfxEvent::path(self : SkillSfxEvent) -> String {
  self.path
}

///|
let skill_sfx_queue : Array[SkillSfxEvent] = []

///|
let skill_sfx_readers : Map[Int, Int] = {}

///|
let next_reader_id : Ref[Int] = Ref::new(1)

///|
fn skill_sfx_stage_name(stage : SkillSfxStage) -> String {
  match stage {
    Use => "Use"
    Hit => "Hit"
  }
}

///|
fn skill_sfx_path(skill_id : Int, stage : SkillSfxStage) -> String {
  "/assets/sound/Skill.img/\{skill_id.to_string()}/\{skill_sfx_stage_name(stage)}.mp3"
}

///|
fn push_event(event : SkillSfxEvent) -> Unit {
  skill_sfx_queue.push(event)
}

///|
fn play_skill_sfx(skill_id : Int, stage : SkillSfxStage) -> Unit {
  if skill_id <= 0 {
    @log.warn("invalid skill sfx skill id", data={
      "skill_id": skill_id,
      "stage": stage,
    })
    return
  }
  let path = skill_sfx_path(skill_id, stage)
  push_event({ skill_id, stage, path })
  let entity = @entity.Entity::new()
  @audio.attach_audio(
    entity,
    @audio.AudioPlayer::from_path(path),
    settings=@audio.PlaybackSettings::despawn().with_volume(0.1),
  )
}

///|
/// Play the `Use` sound for the given skill.
pub fn play_skill_use(skill_id : Int) -> Unit {
  play_skill_sfx(skill_id, Use)
}

///|
/// Play the `Hit` sound for the given skill.
pub fn play_skill_hit(skill_id : Int) -> Unit {
  play_skill_sfx(skill_id, Hit)
}

///|
/// Register a reader cursor for skill sound events.
pub fn register_reader() -> Int {
  let reader_id = next_reader_id.val
  next_reader_id.val += 1
  skill_sfx_readers.set(reader_id, skill_sfx_queue.length())
  reader_id
}

///|
/// Unregister a skill sound event reader cursor.
pub fn unregister_reader(reader_id : Int) -> Unit {
  ignore(skill_sfx_readers.remove(reader_id))
}

///|
/// Read unread skill sound events for a reader and advance its cursor.
pub fn read_new_events(reader_id : Int) -> Array[SkillSfxEvent] {
  guard skill_sfx_readers.get(reader_id) is Some(cursor) else { return [] }
  let events = []
  let queue_len = skill_sfx_queue.length()
  for i in cursor..<queue_len {
    events.push(skill_sfx_queue[i])
  }
  skill_sfx_readers.set(reader_id, queue_len)
  events
}

///|
/// Garbage-collect consumed skill sound events.
pub fn gc_consumed_events() -> Unit {
  if skill_sfx_readers.is_empty() {
    skill_sfx_queue.clear()
    return
  }
  let mut min_cursor = skill_sfx_queue.length()
  for _, cursor in skill_sfx_readers {
    if cursor < min_cursor {
      min_cursor = cursor
    }
  }
  guard min_cursor > 0 else { return }

  let retained = []
  for i in min_cursor..<skill_sfx_queue.length() {
    retained.push(skill_sfx_queue[i])
  }
  skill_sfx_queue.clear()
  for event in retained {
    skill_sfx_queue.push(event)
  }

  let reader_ids = skill_sfx_readers.keys().to_array()
  for reader_id in reader_ids {
    guard skill_sfx_readers.get(reader_id) is Some(cursor) else { continue }
    skill_sfx_readers.set(reader_id, cursor - min_cursor)
  }
}

///|
/// Clear all buffered skill sound events.
pub fn clear_events() -> Unit {
  skill_sfx_queue.clear()
  let reader_ids = skill_sfx_readers.keys().to_array()
  for reader_id in reader_ids {
    skill_sfx_readers.set(reader_id, 0)
  }
}
