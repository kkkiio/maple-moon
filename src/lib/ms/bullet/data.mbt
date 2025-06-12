///|
pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @graphics.Animation
  watk : Int
}

///|
async fn BulletData::load(
  id : Int,
  string_loader : @resource.SyncLoader
) -> BulletData! {
  let prefix = "0" + (id / 10000).to_string()
  let strid = "0" + id.to_string()
  let src = @item.get_item_loader().load_res_async([
    "Consume",
    prefix + ".img",
    strid,
  ])
  let item_data = @item.ItemData::get_async(id, string_loader)
  BulletData::new!(src, item_data)
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
let cache : Map[Int, BulletData] = Map::new()

///|
pub async fn BulletData::get_async(
  id : Int,
  string_loader : @resource.SyncLoader
) -> BulletData! {
  if cache.get(id) is Some(data) {
    return data
  }
  let data = BulletData::load(id, string_loader)
  cache.set(id, data)
  data
}
