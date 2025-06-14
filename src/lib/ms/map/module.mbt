///|
struct Module {
  portals_animations : MapPortalAnimations
  mini_map_ui_resource : MiniMapUIResource
}

///|
pub async fn Module::load() -> Module raise {
  let portals_animations_fut = MapPortalAnimations::load()
  let mini_map_ui_resource_fut = MiniMapUIResource::load()
  let (portals_animations, mini_map_ui_resource) = (
    portals_animations_fut, mini_map_ui_resource_fut,
  )
  { portals_animations, mini_map_ui_resource }
}

///|
pub fn Module::get_portals_animations(self : Module) -> MapPortalAnimations {
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
