///|
pub(all) enum StatId {
  NONE
  MORPH
  RECOVERY
  MAPLE_WARRIOR
  STANCE
  SHARP_EYES
  MANA_REFLECTION
  SHADOW_CLAW
  INFINITY_
  HOLY_SHIELD
  HAMSTRING
  BLIND
  CONCENTRATE
  ECHO_OF_HERO
  GHOST_MORPH
  AURA
  CONFUSE
  BERSERK_FURY
  DIVINE_BODY
  SPARK
  FINALATTACK
  BATTLESHIP
  WATK
  WDEF
  MATK
  MDEF
  ACC
  AVOID
  HANDS
  SHOWDASH
  SPEED
  JUMP
  MAGIC_GUARD
  DARKSIGHT
  BOOSTER
  POWERGUARD
  HYPERBODYHP
  HYPERBODYMP
  INVINCIBLE
  SOULARROW
  STUN
  POISON
  SEAL
  DARKNESS
  COMBO
  SUMMON
  WK_CHARGE
  DRAGONBLOOD
  HOLY_SYMBOL
  MESOUP
  SHADOWPARTNER
  PICKPOCKET
  PUPPET
  MESOGUARD
  WEAKEN
  DASH
  DASH2
  ELEMENTAL_RESET
  ARAN_COMBO
  COMBO_DRAIN
  COMBO_BARRIER
  BODY_PRESSURE
  SMART_KNOCKBACK
  PYRAMID_PQ
  ENERGY_CHARGE
  MONSTER_RIDING
  HOMING_BEACON
  SPEED_INFUSION
  ZOMBIFY
  CURSE
  SEDUCE
  SLOW
} derive(Eq, Compare)

///|
pub fn int_value(self : StatId) -> Int {
  match self {
    NONE => 0
    MORPH => 1
    RECOVERY => 2
    MAPLE_WARRIOR => 3
    STANCE => 4
    SHARP_EYES => 5
    MANA_REFLECTION => 6
    SHADOW_CLAW => 7
    INFINITY_ => 8
    HOLY_SHIELD => 9
    HAMSTRING => 10
    BLIND => 11
    CONCENTRATE => 12
    ECHO_OF_HERO => 13
    GHOST_MORPH => 14
    AURA => 15
    CONFUSE => 16
    BERSERK_FURY => 17
    DIVINE_BODY => 18
    SPARK => 19
    FINALATTACK => 20
    BATTLESHIP => 21
    WATK => 22
    WDEF => 23
    MATK => 24
    MDEF => 25
    ACC => 26
    AVOID => 27
    HANDS => 28
    SHOWDASH => 29
    SPEED => 30
    JUMP => 31
    MAGIC_GUARD => 32
    DARKSIGHT => 33
    BOOSTER => 34
    POWERGUARD => 35
    HYPERBODYHP => 36
    HYPERBODYMP => 37
    INVINCIBLE => 38
    SOULARROW => 39
    STUN => 40
    POISON => 41
    SEAL => 42
    DARKNESS => 43
    COMBO => 44
    SUMMON => 45
    WK_CHARGE => 46
    DRAGONBLOOD => 47
    HOLY_SYMBOL => 48
    MESOUP => 49
    SHADOWPARTNER => 50
    PICKPOCKET => 51
    PUPPET => 52
    MESOGUARD => 53
    WEAKEN => 54
    DASH => 55
    DASH2 => 56
    ELEMENTAL_RESET => 57
    ARAN_COMBO => 58
    COMBO_DRAIN => 59
    COMBO_BARRIER => 60
    BODY_PRESSURE => 61
    SMART_KNOCKBACK => 62
    PYRAMID_PQ => 63
    ENERGY_CHARGE => 64
    MONSTER_RIDING => 65
    HOMING_BEACON => 66
    SPEED_INFUSION => 67
    ZOMBIFY => 68
    CURSE => 69
    SEDUCE => 70
    SLOW => 71
  }
}

///|
pub fn hash(self : StatId) -> Int {
  self.int_value()
}

