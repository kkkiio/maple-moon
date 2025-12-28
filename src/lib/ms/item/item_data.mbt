///|
using @resource {type AsyncLoader}

///|
/// Class that represents an item loaded from the game's files
/// Contains all shared data between concrete items
pub(all) struct ItemData {
  src : Json
  icons : (@resource.NxTexture, @resource.NxTexture)
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
pub async fn ItemData::load(
  item_id : Int,
  character_loader : AsyncLoader,
  item_loader : AsyncLoader,
) -> ItemData {
  let zid = "0\{item_id}"
  let (category, src, strsrc) : (String, Json, Json) = match
    parse_category1(item_id).unwrap_or_error(INVALID_ITEM_ID(item_id)) {
    EQUIP => {
      guard parse_equip_category(item_id) is Some(category) else {
        raise LoadDataError::INVALID_ITEM_ID(item_id)
      }
      let src = character_loader
        .load_res_async([category, "\{zid}.img"])
        .value()
      let strsrc = equip_texts
        .as_object()
        .bind(_.get(category))
        .bind(_.as_object())
        .bind(_.get(item_id.to_string()))
        .unwrap_or(Json::null())
      (category, src, strsrc)
    }
    CONSUME => {
      let category = "Consume"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let src = item_loader.load_res_async(["Consume", strprefix + ".img", zid])
      let strsrc = consume_texts
        .as_object()
        .bind(_.get(category))
        .bind(_.as_object())
        .bind(_.get(item_id.to_string()))
        .unwrap_or(Json::null())
      (category, src.value(), strsrc)
    }
    INSTALL => {
      let category = "Install"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let src = item_loader.load_res_async(["Install", strprefix + ".img", zid])
      let strsrc = install_texts
        .as_object()
        .bind(_.get(category))
        .bind(_.as_object())
        .bind(_.get(item_id.to_string()))
        .unwrap_or(Json::null())
      (category, src.value(), strsrc)
    }
    ETC => {
      let category = "Etc"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let src = item_loader.load_res_async(["Etc", strprefix + ".img", zid])
      let strsrc = etc_texts
        .as_object()
        .bind(_.get(category))
        .bind(_.as_object())
        .bind(_.get(item_id.to_string()))
        .unwrap_or(Json::null())
      (category, src.value(), strsrc)
    }
    CASH => {
      let category = "Cash"
      let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
      let src = item_loader.load_res_async(["Cash", strprefix + ".img", zid])
      let strsrc = cash_texts
        .as_object()
        .bind(_.get(category))
        .bind(_.as_object())
        .bind(_.get(item_id.to_string()))
        .unwrap_or(Json::null())
      (category, src.value(), strsrc)
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
    raise LoadDataError::DATA_NOT_FOUND(item_id)
  }
  let icons : (@resource.NxTexture, @resource.NxTexture) = (
    info["icon"] |> @json.from_json,
    info["iconRaw"] |> @json.from_json,
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
let cache : Map[Int, ItemData] = Map::new()

///|
pub fn ItemData::get_loaded(id : Int) -> ItemData? {
  cache.get(id)
}

///|
pub async fn ItemData::get_async(id : Int) -> ItemData {
  if cache.get(id) is Some(data) {
    return data
  }
  let data = ItemData::load(
    id,
    @resource.get_character_loader(),
    get_item_loader(),
  )
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
let category_names : Array[String] = [
  "Cap", "Accessory", "Accessory", "Accessory", "Coat", "Longcoat", "Pants", "Shoes",
  "Glove", "Shield", "Cape", "Ring", "Accessory", "Accessory", "Accessory",
]

///|
pub(all) suberror LoadDataError {
  INVALID_ITEM_ID(Int)
  DATA_NOT_FOUND(Int)
  INVALID_DATA(String)
} derive(Show)

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
pub fn ItemData::get_icon(self : ItemData, raw : Bool) -> @resource.NxTexture {
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
    _ => Map::new()
  }
}

///|
pub fn get_item_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "item",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Consume/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/Item/Consume",
      ),
      "Cash/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/Item/Cash",
      ),
      "Etc/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/Item/Etc",
      ),
      "Install/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/Item/Install",
      ),
      "Pet/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/Item/Pet",
      ),
    }),
  )
}
