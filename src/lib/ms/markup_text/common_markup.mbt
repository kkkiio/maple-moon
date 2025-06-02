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
typealias ColorName = @struct.ColorName

///| #p[npcid]# - Shows the name of the NPC.
pub let npc_tag : (Char, MarkupType) = ('p', MarkupType::Pair)

///| #m[mapid]# - Shows the name of the map.
pub let map_tag : (Char, MarkupType) = ('m', MarkupType::Pair)

///| #t[itemid]# - Shows the name of the item.
pub let item_tag : (Char, MarkupType) = ('t', MarkupType::Pair)

///| #h # - Shows the name of the player.
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
    [
      (npc_tag.0, npc_tag.1),
      (map_tag.0, map_tag.1),
      (item_tag.0, item_tag.1),
      (player_tag.0, player_tag.1),
    ].iter(),
  )
  |> Map::from_iter

///|
struct RefRender {
  string_loader : @resource.SyncLoader
  get_player_name : () -> String
}

///|
pub fn RefRender::new(
  string_loader : @resource.SyncLoader,
  get_player_name : () -> String
) -> RefRender {
  { string_loader, get_player_name }
}

///|
pub fn RefRender::get_npc_name(self : RefRender, nid : @string.View) -> String {
  self.string_loader.load_res(["Npc.img", nid.to_string(), "name"]).get_string()
}

///|
pub fn RefRender::get_mob_name(self : RefRender, mid : @string.View) -> String {
  self.string_loader
  .load_res(["Mob.img", mid.trim_start("0").to_string(), "name"])
  .get_string()
}

///|
pub fn RefRender::get_map_name(self : RefRender, v : @string.View) -> String! {
  let mapid = @strconv.parse_int!(v.to_string())
  let map_category = @map.get_map_category(mapid)
  let map_info = self.string_loader.load_res([
    "Map.img",
    map_category,
    mapid.to_string(),
  ])
  map_info["mapName"].get_string()
}

///|
pub fn RefRender::get_item_name(self : RefRender, v : @string.View) -> String! {
  let item_id_str = v.to_string()
  let item_id = @strconv.parse_int!(item_id_str)
  let path_parts = match @item.parse_category1(item_id) {
    Some(@item.Category1::EQUIP) =>
      match @item.parse_equip_category(item_id) {
        Some(sub_category) =>
          ["Eqp.img", "Eqp", sub_category, item_id_str, "name"]
        None => fail!("equip sub-category not found, item_id: \{item_id}")
      }
    Some(@item.Category1::CONSUME) => ["Consume.img", item_id_str, "name"]
    Some(@item.Category1::INSTALL) => ["Ins.img", item_id_str, "name"]
    Some(@item.Category1::ETC) => ["Etc.img", "Etc", item_id_str, "name"]
    Some(@item.Category1::CASH) => ["Cash.img", item_id_str, "name"]
    None => fail!("unknown category, item_id: \{item_id}")
  }
  self.string_loader.load_res(path_parts).get_string()
}

///|
pub fn RefRender::get_player_name(self : RefRender) -> String {
  (self.get_player_name)()
}
