enum AttackType {
  CLOSE
  RANGED
  MAGIC
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
  mobcount : Int
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
  first_oid : Int
  last_oid : Int
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

pub fn AttackResult::new(attack : AttackResult) -> AttackResult {
  {
    t: attack.t,
    attacker: 0,
    mobcount: 0,
    hitcount: attack.hitcount,
    skill: attack.skill,
    charge: 0,
    level: 0,
    display: 0,
    stance: 0,
    speed: 0,
    damage_lines: {},
    first_oid: 0,
    last_oid: 0,
    bullet: attack.bullet,
    toleft: attack.toleft,
  }
}
