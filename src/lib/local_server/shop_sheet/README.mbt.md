# Shop Sheet

Parse `shops.csv` and `shopitems.csv`, then build NPC shop data used by local server and tests.

## 可执行示例

```mbt check
///|
test "parse shops and shopitems" {
  let shops_csv = "shopid,npcid\n1,9010000\n"
  let shopitems_csv = "shopid,itemid,price,pitch,position,time,charge_price,buyable\n1,2000000,50,0,0,0,0,100\n"

  let shops = @shop_sheet.parse_shop_rows(shops_csv)
  inspect(shops.length(), content="1")

  let items_map = @shop_sheet.parse_shop_item_rows(shopitems_csv)
  guard items_map.get(1) is Some(items) else { fail("missing shop") }
  inspect(items.length(), content="1")
}

///|
test "build npc shop map" {
  let shops_csv = "shopid,npcid\n1,9010000\n"
  let shopitems_csv = "shopid,itemid,price,pitch,position,time,charge_price,buyable\n1,2000000,50,0,0,0,0,100\n"
  let npc_map = @shop_sheet.build_npc_shop_map(shops_csv, shopitems_csv)
  guard npc_map.get(9010000) is Some(shop) else { fail("missing npc shop") }
  inspect(shop.npc_id, content="9010000")
  inspect(shop.items.length(), content="1")
}
```
