///|
pub let color_map : Map[Char, ColorName] = {
  'b': ColorName::BLUE,
  'd': ColorName::VIOLET,
  'g': ColorName::GREEN,
  'k': ColorName::BLACK,
  'r': ColorName::RED,
}

///|
pub let font_weight_tag_map : Map[Char, Bool] = { 'n': false, 'e': true }

///|
pub let underline_tag_map : Map[Char, Bool] = { 'u': true, 'n': false }

///|
using @struct {type ColorName}

///|
/// #p[npcid]# - Shows the name of the NPC.
pub let npc_tag : (Char, MarkupType) = ('p', MarkupType::Pair)

///|
/// #o[mobid]# - Shows the name of the mob.
pub let mob_tag : (Char, MarkupType) = ('o', MarkupType::Pair)

///|
/// #m[mapid]# - Shows the name of the map.
pub let map_tag : (Char, MarkupType) = ('m', MarkupType::Pair)

///|
/// #t[itemid]# - Shows the name of the item.
pub let item_tag : (Char, MarkupType) = ('t', MarkupType::Pair)

///|
/// #h # - Shows the name of the player.
pub let player_tag : (Char, MarkupType) = ('h', MarkupType::Pair)

///|
pub let common_tags : Map[Char, MarkupType] = color_map
  .keys()
  .map(fn(c : Char) { (c, MarkupType::SelfClosing) })
  .concat(
    font_weight_tag_map
    .keys()
    .map(fn(c : Char) { (c, MarkupType::SelfClosing) }),
  )
  .concat(
    underline_tag_map.keys().map(fn(c : Char) { (c, MarkupType::SelfClosing) }),
  )
  .concat([|
    (mob_tag.0, mob_tag.1),
    (npc_tag.0, npc_tag.1),
    (map_tag.0, map_tag.1),
    (item_tag.0, item_tag.1),
    (player_tag.0, player_tag.1),
  |])
  |> Map::from_iter

///|
priv struct ReferenceData {
  npc_img : Json
  mob_img : Json
  map_img : Json
  eqp_img : Json
  consume_img : Json
  ins_img : Json
  etc_img : Json
  cash_img : Json
}

///|
let reference_data_ref : Ref[ReferenceData?] = Ref(None)

///|
pub(all) suberror ResolveReferenceError {
  DataNotReady
  InvalidId(String)
  PathNotFound(String)
  NameNotFound(String)
} derive(Debug)

///|
pub fn preload_reference_data() -> Unit {
  if reference_data_ref.val is Some(_) {
    return
  }
  reference_data_ref.val = Some({
    npc_img: @res.require_json("res://String/Npc.img.json"),
    mob_img: @res.require_json("res://String/Mob.img.json"),
    map_img: @res.require_json("res://String/Map.img.json"),
    eqp_img: @res.require_json("res://String/Eqp.img.json"),
    consume_img: @res.require_json("res://String/Consume.img.json"),
    ins_img: @res.require_json("res://String/Ins.img.json"),
    etc_img: @res.require_json("res://String/Etc.img.json"),
    cash_img: @res.require_json("res://String/Cash.img.json"),
  })
}

///|
pub fn clear_reference_data() -> Unit {
  reference_data_ref.val = None
}

///|
pub fn is_reference_data_ready() -> Bool {
  reference_data_ref.val is Some(_)
}

///|
pub fn resolve_npc_name(nid : StringView) -> String raise {
  let data = require_reference_data()
  get_name_by_path(data.npc_img, ["\{nid.to_owned()}", "name"], "npc:\{nid}")
}

///|
pub fn resolve_mob_name(mid : StringView) -> String raise {
  let normalized = mid.trim_start(chars="0").to_owned()
  guard !normalized.is_empty() else {
    raise InvalidId("invalid mob id: \{mid.to_owned()}")
  }
  let data = require_reference_data()
  get_name_by_path(data.mob_img, [normalized, "name"], "mob:\{mid}")
}

///|
pub fn resolve_map_name(v : StringView) -> String raise {
  let map_id_str = v.to_owned()
  let map_id = @string.parse_int(map_id_str) catch {
    _ => raise InvalidId("invalid map id: \{map_id_str}")
  }
  let category = @map.get_map_category(map_id)
  let data = require_reference_data()
  get_name_by_path(
    data.map_img,
    [category, map_id_str, "mapName"],
    "map:\{map_id_str}",
  )
}

///|
pub fn resolve_item_name(v : StringView) -> String raise {
  let item_id_str = v.to_owned()
  let item_id = @string.parse_int(item_id_str) catch {
    _ => raise InvalidId("invalid item id: \{item_id_str}")
  }
  let data = require_reference_data()
  let path = match @item.parse_category1(item_id) {
    Some(@item.Category1::EQUIP) =>
      match @item.parse_equip_category(item_id) {
        Some(category) => [category, item_id_str, "name"]
        None => raise InvalidId("invalid equip category: \{item_id}")
      }
    Some(@item.Category1::CONSUME) => [item_id_str, "name"]
    Some(@item.Category1::INSTALL) => [item_id_str, "name"]
    Some(@item.Category1::ETC) => ["Etc", item_id_str, "name"]
    Some(@item.Category1::CASH) => [item_id_str, "name"]
    None => raise InvalidId("unknown item category: \{item_id}")
  }
  let root = match @item.parse_category1(item_id) {
    Some(@item.Category1::EQUIP) => data.eqp_img
    Some(@item.Category1::CONSUME) => data.consume_img
    Some(@item.Category1::INSTALL) => data.ins_img
    Some(@item.Category1::ETC) => data.etc_img
    Some(@item.Category1::CASH) => data.cash_img
    None => raise InvalidId("unknown item category: \{item_id}")
  }
  get_name_by_path(root, path, "item:\{item_id_str}")
}

///|
fn require_reference_data() -> ReferenceData raise {
  match reference_data_ref.val {
    Some(data) => data
    None => raise DataNotReady
  }
}

///|
fn get_name_by_path(
  root : Json,
  path : Array[String],
  label : String,
) -> String raise {
  let value = get_json_by_path(root, path, label)
  match value {
    String(name) => name
    _ => raise NameNotFound("name not found: \{label}, path=\{to_repr(path)}")
  }
}

///|
fn get_json_by_path(
  root : Json,
  path : Array[String],
  label : String,
) -> Json raise {
  let mut current = root
  for key in path {
    current = match current {
      Object(obj) =>
        match obj.get(key) {
          Some(next) => next
          None => raise PathNotFound("path not found: \{label}, key=\{key}")
        }
      _ => raise PathNotFound("path not object: \{label}, key=\{key}")
    }
  }
  current
}