///|
pub fn hash_combine(self : StatId, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
pub fn is_disease(buff_id : StatId) -> Bool {
  not(diseases.find(buff_id).is_empty())
}

///|
pub let first_codes : @immut/hashmap.T[StatId, Int64] = @immut/hashmap.from_array([
    (StatId::DASH2, 0x8000000000000L),
    (StatId::DASH, 0x10000000000000L),
    (StatId::ELEMENTAL_RESET, 0x200000000L),
    (StatId::ARAN_COMBO, 0x1000000000L),
    (StatId::COMBO_DRAIN, 0x2000000000L),
    (StatId::COMBO_BARRIER, 0x4000000000L),
    (StatId::BODY_PRESSURE, 0x8000000000L),
    (StatId::SMART_KNOCKBACK, 0x10000000000L),
    (StatId::PYRAMID_PQ, 0x20000000000L),
    (StatId::ENERGY_CHARGE, 0x4000000000000L),
    (StatId::MONSTER_RIDING, 0x20000000000000L),
    (StatId::HOMING_BEACON, 0x80000000000000L),
    (StatId::SPEED_INFUSION, 0x100000000000000L),
  ],
)

///|
pub let second_codes : @immut/hashmap.T[StatId, Int64] = @immut/hashmap.from_array([
    (StatId::NONE, 0x0L),
    (StatId::SLOW, 0x1L),
    (StatId::MORPH, 0x2L),
    (StatId::RECOVERY, 0x4L),
    (StatId::MAPLE_WARRIOR, 0x8L),
    (StatId::STANCE, 0x10L),
    (StatId::SHARP_EYES, 0x20L),
    (StatId::MANA_REFLECTION, 0x40L),
    (StatId::SEDUCE, 0x80L),
    (StatId::SHADOW_CLAW, 0x100L),
    (StatId::INFINITY_, 0x200L),
    (StatId::HOLY_SHIELD, 0x400L),
    (StatId::HAMSTRING, 0x800L),
    (StatId::BLIND, 0x1000L),
    (StatId::CONCENTRATE, 0x2000L),
    (StatId::ECHO_OF_HERO, 0x8000L),
    (StatId::GHOST_MORPH, 0x20000L),
    (StatId::AURA, 0x40000L),
    (StatId::ZOMBIFY, 0x4000L),
    (StatId::CONFUSE, 0x80000L),
    (StatId::BERSERK_FURY, 0x8000000L),
    (StatId::DIVINE_BODY, 0x10000000L),
    (StatId::SPARK, 0x20000000L),
    (StatId::FINALATTACK, 0x80000000L),
    (StatId::BATTLESHIP, 0xA00000040L),
    (StatId::WATK, 0x100000000L),
    (StatId::WDEF, 0x200000000L),
    (StatId::MATK, 0x400000000L),
    (StatId::MDEF, 0x800000000L),
    (StatId::ACC, 0x1000000000L),
    (StatId::AVOID, 0x2000000000L),
    (StatId::HANDS, 0x4000000000L),
    (StatId::SHOWDASH, 0x4000000000L),
    (StatId::SPEED, 0x8000000000L),
    (StatId::JUMP, 0x10000000000L),
    (StatId::MAGIC_GUARD, 0x20000000000L),
    (StatId::DARKSIGHT, 0x40000000000L),
    (StatId::BOOSTER, 0x80000000000L),
    (StatId::POWERGUARD, 0x100000000000L),
    (StatId::HYPERBODYHP, 0x200000000000L),
    (StatId::HYPERBODYMP, 0x400000000000L),
    (StatId::INVINCIBLE, 0x800000000000L),
    (StatId::SOULARROW, 0x1000000000000L),
    (StatId::STUN, 0x2000000000000L),
    (StatId::POISON, 0x4000000000000L),
    (StatId::SEAL, 0x8000000000000L),
    (StatId::DARKNESS, 0x10000000000000L),
    (StatId::COMBO, 0x20000000000000L),
    (StatId::SUMMON, 0x20000000000000L),
    (StatId::WK_CHARGE, 0x40000000000000L),
    (StatId::DRAGONBLOOD, 0x80000000000000L),
    (StatId::HOLY_SYMBOL, 0x100000000000000L),
    (StatId::MESOUP, 0x200000000000000L),
    (StatId::SHADOWPARTNER, 0x400000000000000L),
    (StatId::PICKPOCKET, 0x800000000000000L),
    (StatId::PUPPET, 0x800000000000000L),
    (StatId::MESOGUARD, 0x1000000000000000L),
    (StatId::WEAKEN, 0x4000000000000000L),
    (StatId::CURSE, 0x8000000000000000L),
  ],
)

///|
pub let diseases : @immut/hashmap.T[StatId, Int64] = @immut/hashmap.from_array([
  (StatId::SLOW, 0x1L),
  (StatId::SEDUCE, 0x80L),
  // (Id::FISHABLE, 0x100), 
  (StatId::CURSE, 0x8000000000000000L),
  (StatId::ZOMBIFY, 0x4000L),
  (StatId::CONFUSE, 0x80000L),
  (StatId::STUN, 0x2000000000000L),
  (StatId::POISON, 0x4000000000000L),
  (StatId::SEAL, 0x8000000000000L),
  (StatId::DARKNESS, 0x10000000000000L),
  (StatId::WEAKEN, 0x4000000000000000L),
])

///|
pub struct Buff {
  stat : StatId
  value : Int
  skillid : Int
  duration : Int
}

///|
pub fn Buff::make(
  stat : StatId,
  value : Int,
  skillid : Int,
  duration : Int
) -> Buff {
  { stat, value, skillid, duration }
}

///|
pub fn Buff::default() -> Buff {
  { stat: StatId::NONE, value: 0, skillid: 0, duration: 0 }
}
