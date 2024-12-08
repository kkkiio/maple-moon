///|
pub fn ui_window_2_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("ui_window_2")
}

///|
pub fn ui_window_4_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("ui_window_4")
}

///|
pub fn common_ui_loader() -> @resource.SyncLoader {
  @resource.SyncLoader::new("common_ui")
}
