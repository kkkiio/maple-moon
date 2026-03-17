# csv

通用 CSV 解析辅助包。

提供：

- 单行 CSV 解析（支持引号与转义双引号）
- 去引号工具
- 表头索引映射
- 按列名读取整数（必填/可选默认值）

## 可执行示例

```mbt check
///|
test "parse csv line and fields" {
  let line = "\"item,id\",1001,\"42\""
  let fields = @csv.parse_csv_line(line)
  inspect(fields.length(), content="3")
  inspect(@csv.strip_quotes(fields[0]), content="item,id")
  inspect(@csv.strip_quotes(fields[2]), content="42")
}

///|
test "parse csv header and int" {
  let header = @csv.parse_csv_header("shopid,npcid,price")
  let row = @csv.parse_csv_line("10,9000010,1200")
  let v = @csv.parse_csv_int_field(row, header, "price", 2, "shops.csv")
  inspect(v, content="1200")
  inspect(
    @csv.parse_csv_int_field_or_default(row, header, "missing", 7),
    content="7",
  )
}
```
