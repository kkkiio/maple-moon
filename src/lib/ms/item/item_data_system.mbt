///|
let consume_bundle_files : Array[String] = [
  "0200.img", "0201.img", "0202.img", "0203.img", "0204.img", "0205.img", "0206.img",
  "0207.img", "0210.img", "0221.img", "0228.img", "0229.img", "0233.img", "0234.img",
  "0238.img",
]

///|
let etc_bundle_files : Array[String] = [
  "0400.img", "0401.img", "0402.img", "0403.img", "0413.img", "0416.img",
]

///|
pub struct ItemDataSystem {
  item_loader : @resource.AsyncLoader
  pending_item_loads : Ref[Map[Int, @utils.Future[Result[ItemData, Error]]]]
  item_load_errors : Ref[Map[Int, String]]
  consume_etc_preload_discovery : Ref[@utils.Future[Result[Array[Int], Error]]?]
  consume_etc_preload_ids : Ref[Array[Int]]
  consume_etc_preload_requested : Ref[Bool]
}

///|
/// Creates an item-data system with an injected item loader.
pub fn ItemDataSystem::new(
  item_loader : @resource.AsyncLoader,
) -> ItemDataSystem {
  {
    item_loader,
    pending_item_loads: Ref::new(Map::new()),
    item_load_errors: Ref::new(Map::new()),
    consume_etc_preload_discovery: Ref::new(None),
    consume_etc_preload_ids: Ref::new([]),
    consume_etc_preload_requested: Ref::new(false),
  }
}

///|
let item_data_system_ref : Ref[ItemDataSystem] = Ref::new(
  ItemDataSystem::new(get_item_loader()),
)

///|
/// Replaces the global item-data system instance.
pub fn set_item_data_system(system : ItemDataSystem) -> Unit {
  item_data_system_ref.val = system
}

///|
/// Gets the global item-data system instance.
pub fn get_item_data_system() -> ItemDataSystem {
  item_data_system_ref.val
}

///|
fn collect_item_ids_from_bundle(json : Json, id_set : Map[Int, Bool]) -> Unit {
  guard json is Object(items) else {
    @log.fatal("invalid item bundle json, expected object")
  }
  for item_id_str, _ in items {
    let item_id = @strconv.parse_int(item_id_str) catch { _ => continue }
    id_set.set(item_id, true)
  }
}

///|
async fn ItemDataSystem::discover_consume_and_etc_item_ids(
  self : ItemDataSystem,
) -> Array[Int] {
  let id_set : Map[Int, Bool] = Map::new()
  for bundle in consume_bundle_files {
    let bundle_json = load_item_bundle_cached(
      "Consume",
      bundle,
      self.item_loader,
    )
    collect_item_ids_from_bundle(bundle_json, id_set)
  }
  for bundle in etc_bundle_files {
    let bundle_json = load_item_bundle_cached("Etc", bundle, self.item_loader)
    collect_item_ids_from_bundle(bundle_json, id_set)
  }
  let ids : Array[Int] = []
  for item_id, _ in id_set {
    ids.push(item_id)
  }
  ids
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
  let item_loader = self.item_loader
  self.pending_item_loads.val.set(
    id,
    @io_service.submit_background_task(async fn() {
      ItemData::load_item_data_with_loader(id, item_loader)
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
/// Starts discovery and preload requests for all items in `assets/Item/Consume`
/// and `assets/Item/Etc`.
///
/// This function is idempotent and safe to call every frame.
pub fn ItemDataSystem::request_consume_and_etc_preload(
  self : ItemDataSystem,
) -> Unit {
  if self.consume_etc_preload_requested.val {
    return
  }
  guard self.consume_etc_preload_discovery.val is Some(discovery) else {
    self.consume_etc_preload_discovery.val = Some(
      @io_service.submit_background_task(async fn() {
        self.discover_consume_and_etc_item_ids()
      }),
    )
    return
  }
  match discovery.poll() {
    Some(Ok(ids)) => {
      self.consume_etc_preload_ids.val = ids
      self.consume_etc_preload_requested.val = true
      self.consume_etc_preload_discovery.val = None
      self.request_many(ids)
    }
    Some(Err(err)) =>
      @log.fatal("failed to discover consume/etc preload items", data={
        "error": err.to_string(),
      })
    None => ()
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
/// Returns whether consume/etc preload is ready.
///
/// Panics immediately if any preloaded item failed.
pub fn ItemDataSystem::consume_and_etc_preload_ready_or_fail(
  self : ItemDataSystem,
) -> Bool {
  self.request_consume_and_etc_preload()
  if not(self.consume_etc_preload_requested.val) {
    return false
  }
  self.all_requested_ready_or_fail(self.consume_etc_preload_ids.val)
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
