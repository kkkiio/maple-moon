///|
pub(open) trait Inventory {
  recalc_stats(Self, @weapon.Type) -> Unit
  get_stat(Self, @maple_stat.EquipStatId) -> Int
  has_projectile(Self) -> Bool
  get_bulletid(Self) -> Int
  get_bulletcount(Self) -> Int
}

///|
pub(open) trait SkillBook {
  get_level(Self, Int) -> Int
  set_skill(Self, Int, Int, Int, Int) -> Unit
}

///|
pub(all) struct MockInventory {} derive(Default)

///|
pub impl Inventory for MockInventory with recalc_stats(_, _) {

}

///|
pub impl Inventory for MockInventory with get_stat(_, _) {
  0
}

///|
pub impl Inventory for MockInventory with has_projectile(_) {
  false
}

///|
pub impl Inventory for MockInventory with get_bulletid(_) {
  0
}

///|
pub impl Inventory for MockInventory with get_bulletcount(_) {
  0
}

///|
pub(all) struct MockSkillBook {} derive(Default)

///|
pub impl SkillBook for MockSkillBook with get_level(_, _) {
  0
}

///|
pub impl SkillBook for MockSkillBook with set_skill(_, _, _, _, _) {

}
