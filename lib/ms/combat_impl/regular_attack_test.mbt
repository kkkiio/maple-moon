///|
test "Regular Attack" {
  let character = @character.Character::new(
    1234567890,
    @char_look.CharLook::new(
      @char_look.LookEntry::default(),
      @char_look.Body::default(),
      @char_look.Hair::default(),
      @char_look.Face::default(),
      @types.BodyDrawInfo::default(),
    ),
    "kkkiio",
    @ui.NumberSet::default(),
    get_skilllevel=fn(_skill_id) { 1 },
    @char_stats.CharStats::new(
      @char_stats.StatsEntry::default(),
      fn() { @weapon.Type::SWORD_1H },
      @job.Job::new(
        100, // Swordsman
        @job.Level::FIRST,
        Map::new(),
      ),
      Map::new(),
      Map::new(),
    ),
    get_integer_attackspeed=fn() { 1 },
  )
  let attack = make_regular_attack(
    character,
    0,
    @combat.AttackType::CLOSE,
    false,
  )
  @json.inspect!(attack, content={
    "t": { "$tag": "CLOSE" },
    "damagetype": { "$tag": "DMG_WEAPON", "0": 0, "1": 0 },
    "critical": 0.05,
    "ignoredef": 0,
    "accuracy": 0,
    "playerlevel": 0,
    "hitcount": 1,
    "mobcount": 1,
    "speed": 1,
    "stance": 0,
    "skill": 0,
    "bullet": 0,
    "origin": [0, 0],
    "range": { "lt": [0, 0], "rb": [0, 0] },
    "hrange": 1,
    "toleft": true,
  })
}
