///| Class that represents an item loaded from the game's files
/// Contains all shared data between concrete items
pub(all) struct ItemData {
  src : @resource.NxNode
  icons : @utils.BoolPair[@graphics.Texture]
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

let character_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "character",
)

pub(all) struct EquipId {
  category : String
  zid : String
}

fn EquipId::parse(item_id : Int) -> EquipId!LoadDataError {
  let category = get_eqcategory!(item_id)
  let zid = "0" + item_id.to_string()
  { category, zid }
}

fn ItemData::load_async(
  item_id : Int
) -> @utils.Future[Result[ItemData, LoadDataError]] {
  let zid = "0" + item_id.to_string()
  let (category, src, strsrc) = try {
    match parse_category1!(item_id) {
      EQUIP => {
        let category = get_eqcategory!(item_id)
        let src = character_loader.load_res([category, zid + ".img"])
        let strsrc = @resource.string_loader().load_res(
          ["Eqp.img", "Eqp", category, item_id.to_string()],
        )
        (category, src, strsrc)
      }
      CONSUME => {
        let category = "Consume"
        let strprefix = "0" + get_item_prefix(item_id).to_string()
        let src = get_item_loader().load_res(
          ["Consume", strprefix + ".img", zid],
        )
        let strsrc = @resource.string_loader().load_res(
          ["Consume.img", item_id.to_string()],
        )
        (category, src |> @utils.Future::from_value, strsrc)
      }
      INSTALL => {
        let category = "Install"
        let strprefix = "0" + get_item_prefix(item_id).to_string()
        let src = get_item_loader().load_res(
          ["Install", strprefix + ".img", zid],
        )
        let strsrc = @resource.string_loader().load_res(
          ["Ins.img", item_id.to_string()],
        )
        (category, src |> @utils.Future::from_value, strsrc)
      }
      ETC => {
        let category = "Etc"
        let strprefix = "0" + get_item_prefix(item_id).to_string()
        let src = get_item_loader().load_res(["Etc", strprefix + ".img", zid])
        let strsrc = @resource.string_loader().load_res(
          ["Etc.img", item_id.to_string()],
        )
        (category, src |> @utils.Future::from_value, strsrc)
      }
      CASH => {
        let category = "Cash"
        let strprefix = "0" + get_item_prefix(item_id).to_string()
        let src = get_item_loader().load_res(["Cash", strprefix + ".img", zid])
        let strsrc = @resource.string_loader().load_res(
          ["Cash.img", item_id.to_string()],
        )
        (category, src |> @utils.Future::from_value, strsrc)
      }
    }
  } catch {
    e => return @utils.Future::from_value(Err(e))
  }
  src.map_exn(
    fn(src) -> ItemData!LoadDataError {
      let info = src["info"]
      if info.is_null() {
        raise LoadDataError::DATA_NOT_FOUND(item_id)
      }
      let icons = @utils.BoolPair::new(
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
        let name = strsrc["name"].get_string()
        let desc = strsrc["desc"].get_string()
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
    },
  )
}

let cache : Map[Int, @utils.Future[Result[ItemData, LoadDataError]]] = Map::new()

pub fn ItemData::get_async(
  id : Int
) -> @utils.Future[Result[ItemData, LoadDataError]] {
  cache.get_or_init(id, fn() { ItemData::load_async(id) })
}

fn ItemData::get_prefix(id : Int) -> Int {
  id / 1000000
}

fn parse_category1(id : Int) -> Category1!LoadDataError {
  match id / 1000000 {
    1 => Category1::EQUIP
    2 => Category1::CONSUME
    3 => Category1::INSTALL
    4 => Category1::ETC
    5 => Category1::CASH
    _ => raise LoadDataError::INVALID_ITEM_ID(id)
  }
}

enum Category1 {
  EQUIP
  CONSUME
  INSTALL
  ETC
  CASH
}

fn ItemData::get_item_prefix(id : Int) -> Int {
  id / 10000
}

let categorynames = [
  "Cap", "Accessory", "Accessory", "Accessory", "Coat", "Longcoat", "Pants", "Shoes",
  "Glove", "Shield", "Cape", "Ring", "Accessory", "Accessory", "Accessory",
]

pub(all) type! LoadDataError {
  INVALID_ITEM_ID(Int)
  DATA_NOT_FOUND(Int)
  INVALID_DATA(String)
} derive(Show)

// TODO: make private
pub fn get_eqcategory(id : Int) -> String!LoadDataError {
  let index = get_item_prefix(id) - 100
  if index < 0 {
    raise LoadDataError::INVALID_ITEM_ID(id)
  }
  if index < categorynames.length() {
    return categorynames[index]
  }
  if index >= 30 && index <= 70 {
    return "Weapon"
  }
  raise LoadDataError::INVALID_ITEM_ID(id) // TODO: what category it is
}

pub fn get_item_gender(id : Int) -> Int {
  let item_prefix = get_item_prefix(id)
  if (get_prefix(id) != 1 && item_prefix != 254) ||
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

pub fn get_item_loader() -> @resource.SyncLoader {
  @resource.SyncLoader::new("item")
}

pub fn get_category(self : ItemData) -> String {
  self.category
}

pub fn ItemData::get_icon(self : ItemData, raw : Bool) -> @graphics.Texture {
  self.icons[raw]
}

pub fn get_info(self : ItemData) -> Map[String, Json] {
  self.src
  .value()
  .as_object()
  .bind(fn(it) { it["info"].bind(fn(it) { it.as_object() }) })
  .or(Map::new())
}

pub fn get_src(self : ItemData) -> @resource.NxNode {
  self.src
}
