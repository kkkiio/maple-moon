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

///|
struct NameLoader {
  string_loader : @resource.SyncLoader
}

///|
pub fn NameLoader::load() -> NameLoader {
  NameLoader::new(@resource.string_loader())
}

///|
pub fn NameLoader::new(string_loader : @resource.SyncLoader) -> NameLoader {
  { string_loader, }
}

///|
pub fn NameLoader::get_npc_name(
  self : NameLoader,
  nid : @string.View
) -> @string.View {
  self.string_loader.load_res(["Npc.img", nid.to_string(), "name"]).get_string()
}

///|
pub fn NameLoader::get_mob_name(
  self : NameLoader,
  mid : @string.View
) -> @string.View {
  self.string_loader
  .load_res(["Mob.img", mid.trim_start("0").to_string(), "name"])
  .get_string()
}

///|
pub fn NameLoader::get_map_name(
  self : NameLoader,
  v : @string.View
) -> @string.View! {
  let mapid = @strconv.parse_int!(v.to_string())
  let map_category = @map.get_map_category(mapid)
  let map_info = self.string_loader.load_res([
    "Map.img",
    map_category,
    mapid.to_string(),
  ])
  map_info["mapName"].get_string()
}
