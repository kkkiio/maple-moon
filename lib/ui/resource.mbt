///|
pub fn ui_window_2_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("UI/UIWindow2.img")
}

///|
pub fn ui_window_4_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("UI/UIWindow4.img")
}

///|
pub fn common_ui_loader() -> @resource.SyncLoader {
  @resource.SyncLoader::new("UI") // TODO: split into multiple async loaders
}
