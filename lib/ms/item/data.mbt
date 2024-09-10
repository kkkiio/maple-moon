/// Class that represents an item loaded from the game's files
/// Contains all shared data between concrete items
pub struct ItemData {
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

let cache : Map[Int, ItemData] = Map::new()

fn ItemData::load(item_id : Int) -> ItemData! {
  let strprefix = "0" + get_item_prefix(item_id).to_string()
  let zid = "0" + item_id.to_string()
  let prefix = get_prefix(item_id)
  let (category, src, strsrc) = match prefix {
    1 => {
      let category = get_eqcategory!(item_id)
      let src = @resource.character_loader().load_res(
        [category, zid + ".img", "info"],
      )
      let strsrc = @resource.string_loader().load_res(
        ["Eqp.img", "Eqp", category, item_id.to_string()],
      )
      (category, Some(src), Some(strsrc))
    }
    2 => {
      let category = "Consume"
      let src = get_item_loader().load_res(
        ["Consume", strprefix + ".img", zid, "info"],
      )
      let strsrc = @resource.string_loader().load_res(
        ["Consume.img", item_id.to_string()],
      )
      (category, Some(src), Some(strsrc))
    }
    3 => {
      let category = "Install"
      let src = get_item_loader().load_res(
        ["Install", strprefix + ".img", zid, "info"],
      )
      let strsrc = @resource.string_loader().load_res(
        ["Ins.img", item_id.to_string()],
      )
      (category, Some(src), Some(strsrc))
    }
    4 => {
      let category = "Etc"
      let src = get_item_loader().load_res(
        ["Etc", strprefix + ".img", zid, "info"],
      )
      let strsrc = @resource.string_loader().load_res(
        ["Etc.img", item_id.to_string()],
      )
      (category, Some(src), Some(strsrc))
    }
    5 => {
      let category = "Cash"
      let src = get_item_loader().load_res(
        ["Cash", strprefix + ".img", zid, "info"],
      )
      let strsrc = @resource.string_loader().load_res(
        ["Cash.img", item_id.to_string()],
      )
      (category, Some(src), Some(strsrc))
    }
    _ => ("", None, None)
  }
  match src {
    Some(src) => {
      let icons = @utils.BoolPair::new(
        src["icon"] |> @graphics.Texture::from_resource,
        src["iconRaw"] |> @graphics.Texture::from_resource,
      )
      let price = src["price"].get_int!()
      let untradable = src["tradeBlock"].get_bool!()
      let unique = src["only"].get_bool!()
      let unsellable = src["notSale"].get_bool!()
      let cash_item = src["cash"].get_bool!()
      let gender = get_item_gender(item_id)
      let name = strsrc.unwrap()["name"].get_string()
      let desc = strsrc.unwrap()["desc"].get_string()
      {
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
    None =>
      {
        icons: @utils.BoolPair::new(
          @graphics.Texture::default(),
          @graphics.Texture::default(),
        ),
        item_id,
        price: 0,
        untradable: false,
        valid: false,
        unique: false,
        unsellable: false,
        cash_item: false,
        gender: 0,
        name: "",
        desc: "",
        category: "",
      }
  }
}

pub fn ItemData::get(id : Int) -> ItemData! {
  match cache[id] {
    Some(item_data) => item_data
    None => {
      let item_data = ItemData::load!(id)
      cache.set(id, item_data)
      item_data
    }
  }
}

fn ItemData::get_prefix(id : Int) -> Int {
  id / 1000000
}

fn ItemData::get_item_prefix(id : Int) -> Int {
  id / 10000
}

let categorynames = [
  "Cap", "Accessory", "Accessory", "Accessory", "Coat", "Longcoat", "Pants", "Shoes",
  "Glove", "Shield", "Cape", "Ring", "Accessory", "Accessory", "Accessory",
]

type! ItemDataError String derive(Show)

fn ItemData::get_eqcategory(id : Int) -> String!ItemDataError {
  let index = get_item_prefix(id) - 100
  if index < 0 {
    raise ItemDataError("invalid item id \{id}")
  }
  if index < categorynames.length() {
    return categorynames[index]
  }
  if index >= 30 && index <= 70 {
    return "Weapon"
  }
  ""
}

fn ItemData::get_item_gender(id : Int) -> Int {
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

fn get_item_loader() -> @resource.Loader {
  @resource.Loader::new("item")
}

pub fn get_category(self : ItemData) -> String {
  self.category
}
