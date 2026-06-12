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
pub fn UIMod::load() -> UIMod {
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
let ui_mod : Ref[UIMod?] = Ref(None)

///|
/// Loading future reference.
let loading_mod_future : Ref[Future[Result[UIMod, Error]]?] = Ref(None)

///|
/// UI system update function. Call this in the game loop to load UI resources.
/// Once loaded, resources can be accessed via get_ui_module() or get_number_set().
pub fn ui_system(_world : @ecs.World) -> Unit {
  // Already loaded
  if ui_mod.val is Some(_) {
    return
  }

  // Check if loading is in progress
  guard loading_mod_future.val is Some(fut) else {
    // Start loading
    loading_mod_future.val = Some(
      submit_background_task(fn() { UIMod::load() }),
    )
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

///|
/// 显示漂浮数字（如伤害值、治疗量等）. 如果数值 (<= 0)，显示 "MISS".
pub fn show_number(
  t : NumberType,
  damage : Int,
  starty : Int,
  x? : Int = 0,
) -> Unit {
  guard ui_mod.val is Some(ui_mod) else { return }
  ui_mod.number_set.show_number(t, damage, starty, x~)
}
