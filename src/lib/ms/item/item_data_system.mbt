///|
pub struct ItemDataSystem {
  pending_item_loads : Ref[Map[Int, @utils.Future[Result[ItemData, Error]]]]
  item_load_errors : Ref[Map[Int, String]]
}

///|
/// Creates an item-data system.
pub fn ItemDataSystem::new() -> ItemDataSystem {
  {
    pending_item_loads: Ref(Map([])),
    item_load_errors: Ref(Map([])),
  }
}

///|
let item_data_system_ref : Ref[ItemDataSystem?] = Ref(None)

///|
/// Replaces the global item-data system instance.
pub fn set_item_data_system(system : ItemDataSystem) -> Unit {
  item_data_system_ref.val = Some(system)
}

///|
/// Gets the global item-data system instance.
pub fn get_item_data_system() -> ItemDataSystem {
  if item_data_system_ref.val is Some(system) {
    return system
  }
  let system = ItemDataSystem::new()
  item_data_system_ref.val = Some(system)
  system
}

///|
fn ItemDataSystem::get_load_error(self : ItemDataSystem, id : Int) -> String? {
  self.item_load_errors.val.get(id)
}

///|
fn ItemDataSystem::clear_tracking(self : ItemDataSystem, id : Int) -> Unit {
  self.pending_item_loads.val.remove(id) |> ignore
  self.item_load_errors.val.remove(id) |> ignore
}

///|
/// Request background loading for one item id.
///
/// This function is idempotent:
/// - already loaded: no-op
/// - already loading: no-op
/// - previously failed: no-op (strict mode keeps the first error)
pub fn ItemDataSystem::request(self : ItemDataSystem, id : Int) -> Unit {
  if cache.contains(id) ||
    self.pending_item_loads.val.contains(id) ||
    self.item_load_errors.val.contains(id) {
    return
  }
  self.pending_item_loads.val.set(
    id,
    @io_service.submit_background_task(fn() {
      ItemData::load_item_data(id)
    }),
  )
}

///|
/// Request background loading for all item ids.
pub fn ItemDataSystem::request_many(
  self : ItemDataSystem,
  ids : Array[Int],
) -> Unit {
  for id in ids {
    self.request(id)
  }
}

///|
/// Return `true` only when all requested items are loaded.
/// Panic immediately if any requested item has a recorded load error.
pub fn ItemDataSystem::all_requested_ready_or_fail(
  self : ItemDataSystem,
  ids : Array[Int],
) -> Bool {
  for id in ids {
    match self.get_load_error(id) {
      Some(err) =>
        @log.fatal("item preload failed", data={ "item_id": id, "error": err })
      None => ()
    }
    if ItemData::get_loaded(id) is None {
      return false
    }
  }
  true
}

///|
/// Poll pending background item-loading tasks and persist failures.
pub fn ItemDataSystem::run(self : ItemDataSystem, _delta : Double) -> Unit {
  let completed_ids : Array[Int] = []
  for id, fut in self.pending_item_loads.val {
    match fut.poll() {
      Some(Ok(_)) => completed_ids.push(id)
      Some(Err(err)) => {
        let err_text = err.to_string()
        self.item_load_errors.val.set(id, err_text)
        completed_ids.push(id)
        @log.error("failed to load item data", data={
          "item_id": id,
          "error": err_text,
        })
      }
      None => ()
    }
  }
  for id in completed_ids {
    self.pending_item_loads.val.remove(id) |> ignore
  }
}

///|
/// Get preloaded item data. Panics when data is not ready or failed to load.
pub fn request_item_data(id : Int) -> ItemData {
  match ItemData::get_loaded(id) {
    Some(data) => data
    None =>
      match get_item_data_system().get_load_error(id) {
        Some(err) =>
          @log.fatal("item data request failed", data={
            "item_id": id,
            "error": err,
          })
        None => @log.fatal("item data not preloaded", data={ "item_id": id })
      }
  }
}

///|
/// Returns item data only when already loaded.
///
/// This function is safe for UI code paths where preload may lag behind
/// incoming game messages:
/// - always enqueue a background load request
/// - return `None` until the cache is ready
pub fn request_item_data_if_ready(id : Int) -> ItemData? {
  let system = get_item_data_system()
  system.request(id)
  ItemData::get_loaded(id)
}

///|
/// Inserts preloaded item data into cache for a specific item id.
///
/// This is intended for tests that load resources with custom loaders and then
/// inject the result into the shared item-data cache.
pub fn ItemData::add_item_data(id : Int, item_data : ItemData) -> Unit {
  if item_data.item_id != id {
    @log.fatal("item data id mismatch", data={
      "expected_item_id": id,
      "actual_item_id": item_data.item_id,
    })
  }
  cache.set(id, item_data)
  get_item_data_system().clear_tracking(id)
}
