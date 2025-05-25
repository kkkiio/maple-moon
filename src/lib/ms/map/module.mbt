///|
struct Module {
  portals_animations : MapPortalAnimations
  mini_map_ui_resource : MiniMapUIResource
}

///|
pub fn Module::load() -> @utils.Future[Module] {
  let portals_animations_fut = MapPortalAnimations::load()
  let mini_map_ui_resource_fut = MiniMapUIResource::load()
  portals_animations_fut
  .combine(mini_map_ui_resource_fut)
  .map(fn(it) { { portals_animations: it.0, mini_map_ui_resource: it.1 } })
}

///|
pub fn get_portals_animations(self : Module) -> MapPortalAnimations {
  self.portals_animations
}

///|
pub fn Module::new_mini_map_ui(
  self : Module,
  ui_model : @ui.UIModel,
  on_state_changed : () -> Unit
) -> MiniMapUI {
  MiniMapUI::new(self.mini_map_ui_resource, ui_model, on_state_changed)
}
