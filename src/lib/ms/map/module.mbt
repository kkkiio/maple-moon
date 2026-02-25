///|
struct Module {
  portals_animations : MapPortalAnimations
}

///|
pub fn Module::load() -> Module {
  let portals_animations = MapPortalAnimations::load()
  { portals_animations, }
}

///|
pub fn Module::get_portals_animations(self : Module) -> MapPortalAnimations {
  self.portals_animations
}
