pub struct BulletData {
  item_data : @item.ItemData
  bullet : @graphics.Animation
  watk : Int
}

pub fn BulletData::load(id : Int) -> BulletData! {
  let item_data = @item.ItemData::get!(id)
  let prefix = "0" + (id / 10000).to_string()
  let strid = "0" + id.to_string()
  let src = @item.get_item_loader().load_res(
    ["Consume", prefix + ".img", strid],
  )
  let bullet = src["bullet"] |> @graphics.Animation::from_resource_ex!()
  let watk = src["info"]["incPAD"].get_int!()
  { item_data, bullet, watk }
}

let cache : Map[Int, BulletData] = Map::new()

pub fn BulletData::get(id : Int) -> BulletData! {
  match cache.get(id) {
    Some(data) => data
    None => {
      let data = BulletData::load!(id)
      cache.set(id, data)
      data
    }
  }
}
