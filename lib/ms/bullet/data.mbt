pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @graphics.Animation
  watk : Int
}

fn BulletData::load(id : Int) -> @utils.Future[Result[BulletData, Error]] {
  @item.ItemData::get_async(id).map_exn(
    fn(item_data) { BulletData::new!(id, item_data.unwrap_or_error!()) },
  )
}

fn BulletData::new(id : Int, item_data : @item.ItemData) -> BulletData! {
  let prefix = "0" + (id / 10000).to_string()
  let strid = "0" + id.to_string()
  let src = @item.get_item_loader().load_res(
    ["Consume", prefix + ".img", strid],
  )
  let bullet = src["bullet"] |> @graphics.Animation::from_resource_ex!()
  let watk = src["info"]["incPAD"].get_int!()
  { item_data, bullet, watk }
}

let cache : Map[Int, @utils.Future[Result[BulletData, Error]]] = Map::new()

pub fn BulletData::get_async(
  id : Int
) -> @utils.Future[Result[BulletData, Error]] {
  cache.get_or_init(id, fn() { BulletData::load(id) })
}
