///| Class that represents an item loaded from the game's files
/// Contains all shared data between concrete items
pub(all) struct ItemData {
  src : @resource.NxNode
  icons : (@graphics.Texture, @graphics.Texture)
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
fn get_character_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("character")
}

///|
pub(all) struct EquipId {
  category : String
  zid : String
}

///|
fn EquipId::parse(item_id : Int) -> EquipId!LoadDataError {
  guard parse_equip_category(item_id) is Some(category) else {
    raise LoadDataError::INVALID_ITEM_ID(item_id)
  }
  let zid = "0" + item_id.to_string()
  { category, zid }
}

///|
fn ItemData::load_async(
  item_id : Int,
  character_loader : @resource.AsyncLoader,
  item_loader : @resource.AsyncLoader,
  string_loader : @resource.SyncLoader
) -> @utils.Future[Result[ItemData, LoadDataError]] {
  let zid = "0" + item_id.to_string()
  let (category, src, strsrc) = try {
    match parse_category1(item_id).or_error(INVALID_ITEM_ID(item_id)) {
      EQUIP => {
        guard parse_equip_category(item_id) is Some(category) else {
          raise LoadDataError::INVALID_ITEM_ID(item_id)
        }
        let src = character_loader.load_res([category, zid + ".img"])
        let strsrc = string_loader.load_res([
          "Eqp.img",
          "Eqp",
          category,
          item_id.to_string(),
        ])
        (category, src, strsrc)
      }
      CONSUME => {
        let category = "Consume"
        let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
        let src = item_loader.load_res(["Consume", strprefix + ".img", zid])
        let strsrc = string_loader.load_res(["Consume.img", item_id.to_string()])
        (category, src, strsrc)
      }
      INSTALL => {
        let category = "Install"
        let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
        let src = item_loader.load_res(["Install", strprefix + ".img", zid])
        let strsrc = string_loader.load_res(["Ins.img", item_id.to_string()])
        (category, src, strsrc)
      }
      ETC => {
        let category = "Etc"
        let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
        let src = item_loader.load_res(["Etc", strprefix + ".img", zid])
        let strsrc = string_loader.load_res([
          "Etc.img",
          "Etc",
          item_id.to_string(),
        ])
        (category, src, strsrc)
      }
      CASH => {
        let category = "Cash"
        let strprefix = "0" + ItemData::get_item_prefix(item_id).to_string()
        let src = item_loader.load_res(["Cash", strprefix + ".img", zid])
        let strsrc = string_loader.load_res(["Cash.img", item_id.to_string()])
        (category, src, strsrc)
      }
    }
  } catch {
    e => return @utils.Future::from_value(Err(e))
  }
  let str_src = strsrc.value()
  let name = match str_src {
    { "name": String(name), .. } => name
    _ => ""
  }
  let desc = match str_src {
    { "desc": String(desc), .. } => desc
    _ => ""
  }
  src.map_exn(fn(src) -> ItemData!LoadDataError {
    let info = src["info"]
    if info.is_null() {
      raise LoadDataError::DATA_NOT_FOUND(item_id)
    }
    let icons = (
      info["icon"] |> @graphics.Texture::from_resource,
      info["iconRaw"] |> @graphics.Texture::from_resource,
    )
    try {
      let price = info["price"].get_int!()
      let untradable = info["tradeBlock"].get_bool!()
      let unique = info["only"].get_bool!()
      let unsellable = info["notSale"].get_bool!()
      let cash_item = info["cash"].get_bool!()
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
    } catch {
      e => raise LoadDataError::INVALID_DATA(Show::to_string(e))
    }
  })
}

///|
let cache : Map[Int, @utils.Future[Result[ItemData, LoadDataError]]] = Map::new()

///|
pub fn ItemData::get_async(
  id : Int,
  string_loader : @resource.SyncLoader
) -> @utils.Future[Result[ItemData, LoadDataError]] {
  cache.get_or_init(id, fn() {
    ItemData::load_async(
      id,
      get_character_loader(),
      get_item_loader(),
      string_loader,
    )
  })
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
let categorynames = [
  "Cap", "Accessory", "Accessory", "Accessory", "Coat", "Longcoat", "Pants", "Shoes",
  "Glove", "Shield", "Cape", "Ring", "Accessory", "Accessory", "Accessory",
]

///|
pub(all) type! LoadDataError {
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
  if index < categorynames.length() {
    return Some(categorynames[index])
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
pub fn get_category(self : ItemData) -> String {
  self.category
}

///|
pub fn ItemData::get_icon(self : ItemData, raw : Bool) -> @graphics.Texture {
  if raw {
    self.icons.1
  } else {
    self.icons.0
  }
}

///|
pub fn get_info(self : ItemData) -> Map[String, Json] {
  match self.src.value() {
    { "info": Object(info), .. } => info
    _ => Map::new()
  }
}

///|
pub fn get_src(self : ItemData) -> @resource.NxNode {
  self.src
}

///|
pub fn get_item_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("item")
}
