# data_sheet

TSV 表格读取包（仅支持 db-styled TSV）。

提供：

- 解析 TSV 文本为 `Sheet`
- 基于列名读取 `Row` 字段
- 严格整数读取（`get_int`）与显式默认值读取（`get_int_or_default`）

## 可执行示例

```mbt check
///|
test "parse tsv sheet and read typed columns" {
  let text = "shopid\tnpcid\tprice\n1\t9010000\t1200\n"
  let sheet = @data_sheet.parse_tsv_sheet(text, "shops.tsv")
  inspect(sheet.row_count(), content="1")
  let row = sheet.rows().collect()[0]
  inspect(row.get_int("shopid"), content="1")
  inspect(row.get_int("price"), content="1200")
  inspect(row.get_int_or_default("missing", 7), content="7")
}
```
