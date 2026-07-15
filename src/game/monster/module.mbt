///|
struct Module {
  map_mobs : MapMobs
}

///|
pub fn Module::Module() -> Module {
  let mobs = MapMobs()
  { map_mobs: mobs }
}

///|
pub fn Module::get_map_mobs(self : Module) -> MapMobs {
  self.map_mobs
}
