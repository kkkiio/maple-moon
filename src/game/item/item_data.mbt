///|

///|
/// Class that represents an item loaded from the game's files
/// Contains all shared data between concrete items
pub(all) struct ItemData {
  src : Json
  icons : (@res.NxTexture, @res.NxTexture)
  item_id : Int
  price : Int
  gender : Int
  name : String
  desc : String
  category : String
  valid : Bool
  untradable : Bool
  unique : Bool
  unsellable : Bool
  cash_item : Bool
}

///|
pub(all) struct EquipId {
  category : String
  zid : String
}

///|
fn EquipId::parse(item_id : Int) -> EquipId raise LoadDataError {
  guard parse_equip_category(item_id) is Some(category) else {
    raise LoadDataError::INVALID_ITEM_ID(item_id)
  }
  let zid = "0" + item_id.to_string()
  { category, zid }
}

///|
fn load_item_text_src(bundle : String, path : Array[String]) -> Json {
  let bundle_json = load_item_text_bundle_cached(bundle)
  get_json_by_path(bundle_json, path)
}

///|
let item_text_bundle_cache : Map[String, Json] = Map([])

///|
fn load_item_text_bundle_cached(bundle : String) -> Json {
  if item_text_bundle_cache.get(bundle) is Some(cached) {
    return cached
  }
  let bundle_json = @res.require_json("res://String/" + bundle + ".json")
  item_text_bundle_cache.set(bundle, bundle_json)
  bundle_json
}

///|
fn get_json_by_path(root : Json, path : Array[String]) -> Json {
  path.fold(init=root, fn(acc, key) {
    match acc {
      Object(obj) => obj.get(key).unwrap_or(Json::null())
      _ => Json::null()
    }
  })
}

///|
/// Preload item text bundles into in-memory cache.
pub fn preload_item_text_bundles() -> Unit {
  let bundles = ["Eqp.img", "Consume.img", "Ins.img", "Etc.img", "Cash.img"]
  for bundle in bundles {
    ignore(load_item_text_bundle_cached(bundle))
  }
}

///|
pub fn ItemData::load(item_id : Int) -> ItemData {
  let zid = "0\{item_id}"
  let category1 = parse_category1(item_id).unwrap_or_else(fn() {
    abort("invalid item id: \{item_id}")
  })
  let (category, src, strsrc) : (String, Json, Json) = match category1 {
    EQUIP => {
      let equip_id = EquipId::parse(item_id) catch {
        _ => abort("invalid equip item id: \{item_id}")
      }
      let category = equip_id.category
      let equip_zid = equip_id.zid
      let src = @res.require_json(
        "res://Character/" + category + "/" + equip_zid + ".img.json",
      )
      let strsrc = load_item_text_src("Eqp.img", [
        "Eqp",
        category,
        item_id.to_string(),
      ])
      (category, src, strsrc)
    }
    CONSUME => {
      let category = "Consume"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let bundle = strprefix + ".img"
      let bundle_json = load_item_bundle_cached(category, bundle)
      let src = get_item_data_from_bundle(bundle_json, item_id, zid) catch {
        _ => abort("item data not found: \{item_id}")
      }
      let strsrc = load_item_text_src("Consume.img", [item_id.to_string()])
      (category, src, strsrc)
    }
    INSTALL => {
      let category = "Install"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let bundle = strprefix + ".img"
      let bundle_json = load_item_bundle_cached(category, bundle)
      let src = get_item_data_from_bundle(bundle_json, item_id, zid) catch {
        _ => abort("item data not found: \{item_id}")
      }
      let strsrc = load_item_text_src("Ins.img", [item_id.to_string()])
      (category, src, strsrc)
    }
    ETC => {
      let category = "Etc"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let bundle = strprefix + ".img"
      let bundle_json = load_item_bundle_cached(category, bundle)
      let src = get_item_data_from_bundle(bundle_json, item_id, zid) catch {
        _ => abort("item data not found: \{item_id}")
      }
      let strsrc = load_item_text_src("Etc.img", ["Etc", item_id.to_string()])
      (category, src, strsrc)
    }
    CASH => {
      let category = "Cash"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let bundle = strprefix + ".img"
      let bundle_json = load_item_bundle_cached(category, bundle)
      let src = get_item_data_from_bundle(bundle_json, item_id, zid) catch {
        _ => abort("item data not found: \{item_id}")
      }
      let strsrc = load_item_text_src("Cash.img", [item_id.to_string()])
      (category, src, strsrc)
    }
  }
  let str_src = strsrc
  let name = match str_src {
    { "name": String(name), .. } => name
    _ => ""
  }
  let desc = match str_src {
    { "desc": String(desc), .. } => desc
    _ => ""
  }
  guard src is { "info": Object(info), .. } else {
    abort("item data missing info: \{item_id}")
  }
  let icons : (@res.NxTexture, @res.NxTexture) = (
    @json.from_json(info["icon"]) catch {
      _ => abort("item icon decode failed: \{item_id}")
    },
    @json.from_json(info["iconRaw"]) catch {
      _ => abort("item iconRaw decode failed: \{item_id}")
    },
  )
  let price = match info {
    { "price": Number(price, ..), .. } => price.to_int()
    _ => 0
  }
  let untradable = match info {
    { "tradeBlock": Number(1, ..), .. } => true
    _ => false
  }
  let unique = match info {
    { "only": Number(1, ..), .. } => true
    _ => false
  }
  let unsellable = match info {
    { "notSale": Number(1, ..), .. } => true
    _ => false
  }
  let cash_item = match info {
    { "cash": Number(1, ..), .. } => true
    _ => false
  }
  let gender = get_item_gender(item_id)
  {
    src,
    icons,
    item_id,
    price,
    gender,
    name,
    desc,
    category,
    valid: true,
    untradable,
    unique,
    unsellable,
    cash_item,
  }
}

