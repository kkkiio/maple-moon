///|
/// UI System: Handles loading and managing UI resources like NumberSet.
/// Similar pattern to char_look_mod.mbt

///|
using @io_service {submit_background_task}

///|
using @utils {type Future}

///|
/// UI Module that holds loaded UI resources.
pub struct UIMod {
  number_set : NumberSet
}

///|
/// Async load the UI module.
pub async fn UIMod::load() -> UIMod {
  let number_set = NumberSet::load()
  { number_set, }
}

///|
/// Get the loaded NumberSet.
pub fn UIMod::get_number_set(self : UIMod) -> NumberSet {
  self.number_set
}

///|
/// Module singleton reference.
let ui_mod : Ref[UIMod?] = Ref::new(None)

///|
/// Get the loaded UI module if available.
pub fn get_ui_module() -> UIMod? {
  ui_mod.val
}

///|
/// Get the loaded NumberSet if UI module is loaded.
pub fn get_number_set() -> NumberSet? {
  ui_mod.val.map(fn(m) { m.number_set })
}

///|
/// Loading future reference.
let loading_mod_future : Ref[Future[Result[UIMod, Error]]?] = Ref::new(None)

///|
/// UI system update function. Call this in the game loop to load UI resources.
/// Once loaded, resources can be accessed via get_ui_module() or get_number_set().
pub fn ui_system(_delta : Double) -> Unit {
  // Already loaded
  if ui_mod.val is Some(_) {
    return
  }

  // Check if loading is in progress
  guard loading_mod_future.val is Some(fut) else {
    // Start loading
    loading_mod_future.val = Some(submit_background_task(UIMod::load))
    return
  }

  // Poll the future
  guard fut.poll() is Some(res) else { return }

  // Handle result
  match res {
    Ok(m) => ui_mod.val = Some(m)
    Err(e) => abort("loading UI module failed, error=\{e}")
  }
}
