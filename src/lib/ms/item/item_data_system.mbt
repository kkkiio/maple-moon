///|
let pending_item_loads : Ref[Map[Int, @utils.Future[Result[ItemData, Error]]]] = Ref::new(
  Map::new(),
)

///|
let item_load_errors : Ref[Map[Int, String]] = Ref::new(Map::new())

///|
/// Request background loading for one item id.
///
/// This function is idempotent:
/// - already loaded: no-op
/// - already loading: no-op
/// - previously failed: no-op (strict mode keeps the first error)
pub fn ItemData::request(id : Int) -> Unit {
  if cache.contains(id) ||
    pending_item_loads.val.contains(id) ||
    item_load_errors.val.contains(id) {
    return
  }
  pending_item_loads.val.set(
    id,
    @io_service.submit_background_task(async fn() {
      ItemData::load_item_data(id)
    }),
  )
}

///|
/// Request background loading for all item ids.
pub fn ItemData::request_many(ids : Array[Int]) -> Unit {
  for id in ids {
    ItemData::request(id)
  }
}

///|
/// Get loading error of an item if background loading failed.
fn ItemData::get_load_error(id : Int) -> String? {
  item_load_errors.val.get(id)
}

///|
/// Get preloaded item data. Panics when data is not ready or failed to load.
pub fn request_item_data(id : Int) -> ItemData {
  match ItemData::get_loaded(id) {
    Some(data) => data
    None =>
      match ItemData::get_load_error(id) {
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
  pending_item_loads.val.remove(id) |> ignore
  item_load_errors.val.remove(id) |> ignore
}

///|
/// Return `true` only when all requested items are loaded.
/// Panic immediately if any requested item has a recorded load error.
pub fn ItemData::all_requested_ready_or_fail(ids : Array[Int]) -> Bool {
  for id in ids {
    match ItemData::get_load_error(id) {
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
pub fn item_data_system(_delta : Double) -> Unit {
  let completed_ids : Array[Int] = []
  for id, fut in pending_item_loads.val {
    match fut.poll() {
      Some(Ok(_)) => completed_ids.push(id)
      Some(Err(err)) => {
        let err_text = err.to_string()
        item_load_errors.val.set(id, err_text)
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
    pending_item_loads.val.remove(id) |> ignore
  }
}
