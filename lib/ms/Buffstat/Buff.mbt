pub enum Id {
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
} derive(Eq, Debug, Compare)

pub let all_buff_id_map : @immut/sorted_map.Map[Id, Int] = @immut/sorted_map.from_array(
  [
    (NONE, 0),
    (MORPH, 1),
    (RECOVERY, 2),
    (MAPLE_WARRIOR, 3),
    (STANCE, 4),
    (SHARP_EYES, 5),
    (MANA_REFLECTION, 6),
    (SHADOW_CLAW, 7),
    (INFINITY_, 8),
    (HOLY_SHIELD, 9),
    (HAMSTRING, 10),
    (BLIND, 11),
    (CONCENTRATE, 12),
    (ECHO_OF_HERO, 13),
    (GHOST_MORPH, 14),
    (AURA, 15),
    (CONFUSE, 16),
    (BERSERK_FURY, 17),
    (DIVINE_BODY, 18),
    (SPARK, 19),
    (FINALATTACK, 20),
    (BATTLESHIP, 21),
    (WATK, 22),
    (WDEF, 23),
    (MATK, 24),
    (MDEF, 25),
    (ACC, 26),
    (AVOID, 27),
    (HANDS, 28),
    (SHOWDASH, 29),
    (SPEED, 30),
    (JUMP, 31),
    (MAGIC_GUARD, 32),
    (DARKSIGHT, 33),
    (BOOSTER, 34),
    (POWERGUARD, 35),
    (HYPERBODYHP, 36),
    (HYPERBODYMP, 37),
    (INVINCIBLE, 38),
    (SOULARROW, 39),
    (STUN, 40),
    (POISON, 41),
    (SEAL, 42),
    (DARKNESS, 43),
    (COMBO, 44),
    (SUMMON, 45),
    (WK_CHARGE, 46),
    (DRAGONBLOOD, 47),
    (HOLY_SYMBOL, 48),
    (MESOUP, 49),
    (SHADOWPARTNER, 50),
    (PICKPOCKET, 51),
    (PUPPET, 52),
    (MESOGUARD, 53),
    (WEAKEN, 54),
    (DASH, 55),
    (DASH2, 56),
    (ELEMENTAL_RESET, 57),
    (ARAN_COMBO, 58),
    (COMBO_DRAIN, 59),
    (COMBO_BARRIER, 60),
    (BODY_PRESSURE, 61),
    (SMART_KNOCKBACK, 62),
    (PYRAMID_PQ, 63),
    (ENERGY_CHARGE, 64),
    (MONSTER_RIDING, 65),
    (HOMING_BEACON, 66),
    (SPEED_INFUSION, 67),
    (ZOMBIFY, 68),
    (CURSE, 69),
    (SEDUCE, 70),
    (SLOW, 71),
  ],
)

pub fn int_value(self : Id) -> Int {
  all_buff_id_map[self].unwrap()
}

pub fn hash(self : Id) -> Int {
  self.int_value()
}

pub fn is_disease(buff_id : Id) -> Bool {
  diseases.find(buff_id).is_empty().not()
}

pub let first_codes : @immut/hashmap.Map[Id, Int64] = @immut/hashmap.from_array(
  [
    (Id::DASH2, 0x8000000000000L),
    (Id::DASH, 0x10000000000000L),
    (Id::ELEMENTAL_RESET, 0x200000000L),
    (Id::ARAN_COMBO, 0x1000000000L),
    (Id::COMBO_DRAIN, 0x2000000000L),
    (Id::COMBO_BARRIER, 0x4000000000L),
    (Id::BODY_PRESSURE, 0x8000000000L),
    (Id::SMART_KNOCKBACK, 0x10000000000L),
    (Id::PYRAMID_PQ, 0x20000000000L),
    (Id::ENERGY_CHARGE, 0x4000000000000L),
    (Id::MONSTER_RIDING, 0x20000000000000L),
    (Id::HOMING_BEACON, 0x80000000000000L),
    (Id::SPEED_INFUSION, 0x100000000000000L),
  ],
)

