///|
pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @resource.NxAnimation
  watk : Int
}

///|
pub async fn BulletData::load(strid : String) -> BulletData {
  guard strid.length() == 8 else { fail("Invalid bullet id: \{strid}") }
  let prefix = strid[:4]
  let src = @item.get_item_loader().load_res_async([
    "Consume",
    prefix.to_string() + ".img",
    strid,
  ])
  let id = strid.trim_start(chars="0").to_string() |> @strconv.parse_int
  let item_data = @item.ItemData::load(
    id,
    @resource.get_character_loader(),
    @item.get_item_loader(),
  )
  BulletData::new(src, item_data)
}

///|
fn BulletData::new(
  src : @resource.NxNode,
  item_data : @item.ItemData,
) -> BulletData raise {
  let bullet : @resource.NxAnimation = @json.from_json(src["bullet"].value())
  let watk = src["info"]["incPAD"].get_int()
  { item_data, bullet, watk }
}
