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
  let src = @item.get_item_loader()
    .load_res_async(["Consume", prefix.to_string() + ".img", strid])
    .value()
  let id = strid.trim_start(chars="0").to_string() |> @strconv.parse_int
  let item_data = @item.ItemData::load(
    id,
    @resource.get_character_loader(),
    @item.get_item_loader(),
  )
  BulletData::new(src, item_data)
}

///|
fn BulletData::new(src : Json, item_data : @item.ItemData) -> BulletData raise {
  match src {
    { "bullet": bullet_src, "info": info, .. } => {
      let watk = match info {
        { "incPAD": Number(watk, ..), .. } => watk.to_int()
        _ => 0
      }
      let bullet : @resource.NxAnimation = @json.from_json(bullet_src)
      { item_data, bullet, watk }
    }
    _ => fail("Invalid bullet data")
  }
}
