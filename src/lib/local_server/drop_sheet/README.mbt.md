# Drop Sheet

Parse mob drop TSV resources (`mob_drops.tsv`, `drop_data_global.tsv`) into typed rows grouped by `dropperid`.

## 可执行示例

```mbt check
///|
test "parse drop rows" {
  let tsv = "id\tdropperid\titemid\tminimum_quantity\tmaximum_quantity\tquestid\tchance\n1\t100100\t2000005\t1\t2\t0\t100000\n"
  let rows = @drop_sheet.parse_drop_rows(tsv)
  inspect(rows.length(), content="1")
  inspect(rows[0].dropperid, content="100100")
  inspect(rows[0].itemid, content="2000005")
}

///|
test "group rows by dropperid" {
  let tsv = "id\tdropperid\titemid\tminimum_quantity\tmaximum_quantity\tquestid\tchance\n1\t100100\t2000005\t1\t2\t0\t100000\n2\t100100\t4000000\t1\t1\t0\t250000\n"
  let grouped = @drop_sheet.build_drop_row_map(tsv)
  guard grouped.get(100100) is Some(rows) else { fail("missing dropper") }
  inspect(rows.length(), content="2")
}
```
