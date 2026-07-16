///|
/// Parsed NPC template resource from `Npc/<id>.img` in mx format.
pub struct MxNpc {
  /// Parsed info node.
  info : MxNpcInfo
  /// Path to aseprite animation json (relative to assets root by default).
  animations_path : String
} derive(@json.FromJson)

///|
/// Normalized metadata extracted from NPC `info`.
pub struct MxNpcInfo {
  /// Optional linked NPC template id without `.img` suffix.
  link : String?
  /// True when NPC is script/shop driven (`script != null || shop == true`).
  scripted : Bool
  /// Collected speak key lists from info node (`info.speak`).
  speak_keys : Array[String]
}

///|
pub impl @json.FromJson for MxNpcInfo with fn from_json(json, path) -> MxNpcInfo raise @json.JsonDecodeError {
  guard json is Object(info_obj) else {
    raise @json.JsonDecodeError((path, "MxNpcInfo must be an object"))
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
  let speak_keys = match info_obj.get("speak") {
    Some(speak_json) =>
      @res.parse_map_based_array(speak_json, path=path.add_key("speak"))
    None => []
  }
  { link, scripted: has_script || is_shop, speak_keys }
}
