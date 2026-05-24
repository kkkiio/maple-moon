///|
using @combat_proto {type MobAttack, type MobAttackResult}

///|
using @character {type Character}

///|
using @char_stats {type CharStats}

///|
using @legacy_types {trait Inventory, trait SkillBook}

///|
pub(open) trait DamagableCharacter {
  fn is_invincible(Self) -> Bool
  fn get_phobj(Self) -> @physics.PhysicsObject
  fn damage(Self, MobAttack) -> MobAttackResult
}

///|
pub(open) trait CombatCharacter {
  fn get_character(Self) -> Character
  fn get_stats(Self) -> CharStats
  fn get_inventory(Self) -> &Inventory
  fn get_skill_book(Self) -> &SkillBook
  fn can_attack(Self) -> Bool
  fn rush(Self, Double) -> Unit
}
