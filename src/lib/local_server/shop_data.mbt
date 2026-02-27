///|
priv struct NxShopRow {
  shop_id : Int
  npc_id : Int
}

///|
priv struct NxShopItemRow {
  item_id : Int
  price : Int
  pitch : Int
  position : Int
  time : Int
  charge_price : Int
  buyable : Int
}

///|
priv struct NpcShopDatabase {
  by_npc_id : Map[Int, @server_proto.OpenNpcShopMessage]
}

///|
fn NpcShopDatabase::from_csv(
  shops_csv : String,
  shopitems_csv : String,
) -> NpcShopDatabase raise {
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
  { by_npc_id, }
}

///|
fn NpcShopDatabase::get_shop_by_npc_id(
  self : NpcShopDatabase,
  npc_id : Int,
) -> @server_proto.OpenNpcShopMessage? {
  self.by_npc_id.get(npc_id)
}

///|
fn LocalServer::get_shop_by_npc_id(
  self : LocalServer,
  npc_id : Int,
) -> @server_proto.OpenNpcShopMessage? {
  match self.npc_shop_db {
    Some(db) => db.get_shop_by_npc_id(npc_id)
    None => None
  }
}

///|
fn LocalServer::load_npc_shop_database(self : LocalServer) -> Unit {
  @io_service.execute_background(async fn() {
    let shops_csv : String = fetch_text("/assets/data/shops.csv").wait()
      |> @js.Value::cast
    let shopitems_csv : String = fetch_text("/assets/data/shopitems.csv").wait()
      |> @js.Value::cast
    let db = NpcShopDatabase::from_csv(shops_csv, shopitems_csv)
    self.npc_shop_db = Some(db)
    @log.info("Loaded shops.csv and shopitems.csv", data={})
  })
}

///|
fn parse_shop_rows(csv_text : String) -> Array[NxShopRow] raise {
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
    let shop_id = @csv.parse_csv_int_field(
      fields,
      header,
      "shopid",
      i + 1,
      "shops.csv",
    )
    let npc_id = @csv.parse_csv_int_field(
      fields,
      header,
      "npcid",
      i + 1,
      "shops.csv",
    )
    rows.push({ shop_id, npc_id })
  }
  rows
}

///|
fn parse_shop_item_rows(
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
    let shop_id = @csv.parse_csv_int_field(
      fields,
      header,
      "shopid",
      i + 1,
      "shopitems.csv",
    )
    let row : NxShopItemRow = {
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
    match rows.get(shop_id) {
      Some(items) => items.push(row)
      None => rows[shop_id] = [row]
    }
  }
  rows
}
