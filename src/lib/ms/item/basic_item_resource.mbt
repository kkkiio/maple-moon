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
async fn discover_consume_and_etc_item_ids(
  item_loader : @resource.AsyncLoader,
) -> Array[Int] {
  let id_set : Map[Int, Bool] = Map([])
  for bundle in consume_bundle_files {
    let bundle_json = load_item_bundle_cached("Consume", bundle, item_loader)
    collect_item_ids_from_bundle(bundle_json, id_set)
  }
  for bundle in etc_bundle_files {
    let bundle_json = load_item_bundle_cached("Etc", bundle, item_loader)
    collect_item_ids_from_bundle(bundle_json, id_set)
  }
  let ids : Array[Int] = []
  for item_id, _ in id_set {
    ids.push(item_id)
  }
  ids
}

///|
/// Loads consume/etc basic item resources and keeps a full in-memory item-data map.
pub async fn BasicItemResource::load(
  item_loader : @resource.AsyncLoader,
  string_loader : @resource.AsyncLoader,
) -> BasicItemResource {
  preload_item_text_bundles(string_loader)
  let ids = discover_consume_and_etc_item_ids(item_loader)
  let items_by_id : Map[Int, ItemData] = Map([])
  for item_id in ids {
    let item_data = ItemData::load_item_data_with_loader(item_id, item_loader)
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
