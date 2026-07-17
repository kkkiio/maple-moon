///|
pub(all) struct BulletData {
  item_data : @item.ItemData
  bullet : @combat_proto.BulletAnimation
  watk : Int
}

///|
/// Load one bullet item and its native animation.
///
/// # Example
/// ```moonbit nocheck
/// let arrow = try! BulletData::load("02060000")
/// ignore(arrow)
/// ```
///
/// # Errors
/// Raises when `strid` is invalid or its referenced animation resource cannot
/// be loaded or decoded.
pub fn BulletData::load(strid : String) -> BulletData raise {
  guard strid.length() == 8 else { fail("invalid bullet id: \{strid}") }
  let prefix = strid[:4]
  let src = @res.require_json_node(
    "res://Item/Consume/" + prefix.to_owned() + ".img.json",
    [strid],
  )
  let id = (strid.trim_start(chars="0") |> @string.parse_int) catch {
    _ => fail("invalid bullet id: \{strid}")
  }
  let item_data = @item.ItemData::load(id)
  BulletData(src, item_data, strid)
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
) -> @combat_proto.BulletAnimation raise {
  let prefix = strid[:4]
  let base_path = "res://Item/Consume/\{prefix}.img.json"
  let ref_path = read_mx_animation_ref(bullet_src) catch {
    error =>
      fail("missing mx_animation in bullet node: \{strid}, error=\{error}")
  }
  let resolved = @res.resolve_ref(base_path, ref_path)
  let animation_loader = AnimationLoader()
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip("main") catch {
    error =>
      fail("missing main clip in bullet animation: \{strid}, error=\{error}")
  }
  @combat_proto.BulletAnimation(clip)
}

///|
fn BulletData::BulletData(
  src : Json,
  item_data : @item.ItemData,
  strid : String,
) -> BulletData raise {
  match src {
    { "bullet": bullet_src, "info": info, .. } => {
      let watk = match info {
        { "incPAD": Number(watk, ..), .. } => watk.to_int()
        _ => 0
      }
      let bullet = load_bullet_native_animation(strid, bullet_src)
      { item_data, bullet, watk }
    }
    _ => fail("invalid bullet data: \{strid}")
  }
}
