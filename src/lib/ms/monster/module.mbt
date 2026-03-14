///|
struct Module {
  map_mobs : MapMobs
  mob_combat : MobCombat
}

///|
pub fn Module::new() -> Module {
  let mobs = MapMobs::new()
  { map_mobs: mobs, mob_combat: MobCombat::new(mobs) }
}

///|
pub fn Module::get_map_mobs(self : Module) -> MapMobs {
  self.map_mobs
}

