///|
struct SkillSound {
  skill_id : Int
}

///|
fn SkillSound::SkillSound(skill_id : Int) -> SkillSound {
  { skill_id, }
}

///|
fn SkillSound::play_use(self : SkillSound) -> Unit {
  @skill_sfx.play_skill_use(self.skill_id)
}

///|
fn SkillSound::play_hit(self : SkillSound) -> Unit {
  @skill_sfx.play_skill_hit(self.skill_id)
}
