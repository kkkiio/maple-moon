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
  is_invincible(Self) -> Bool
  get_phobj(Self) -> @physics.PhysicsObject
  damage(Self, MobAttack) -> MobAttackResult
}

///|
pub(open) trait CombatCharacter {
  get_character(Self) -> Character
  get_stats(Self) -> CharStats
  get_inventory(Self) -> &Inventory
  get_skill_book(Self) -> &SkillBook
  can_attack(Self) -> Bool
  rush(Self, Double) -> Unit
}
