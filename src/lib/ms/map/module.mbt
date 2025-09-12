///|
struct Module {
  portals_animations : MapPortalAnimations
  mini_map_ui_resource : MiniMapUIResource
}

///|
pub fn Module::load() -> Module {
  let portals_animations = MapPortalAnimations::load()
  let mini_map_ui_resource = MiniMapUIResource::load()
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
) -> MiniMapUI {
  MiniMapUI::new(self.mini_map_ui_resource, ui_model)
}
