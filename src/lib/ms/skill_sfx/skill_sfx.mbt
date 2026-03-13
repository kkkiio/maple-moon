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
pub let skill_sfx_event_bus : @event.Events[SkillSfxEvent] = @event.Events::new()

///|
fn init {
  skill_sfx_event_bus.register()
}

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
  skill_sfx_event_bus.send(event)
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
/// Clear all buffered skill sound events.
pub fn clear_events() -> Unit {
  skill_sfx_event_bus.clear()
}
