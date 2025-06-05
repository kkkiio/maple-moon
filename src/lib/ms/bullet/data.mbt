///|
pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @graphics.Animation
  watk : Int
}

///|
fn BulletData::load(
  id : Int,
  string_loader : @resource.SyncLoader
) -> @utils.Future[Result[BulletData, Error]] {
  let prefix = "0" + (id / 10000).to_string()
  let strid = "0" + id.to_string()
  @item.get_item_loader()
  .load_res(["Consume", prefix + ".img", strid])
  .combine(@item.ItemData::get_async(id, string_loader))
  .map_exn(fn(it) {
    let (src, item_data) = it
    BulletData::new!(src, item_data.unwrap_or_error!())
  })
}

///|
fn BulletData::new(
  src : @resource.NxNode,
  item_data : @item.ItemData
) -> BulletData! {
  let bullet = src["bullet"] |> @graphics.Animation::from_resource_ex!()
  let watk = src["info"]["incPAD"].get_int!()
  { item_data, bullet, watk }
}

///|
let cache : Map[Int, @utils.Future[Result[BulletData, Error]]] = Map::new()

///|
pub fn BulletData::get_async(
  id : Int,
  string_loader : @resource.SyncLoader
) -> @utils.Future[Result[BulletData, Error]] {
  cache.get_or_init(id, fn() { BulletData::load(id, string_loader) })
}
