///|
pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @ms_animation.Animation
  watk : Int
}

///|
pub fn BulletData::load(strid : String) -> BulletData {
  guard strid.length() == 8 else { abort("Invalid bullet id: \{strid}") }
  let prefix = strid[:4]
  let src = @resource.json_navigate(
    "assets/Item/Consume/" + prefix.to_owned() + ".img.json",
    [strid],
  )
  let id = (strid.trim_start(chars="0") |> @string.parse_int) catch {
    _ => abort("Invalid bullet id: \{strid}")
  }
  let item_data = @item.ItemData::load(id)
  BulletData::new(src, item_data, strid)
}

///|
fn read_mx_animation_ref(src : Json) -> String raise {
  match src {
    { "mx_animation": String(path), .. } => path
    _ => fail("missing mx_animation in bullet node")
  }
}

///|
fn load_bullet_native_animation(
  strid : String,
  bullet_src : Json,
) -> @ms_animation.Animation {
  let prefix = strid[:4]
  let base_path = "assets/Item/Consume/\{prefix}.img.json"
  let ref_path = read_mx_animation_ref(bullet_src) catch {
    _ => abort("missing mx_animation in bullet node: \{strid}")
  }
  let resolved = @resource.resolve_ref(base_path, ref_path)
  let animation_loader = @resource.AnimationLoader::new()
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip("main") catch {
    _ => abort("missing main clip in bullet animation: \{strid}")
  }
  @ms_animation.from_selene_clip(clip, loop_=true)
}

///|
fn BulletData::new(
  src : Json,
  item_data : @item.ItemData,
  strid : String,
) -> BulletData {
  match src {
    { "bullet": bullet_src, "info": info, .. } => {
      let watk = match info {
        { "incPAD": Number(watk, ..), .. } => watk.to_int()
        _ => 0
      }
      let bullet = load_bullet_native_animation(strid, bullet_src)
      { item_data, bullet, watk }
    }
    _ => abort("Invalid bullet data")
  }
}