///|
let cache : Map[Int, ItemData] = Map([])

///|
let bundle_cache : Map[String, Json] = Map([])

///|
fn load_item_bundle_cached(category : String, bundle : String) -> Json {
  let key = "\{category}/\{bundle}"
  if bundle_cache.get(key) is Some(cached) {
    return cached
  }
  let bundle_json = @res.require_json(
    "res://Item/" + category + "/" + bundle + ".json",
  )
  bundle_cache.set(key, bundle_json)
  bundle_json
}

///|
fn get_item_data_from_bundle(
  bundle_json : Json,
  item_id : Int,
  zid : String,
) -> Json raise LoadDataError {
  match bundle_json {
    Object(items) =>
      match items.get(zid) {
        Some(item_data) => item_data
        None => raise LoadDataError::DATA_NOT_FOUND(item_id)
      }
    _ => raise LoadDataError::DATA_NOT_FOUND(item_id)
  }
}

///|
fn ItemData::get_loaded(id : Int) -> ItemData? {
  cache.get(id)
}

///|
pub fn ItemData::load_item_data(id : Int) -> ItemData {
  if cache.get(id) is Some(data) {
    return data
  }
  let data = ItemData::load(id)
  cache.set(id, data)
  data
}

///|
fn ItemData::get_prefix(id : Int) -> Int {
  id / 1000000
}

///|
pub fn parse_category1(id : Int) -> Category1? {
  let res = match id / 1000000 {
    1 => Category1::EQUIP
    2 => Category1::CONSUME
    3 => Category1::INSTALL
    4 => Category1::ETC
    5 => Category1::CASH
    _ => return None
  }
  Some(res)
}

///|
pub enum Category1 {
  EQUIP
  CONSUME
  INSTALL
  ETC
  CASH
}

///|
fn ItemData::get_item_prefix(id : Int) -> Int {
  id / 10000
}

///|
let category_names : ReadOnlyArray[String] = [
  "Cap", "Accessory", "Accessory", "Accessory", "Coat", "Longcoat", "Pants", "Shoes",
  "Glove", "Shield", "Cape", "Ring", "Accessory", "Accessory", "Accessory",
]

///|
pub(all) suberror LoadDataError {
  INVALID_ITEM_ID(Int)
  DATA_NOT_FOUND(Int)
  INVALID_DATA(String)
} derive(Debug)

///|
pub fn parse_equip_category(id : Int) -> String? {
  let index = ItemData::get_item_prefix(id) - 100
  if index < 0 {
    return None
  }
  if index < category_names.length() {
    return Some(category_names[index])
  }
  if index >= 30 && index <= 70 {
    return Some("Weapon")
  }
  return None
}

///|
pub fn get_item_gender(id : Int) -> Int {
  let item_prefix = ItemData::get_item_prefix(id)
  if (ItemData::get_prefix(id) != 1 && item_prefix != 254) ||
    item_prefix == 119 ||
    item_prefix == 168 {
    return 2
  }
  let gender_digit = id / 1000 % 10
  if gender_digit > 1 {
    return 2
  }
  gender_digit
}

///|
pub fn ItemData::get_category(self : ItemData) -> String {
  self.category
}

///|
pub fn ItemData::get_icon(self : ItemData, raw : Bool) -> @res.NxTexture {
  if raw {
    self.icons.1
  } else {
    self.icons.0
  }
}

///|
pub fn ItemData::get_info(self : ItemData) -> Map[String, Json] {
  match self.src {
    { "info": Object(info), .. } => info
    _ => Map([])
  }
}
