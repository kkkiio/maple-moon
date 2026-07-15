///|
/// A row in `shops.tsv`.
pub struct NxShopRow {
  /// Shop id in `shops.tsv`.
  shop_id : Int
  /// NPC id in `shops.tsv`.
  npc_id : Int
}

///|
/// A row in `shopitems.tsv`.
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
/// Parse all rows from `shops.tsv`.
pub fn parse_shop_rows(tsv_text : String) -> Array[NxShopRow] raise {
  let rows : Array[NxShopRow] = []
  let sheet = @data_sheet.parse_tsv_sheet(tsv_text, "shops.tsv")
  for row in sheet.rows() {
    rows.push({ shop_id: row.get_int("shopid"), npc_id: row.get_int("npcid") })
  }
  rows
}

///|
/// Parse all rows from `shopitems.tsv`.
pub fn parse_shop_item_rows(
  tsv_text : String,
) -> Map[Int, Array[NxShopItemRow]] raise {
  let rows : Map[Int, Array[NxShopItemRow]] = Map([])
  let sheet = @data_sheet.parse_tsv_sheet(tsv_text, "shopitems.tsv")
  for row in sheet.rows() {
    let row : NxShopItemRow = {
      shop_id: row.get_int("shopid"),
      item_id: row.get_int("itemid"),
      price: row.get_int("price"),
      pitch: row.get_int("pitch"),
      position: row.get_int("position"),
      time: row.get_int_or_default("time", 0),
      charge_price: row.get_int_or_default("charge_price", 0),
      buyable: row.get_int_or_default("buyable", 1000),
    }
    match rows.get(row.shop_id) {
      Some(items) => items.push(row)
      None => rows[row.shop_id] = [row]
    }
  }
  rows
}

///|
/// Build map from npc id to open-shop message using parsed TSV text.
pub fn build_npc_shop_map(
  shops_tsv : String,
  shopitems_tsv : String,
) -> Map[Int, @server_proto.OpenNpcShopMessage] raise {
  let shops = parse_shop_rows(shops_tsv)
  let items_by_shop = parse_shop_item_rows(shopitems_tsv)
  let by_npc_id : Map[Int, @server_proto.OpenNpcShopMessage] = Map([])
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
/// Load and build NPC shop map through registered TSV loader.
pub fn load_npc_shop_map(
  shops_path? : String = "assets/data/shops.tsv",
  shopitems_path? : String = "assets/data/shopitems.tsv",
) -> Map[Int, @server_proto.OpenNpcShopMessage] {
  let shops_tsv = @resource.load_text(shops_path)
  let shopitems_tsv = @resource.load_text(shopitems_path)
  build_npc_shop_map(shops_tsv, shopitems_tsv) catch {
    err => abort("failed to load NPC shop map: \{err}")
  }
}
