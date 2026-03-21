# Shop Sheet

Parse `shops.tsv` and `shopitems.tsv`, then build NPC shop data used by local server and tests.

## 可执行示例

```mbt check
///|
test "parse shops and shopitems" {
  let shops_tsv = "shopid\tnpcid\n1\t9010000\n"
  let shopitems_tsv = "shopid\titemid\tprice\tpitch\tposition\ttime\tcharge_price\tbuyable\n1\t2000000\t50\t0\t0\t0\t0\t100\n"

  let shops = @shop_sheet.parse_shop_rows(shops_tsv)
  inspect(shops.length(), content="1")

  let items_map = @shop_sheet.parse_shop_item_rows(shopitems_tsv)
  guard items_map.get(1) is Some(items) else { fail("missing shop") }
  inspect(items.length(), content="1")
}

///|
test "build npc shop map" {
  let shops_tsv = "shopid\tnpcid\n1\t9010000\n"
  let shopitems_tsv = "shopid\titemid\tprice\tpitch\tposition\ttime\tcharge_price\tbuyable\n1\t2000000\t50\t0\t0\t0\t0\t100\n"
  let npc_map = @shop_sheet.build_npc_shop_map(shops_tsv, shopitems_tsv)
  guard npc_map.get(9010000) is Some(shop) else { fail("missing npc shop") }
  inspect(shop.npc_id, content="9010000")
  inspect(shop.items.length(), content="1")
}
```
