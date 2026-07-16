///|
let consume_bundle_files : ReadOnlyArray[String] = ["0200.img"]

///|
/// Basic item resources preloaded during app setup.
pub struct BasicItemResource {
  ids : Array[Int]
  items_by_id : Map[Int, ItemData]
}

///|
fn collect_item_ids_from_bundle(json : Json, id_set : Map[Int, Bool]) -> Unit {
  guard json is Object(items) else {
    @log.fatal("invalid item bundle json, expected object")
  }
  for item_id_str, _ in items {
    let item_id = @string.parse_int(item_id_str) catch { _ => continue }
    id_set.set(item_id, true)
  }
}

///|
fn discover_preloaded_item_ids() -> Array[Int] {
  let id_set : Map[Int, Bool] = Map([])
  for bundle in consume_bundle_files {
    let bundle_json = load_item_bundle_cached("Consume", bundle)
    collect_item_ids_from_bundle(bundle_json, id_set)
  }
  [
    for item_id, _ in id_set => item_id
  ]
}

///|
/// Loads basic item resources and keeps a full in-memory item-data map.
pub fn BasicItemResource::load() -> BasicItemResource {
  preload_item_text_bundles()
  let ids = discover_preloaded_item_ids()
  let items_by_id : Map[Int, ItemData] = Map([])
  for item_id in ids {
    let item_data = ItemData::load_item_data(item_id)
    items_by_id.set(item_id, item_data)
  }
  { ids, items_by_id }
}

///|
/// Installs preloaded item data into shared item-data cache.
pub fn BasicItemResource::install(self : BasicItemResource) -> Unit {
  for item_id, item_data in self.items_by_id {
    ItemData::add_item_data(item_id, item_data)
  }
}

///|
/// Returns all preload item ids carried by this resource.
pub fn BasicItemResource::ids(self : BasicItemResource) -> Array[Int] {
  self.ids
}

///|
let resources_by_world : Ref[Map[UInt, BasicItemResource]] = Ref(Map([]))

///|
/// Gets basic item resource for the current world.
pub fn get_resource() -> BasicItemResource? {
  let world_id = @ecs.require_current_world().id()
  resources_by_world.val.get(world_id)
}

///|
/// Inserts basic item resource for the current world.
pub fn insert_resource(resource : BasicItemResource) -> Unit {
  let world_id = @ecs.require_current_world().id()
  resources_by_world.val[world_id] = resource
}

///|
/// Clears basic item resource for the current world.
pub fn clear_resource() -> Unit {
  let world_id = @ecs.require_current_world().id()
  resources_by_world.val.remove(world_id)
}
