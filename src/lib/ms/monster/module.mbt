///|
struct Module {
  map_mobs : MapMobs
}

///|
pub fn Module::new() -> Module {
  let mobs = MapMobs::new()
  { map_mobs: mobs }
}

///|
pub fn Module::get_map_mobs(self : Module) -> MapMobs {
  self.map_mobs
}
