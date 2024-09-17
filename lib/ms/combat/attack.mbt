pub enum AttackType {
  CLOSE
  RANGED
  MAGIC
} derive(Eq)

pub enum AttackDamageType {
  DMG_WEAPON
  DMG_MAGIC
  DMG_FIXED
} derive(Eq)

pub struct Attack {
  t : AttackType
  mut damagetype : AttackDamageType
  mindamage : Double
  maxdamage : Double
  critical : Double
  ignoredef : Double
  matk : Int
  accuracy : Int
  fixdamage : Int
  playerlevel : Int
  mut hitcount : Int
  mut mobcount : Int
  speed : Int
  mut stance : Int
  mut skill : Int
  bullet : Int
  origin : @struct.Point[Int]
  mut range : @struct.Rectangle[Int]
  hrange : Double
  toleft : Bool
}

pub fn Attack::default() -> Attack {
  {
    t: AttackType::CLOSE,
    damagetype: AttackDamageType::DMG_WEAPON,
    mindamage: 1.0,
    maxdamage: 1.0,
    critical: 0.0,
    ignoredef: 0.0,
    matk: 0,
    accuracy: 0,
    fixdamage: 0,
    playerlevel: 1,
    hitcount: 0,
    mobcount: 0,
    speed: 0,
    stance: 0,
    skill: 0,
    bullet: 0,
    origin: @struct.Point::default(),
    range: @struct.Rectangle::default(),
    hrange: 1.0,
    toleft: false,
  }
}

/// an attack coming from a mob
pub struct MobAttack {
  t : AttackType
  watk : Int
  matk : Int
  mobid : Int
  oid : Int
  origin : @struct.Point[Int]
  valid : Bool
}

/// Create a mob attack for touch damage.
pub fn MobAttack::new(
  watk : Int,
  origin : @struct.Point[Int],
  mobid : Int,
  oid : Int
) -> MobAttack {
  { t: AttackType::CLOSE, watk, matk: 0, mobid, oid, origin, valid: true }
}

pub fn MobAttack::default() -> MobAttack {
  {
    t: AttackType::CLOSE,
    watk: 0,
    matk: 0,
    mobid: 0,
    oid: 0,
    origin: @struct.Point::default(),
    valid: false,
  }
}

/// result of a mob's attack
pub struct MobAttackResult {
  damage : Int
  mobid : Int
  oid : Int
  direction : Int
}

pub fn MobAttackResult::new(
  attack : MobAttack,
  damage : Int,
  direction : Int
) -> MobAttackResult {
  { damage, mobid: attack.mobid, oid: attack.oid, direction }
}

/// result of a player's attack
pub struct AttackResult {
  t : AttackType
  attacker : Int
  mut mobcount : Int
  hitcount : Int
  skill : Int
  charge : Int
  bullet : Int
  level : Int
  display : Int
  stance : Int
  speed : Int
  toleft : Bool
  damage_lines : Map[Int, Array[(Int, Bool)]]
  mut first_oid : Int
  mut last_oid : Int
}

pub fn AttackResult::default() -> AttackResult {
  {
    t: AttackType::CLOSE,
    attacker: 0,
    mobcount: 0,
    hitcount: 1,
    skill: 0,
    charge: 0,
    bullet: 0,
    level: 0,
    display: 0,
    stance: 0,
    speed: 0,
    toleft: false,
    damage_lines: {},
    first_oid: 0,
    last_oid: 0,
  }
}

pub fn AttackResult::new(attack : Attack) -> AttackResult {
  {
    t: attack.t,
    attacker: 0,
    mobcount: 0,
    hitcount: attack.hitcount,
    skill: attack.skill,
    charge: 0,
    level: 0,
    display: 0,
    stance: attack.stance,
    speed: attack.speed,
    damage_lines: {},
    first_oid: 0,
    last_oid: 0,
    bullet: attack.bullet,
    toleft: attack.toleft,
  }
}

/// an attack coming from a user
pub struct AttackUser {
  skill_level : Int
  level : Int
  second_weapon : Bool
  flip : Bool
}
