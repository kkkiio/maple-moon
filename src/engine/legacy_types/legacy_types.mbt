///|
pub(open) trait Inventory {
  fn recalc_stats(Self, @weapon.Type) -> Unit
  fn get_stat(Self, @maple_stat.EquipStatId) -> Int
  fn has_projectile(Self) -> Bool
  fn get_bulletid(Self) -> Int
  fn get_bulletcount(Self) -> Int
}

///|
pub(open) trait SkillBook {
  fn get_level(Self, Int) -> Int
  fn set_skill(Self, Int, Int, Int, Int) -> Unit
}

///|
pub(all) struct MockInventory {} derive(Default)

///|
pub impl Inventory for MockInventory with fn recalc_stats(_, _) {

}

///|
pub impl Inventory for MockInventory with fn get_stat(_, _) {
  0
}

///|
pub impl Inventory for MockInventory with fn has_projectile(_) {
  false
}

///|
pub impl Inventory for MockInventory with fn get_bulletid(_) {
  0
}

///|
pub impl Inventory for MockInventory with fn get_bulletcount(_) {
  0
}

///|
pub(all) struct MockSkillBook {} derive(Default)

///|
pub impl SkillBook for MockSkillBook with fn get_level(_, _) {
  0
}

///|
pub impl SkillBook for MockSkillBook with fn set_skill(_, _, _, _, _) {

}

///|
/// SkillBook that returns max level (20) for all skills (no leveling system)
pub(all) struct MaxLevelSkillBook {} derive(Default)

///|
pub impl SkillBook for MaxLevelSkillBook with fn get_level(_, _) {
  20
}

///|
pub impl SkillBook for MaxLevelSkillBook with fn set_skill(_, _, _, _, _) {

}
