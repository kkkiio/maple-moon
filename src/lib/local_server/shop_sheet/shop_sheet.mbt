///|
/// A row in `shops.csv`.
pub struct NxShopRow {
  /// Shop id in `shops.csv`.
  shop_id : Int
  /// NPC id in `shops.csv`.
  npc_id : Int
}

///|
/// A row in `shopitems.csv`.
pub struct NxShopItemRow {
  /// Shop id this item belongs to.
  shop_id : Int
  /// Item id.
  item_id : Int
  /// Item price.
  price : Int
  /// Pitch field.
  pitch : Int
  /// Position field used for sort order.
  position : Int
  /// Time field.
  time : Int
  /// Charge price field.
  charge_price : Int
  /// Buyable count.
  buyable : Int
}

///|
/// Parse all rows from `shops.csv`.
pub fn parse_shop_rows(csv_text : String) -> Array[NxShopRow] raise {
  let rows : Array[NxShopRow] = []
  let lines = csv_text.split("\n").collect()
  if lines.length() == 0 {
    fail("shops.csv is empty")
  }
  let header = @csv.parse_csv_header(lines[0].to_string())
  for i = 1; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line.is_empty() {
      continue
    }
    let fields = @csv.parse_csv_line(line.to_string())
    rows.push({
      shop_id: @csv.parse_csv_int_field(
        fields,
        header,
        "shopid",
        i + 1,
        "shops.csv",
      ),
      npc_id: @csv.parse_csv_int_field(
        fields,
        header,
        "npcid",
        i + 1,
        "shops.csv",
      ),
    })
  }
  rows
}

///|
/// Parse all rows from `shopitems.csv`.
pub fn parse_shop_item_rows(
  csv_text : String,
) -> Map[Int, Array[NxShopItemRow]] raise {
  let rows : Map[Int, Array[NxShopItemRow]] = {}
  let lines = csv_text.split("\n").collect()
  if lines.length() == 0 {
    fail("shopitems.csv is empty")
  }
  let header = @csv.parse_csv_header(lines[0].to_string())
  for i = 1; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line.is_empty() {
      continue
    }
    let fields = @csv.parse_csv_line(line.to_string())
    let row : NxShopItemRow = {
      shop_id: @csv.parse_csv_int_field(
        fields,
        header,
        "shopid",
        i + 1,
        "shopitems.csv",
      ),
      item_id: @csv.parse_csv_int_field(
        fields,
        header,
        "itemid",
        i + 1,
        "shopitems.csv",
      ),
      price: @csv.parse_csv_int_field(
        fields,
        header,
        "price",
        i + 1,
        "shopitems.csv",
      ),
      pitch: @csv.parse_csv_int_field(
        fields,
        header,
        "pitch",
        i + 1,
        "shopitems.csv",
      ),
      position: @csv.parse_csv_int_field(
        fields,
        header,
        "position",
        i + 1,
        "shopitems.csv",
      ),
      time: @csv.parse_csv_int_field_or_default(fields, header, "time", 0),
      charge_price: @csv.parse_csv_int_field_or_default(
        fields, header, "charge_price", 0,
      ),
      buyable: @csv.parse_csv_int_field_or_default(
        fields, header, "buyable", 1000,
      ),
    }
    match rows.get(row.shop_id) {
      Some(items) => items.push(row)
      None => rows[row.shop_id] = [row]
    }
  }
  rows
}

///|
/// Build map from npc id to open-shop message using parsed CSV text.
pub fn build_npc_shop_map(
  shops_csv : String,
  shopitems_csv : String,
) -> Map[Int, @server_proto.OpenNpcShopMessage] raise {
  let shops = parse_shop_rows(shops_csv)
  let items_by_shop = parse_shop_item_rows(shopitems_csv)
  let by_npc_id : Map[Int, @server_proto.OpenNpcShopMessage] = {}
  for shop in shops {
    if shop.shop_id <= 0 {
      fail("invalid shop_id: \{shop.shop_id}")
    }
    let sorted_items = items_by_shop.get(shop.shop_id).unwrap_or([]).copy()
    sorted_items.sort_by(fn(a, b) { a.position.compare(b.position) })
    let items : Array[@server_proto.ShopItem] = []
    for item in sorted_items {
      items.push({
        id: item.item_id,
        price: item.price,
        pitch: item.pitch,
        time: item.time,
        charge_price: item.charge_price,
        buyable: item.buyable,
      })
    }
    by_npc_id.set(shop.npc_id, { npc_id: shop.npc_id, items })
  }
  by_npc_id
}

///|
/// Load and build NPC shop map through registered CSV loader.
pub async fn load_npc_shop_map(
  csv_loader : @resource.CsvLoader,
  shops_path? : String = "/assets/data/shops.csv",
  shopitems_path? : String = "/assets/data/shopitems.csv",
) -> Map[Int, @server_proto.OpenNpcShopMessage] {
  let shops_csv = csv_loader.load_text(shops_path)
  let shopitems_csv = csv_loader.load_text(shopitems_path)
  build_npc_shop_map(shops_csv, shopitems_csv)
}
