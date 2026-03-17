# Drop Sheet

Parse mob drop CSV resources (`mob_drops.csv`, `drop_data_global.csv`) into typed rows grouped by `dropperid`.

## 可执行示例

```mbt check
///|
test "parse drop rows" {
  let csv =
    "id,dropperid,itemid,minimum_quantity,maximum_quantity,questid,chance\n1,100100,2000005,1,2,0,100000\n"
  let rows = @drop_sheet.parse_drop_rows(csv)
  inspect(rows.length(), content="1")
  inspect(rows[0].dropperid, content="100100")
  inspect(rows[0].itemid, content="2000005")
}

///|
test "group rows by dropperid" {
  let csv =
    "id,dropperid,itemid,minimum_quantity,maximum_quantity,questid,chance\n1,100100,2000005,1,2,0,100000\n2,100100,4000000,1,1,0,250000\n"
  let grouped = @drop_sheet.build_drop_row_map(csv)
  guard grouped.get(100100) is Some(rows) else { fail("missing dropper") }
  inspect(rows.length(), content="2")
}
```
