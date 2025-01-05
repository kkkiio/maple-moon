struct Module {
  portals_animations : MapPortalAnimations
}

pub fn Module::load() -> @utils.Future[Module] {
  let portals_animations = MapPortalAnimations::load()
  portals_animations.map(fn(it) { { portals_animations: it } })
}

pub fn get_portals_animations(self : Module) -> MapPortalAnimations {
  self.portals_animations
}