pub let second_codes : @immut/hashmap.Map[Id, Int64] = @immut/hashmap.from_array(
  [
    (Id::NONE, 0x0L),
    (Id::SLOW, 0x1L),
    (Id::MORPH, 0x2L),
    (Id::RECOVERY, 0x4L),
    (Id::MAPLE_WARRIOR, 0x8L),
    (Id::STANCE, 0x10L),
    (Id::SHARP_EYES, 0x20L),
    (Id::MANA_REFLECTION, 0x40L),
    (Id::SEDUCE, 0x80L),
    (Id::SHADOW_CLAW, 0x100L),
    (Id::INFINITY_, 0x200L),
    (Id::HOLY_SHIELD, 0x400L),
    (Id::HAMSTRING, 0x800L),
    (Id::BLIND, 0x1000L),
    (Id::CONCENTRATE, 0x2000L),
    (Id::ECHO_OF_HERO, 0x8000L),
    (Id::GHOST_MORPH, 0x20000L),
    (Id::AURA, 0x40000L),
    (Id::ZOMBIFY, 0x4000L),
    (Id::CONFUSE, 0x80000L),
    (Id::BERSERK_FURY, 0x8000000L),
    (Id::DIVINE_BODY, 0x10000000L),
    (Id::SPARK, 0x20000000L),
    (Id::FINALATTACK, 0x80000000L),
    (Id::BATTLESHIP, 0xA00000040L),
    (Id::WATK, 0x100000000L),
    (Id::WDEF, 0x200000000L),
    (Id::MATK, 0x400000000L),
    (Id::MDEF, 0x800000000L),
    (Id::ACC, 0x1000000000L),
    (Id::AVOID, 0x2000000000L),
    (Id::HANDS, 0x4000000000L),
    (Id::SHOWDASH, 0x4000000000L),
    (Id::SPEED, 0x8000000000L),
    (Id::JUMP, 0x10000000000L),
    (Id::MAGIC_GUARD, 0x20000000000L),
    (Id::DARKSIGHT, 0x40000000000L),
    (Id::BOOSTER, 0x80000000000L),
    (Id::POWERGUARD, 0x100000000000L),
    (Id::HYPERBODYHP, 0x200000000000L),
    (Id::HYPERBODYMP, 0x400000000000L),
    (Id::INVINCIBLE, 0x800000000000L),
    (Id::SOULARROW, 0x1000000000000L),
    (Id::STUN, 0x2000000000000L),
    (Id::POISON, 0x4000000000000L),
    (Id::SEAL, 0x8000000000000L),
    (Id::DARKNESS, 0x10000000000000L),
    (Id::COMBO, 0x20000000000000L),
    (Id::SUMMON, 0x20000000000000L),
    (Id::WK_CHARGE, 0x40000000000000L),
    (Id::DRAGONBLOOD, 0x80000000000000L),
    (Id::HOLY_SYMBOL, 0x100000000000000L),
    (Id::MESOUP, 0x200000000000000L),
    (Id::SHADOWPARTNER, 0x400000000000000L),
    (Id::PICKPOCKET, 0x800000000000000L),
    (Id::PUPPET, 0x800000000000000L),
    (Id::MESOGUARD, 0x1000000000000000L),
    (Id::WEAKEN, 0x4000000000000000L),
    (Id::CURSE, 0x8000000000000000L),
  ],
)

pub let diseases : @immut/hashmap.Map[Id, Int64] = @immut/hashmap.from_array(
  [
    (Id::SLOW, 0x1L),
    (Id::SEDUCE, 0x80L),
    // (Id::FISHABLE, 0x100), 
    (Id::CURSE, 0x8000000000000000L),
    (Id::ZOMBIFY, 0x4000L),
    (Id::CONFUSE, 0x80000L),
    (Id::STUN, 0x2000000000000L),
    (Id::POISON, 0x4000000000000L),
    (Id::SEAL, 0x8000000000000L),
    (Id::DARKNESS, 0x10000000000000L),
    (Id::WEAKEN, 0x4000000000000000L),
  ],
)

pub struct Buff {
  stat : Id
  value : Int
  skillid : Int
  duration : Int
}

pub fn Buff::make(
  stat : Id,
  value : Int,
  skillid : Int,
  duration : Int
) -> Buff {
  { stat, value, skillid, duration }
}

pub fn Buff::default() -> Buff {
  { stat: Id::NONE, value: 0, skillid: 0, duration: 0 }
}
