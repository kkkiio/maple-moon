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
