///|
pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @graphics.Animation
  watk : Int
}

///|
pub async fn BulletData::load(
  strid : String,
  string_loader : @resource.SyncLoader
) -> BulletData raise {
  guard strid.length() == 8 else { fail("Invalid bullet id: \{strid}") }
  let prefix = strid.substring(end=4)
  let src = @item.get_item_loader().load_res_async([
    "Consume",
    prefix + ".img",
    strid,
  ])
  let id = strid.trim_start("0").to_string() |> @strconv.parse_int
  let item_data = @item.ItemData::load(
    id,
    @item.get_character_loader(),
    @item.get_item_loader(),
    string_loader,
  )
  BulletData::new(src, item_data)
}

///|
fn BulletData::new(
  src : @resource.NxNode,
  item_data : @item.ItemData
) -> BulletData raise {
  let bullet = src["bullet"] |> @graphics.Animation::from_resource_ex()
  let watk = src["info"]["incPAD"].get_int()
  { item_data, bullet, watk }
}
