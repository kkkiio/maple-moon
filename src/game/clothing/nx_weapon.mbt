///|
/// Anchor metadata parsed from weapon frame `map`.
///
/// `parent_key` is expected to be one of `"handMove"`, `"hand"`, `"navel"`.
/// `parent_pos` is the local point defined by that anchor key in NX resource.
pub(all) struct NxMapAnchor {
  parent_key : String
  parent_pos : @struct.Point[Int]
} derive(Eq, Debug)

///|
/// Weapon-part rendering node in one frame.
///
/// - `texture`: frame texture payload (`__i/__w/__h/__off/origin`).
/// - `z`: raw layer tag string from resource, such as `"weaponOverArm"`.
/// - `anchor`: map anchor metadata used to align with body draw points.
pub(all) struct NxWeaponPart {
  texture : @resource.NxTexture
  z : String
  anchor : NxMapAnchor
} derive(Debug)

///|
/// All renderable parts in a single weapon action frame.
pub(all) struct NxWeaponFrame {
  parts : Map[String, NxWeaponPart]
} derive(Debug)

///|
/// Frame table of a single weapon action (e.g. `shoot2`).
pub(all) struct NxWeaponAction {
  frames : Map[Int, NxWeaponFrame]
} derive(Debug)

///|
/// Structured weapon resource parsed from item JSON source.
///
/// Keys are action names (`stand1`, `shoot2`, etc.).
pub(all) struct NxWeapon {
  actions : Map[String, NxWeaponAction]
} derive(Debug)

///|
pub impl @json.FromJson for NxMapAnchor with fn from_json(json, path) -> NxMapAnchor raise @json.JsonDecodeError {
  guard json is Object(map_obj) else {
    raise @json.JsonDecodeError((path, "NxMapAnchor: expected object"))
  }
  for key, value in map_obj {
    match value {
      Array([Number(x, ..), Number(y, ..)]) =>
        return { parent_key: key, parent_pos: Point(x.to_int(), y.to_int()) }
      _ => ()
    }
  }
  raise @json.JsonDecodeError(
    (path, "NxMapAnchor: expected at least one [x,y] anchor entry"),
  )
}

///|
pub impl @json.FromJson for NxWeaponPart with fn from_json(json, path) -> NxWeaponPart raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "NxWeaponPart: expected object"))
  }
  guard obj.contains("__i") else {
    raise @json.JsonDecodeError(
      (path, "NxWeaponPart: missing __i texture field"),
    )
  }
  guard obj.contains("origin") else {
    raise @json.JsonDecodeError((path, "NxWeaponPart: missing origin"))
  }
  let z = match obj.get("z") {
    Some(String(z)) => z
    _ => raise @json.JsonDecodeError((path, "NxWeaponPart: missing string z"))
  }
  let anchor = match obj.get("map") {
    Some(map_json) => @json.from_json(map_json, path=path.add_key("map"))
    None => raise @json.JsonDecodeError((path, "NxWeaponPart: missing map"))
  }
  let texture : @resource.NxTexture = @json.from_json(json, path~)
  { texture, z, anchor }
}

///|
pub impl @json.FromJson for NxWeaponFrame with fn from_json(json, path) -> NxWeaponFrame raise @json.JsonDecodeError {
  guard json is Object(frame_obj) else {
    raise @json.JsonDecodeError((path, "NxWeaponFrame: expected object"))
  }
  let parts = Map([])
  for part_name, part_json in frame_obj {
    guard part_json is Object(part_obj) && part_obj.contains("__i") else {
      continue
    }
    let part : NxWeaponPart = @json.from_json(
      part_json,
      path=path.add_key(part_name),
    )
    parts.set(part_name, part)
  }
  { parts, }
}

///|
pub impl @json.FromJson for NxWeaponAction with fn from_json(json, path) -> NxWeaponAction raise @json.JsonDecodeError {
  guard json is Object(action_obj) else {
    raise @json.JsonDecodeError((path, "NxWeaponAction: expected object"))
  }
  let frames = Map([])
  for frame_key, frame_json in action_obj {
    let frame_idx = @string.parse_int(frame_key) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key(frame_key), "NxWeaponAction: frame key must be int"),
        )
    }
    let frame : NxWeaponFrame = @json.from_json(
      frame_json,
      path=path.add_key(frame_key),
    )
    frames.set(frame_idx, frame)
  }
  guard !frames.is_empty() else {
    raise @json.JsonDecodeError((path, "NxWeaponAction: no frames"))
  }
  { frames, }
}

///|
pub impl @json.FromJson for NxWeapon with fn from_json(json, path) -> NxWeapon raise @json.JsonDecodeError {
  guard json is Object(src_obj) else {
    raise @json.JsonDecodeError((path, "NxWeapon: expected object"))
  }
  let actions = Map([])
  for action_name, action_json in src_obj {
    if action_name == "info" {
      continue
    }
    let action : NxWeaponAction = @json.from_json(
      action_json,
      path=path.add_key(action_name),
    )
    actions.set(action_name, action)
  }
  guard !actions.is_empty() else {
    raise @json.JsonDecodeError((path, "NxWeapon: no actions"))
  }
  { actions, }
}

///|
/// Returns a parsed part for (`action_name`, `frame`, `part_name`) if present.
pub fn NxWeapon::get_part(
  self : NxWeapon,
  action_name : String,
  frame : Int,
  part_name : String,
) -> NxWeaponPart? {
  self.actions
  .get(action_name)
  .bind(fn(action) { action.frames.get(frame) })
  .bind(fn(frame_data) { frame_data.parts.get(part_name) })
}
