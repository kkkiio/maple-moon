///|
/// Parsed NPC template resource from `Npc/<id>.img`.
pub struct NxNpc {
  /// Parsed info node.
  info : NxNpcInfo
  /// Stance/action animation table keyed by original node name (`stand`, `arm`, ...).
  animations : Map[String, @resource.NxAnimation]
}

///|
/// Normalized metadata extracted from NPC `info`.
pub struct NxNpcInfo {
  /// Optional linked NPC template id without `.img` suffix.
  link : String?
  /// True when NPC is script/shop driven (`script != null || shop == true`).
  scripted : Bool
  /// Collected speak key lists from every node that has `speak`.
  /// Key is state/node name (for example: `info`, `stand`, `arm`).
  speak_keys_by_state : Map[String, Array[String]]
}

///|
pub impl @json.FromJson for NxNpcInfo with from_json(json, path) -> NxNpcInfo raise @json.JsonDecodeError {
  guard json is Object(info_obj) else {
    raise @json.JsonDecodeError((path, "NxNpcInfo must be an object"))
  }
  let link = match info_obj.get("link") {
    Some(String(link)) => Some(link)
    Some(Null) | None => None
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("link"), "link must be string or null"),
      )
  }
  let has_script = match info_obj.get("script") {
    Some(Null) | None => false
    Some(_) => true
  }
  let is_shop = match info_obj.get("shop") {
    Some(True) => true
    Some(False) | None => false
    _ =>
      raise @json.JsonDecodeError((path.add_key("shop"), "shop must be bool"))
  }
  { link, scripted: has_script || is_shop, speak_keys_by_state: {} }
}

///|
pub impl @json.FromJson for NxNpc with from_json(json, path) -> NxNpc raise @json.JsonDecodeError {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "NxNpc must be an object"))
  }
  let info_json = match root.get("info") {
    Some(info_json) => info_json
    None => raise @json.JsonDecodeError((path.add_key("info"), "missing info"))
  }
  let info : NxNpcInfo = @json.from_json(info_json, path=path.add_key("info"))
  let animations : Map[String, @resource.NxAnimation] = {}
  let speak_keys_by_state : Map[String, Array[String]] = {}
  for state, node in root {
    if state != "info" {
      let animation : @resource.NxAnimation = @json.from_json(
        node,
        path=path.add_key(state),
      )
      animations.set(state, animation)
    }
    match node {
      { "speak": speak_json, .. } => {
        let speak_keys : Array[String] = @resource.parse_map_based_array(
          speak_json,
          path=path.add_key(state).add_key("speak"),
        )
        speak_keys_by_state.set(state, speak_keys)
      }
      _ => ()
    }
  }
  if animations.length() == 0 {
    raise @json.JsonDecodeError(
      (path, "NxNpc must have at least one animation"),
    )
  }
  { info: { ..info, speak_keys_by_state, }, animations }
}
