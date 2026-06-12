///|
test "parse_tsv_sheet reads header and rows" {
  let text = "shopid\tnpcid\n1011000\t9010000\n"
  let sheet = @data_sheet.parse_tsv_sheet(text, "shops.tsv")
  inspect(sheet.row_count(), content="1")
  let rows = sheet.rows().collect()
  inspect(rows.length(), content="1")
  inspect(rows[0].get_int("shopid"), content="1011000")
  inspect(rows[0].get_int("npcid"), content="9010000")
}

///|
test "parse_tsv_sheet allows only trailing empty line" {
  let text = "shopid\tnpcid\n1\t2\n3\t4\n"
  let sheet = @data_sheet.parse_tsv_sheet(text, "shops.tsv")
  inspect(sheet.row_count(), content="2")
}

///|
test "parse_tsv_sheet fails on middle empty line" {
  let text = "shopid\tnpcid\n1\t2\n\n3\t4\n"
  try @data_sheet.parse_tsv_sheet(text, "shops.tsv") catch {
    Failure::Failure(msg) =>
      if !msg.contains("empty tsv line at line 3") {
        fail("expected empty line parse error")
      }
    _ => fail("expected empty line parse error")
  } noraise {
    _ => fail("expected empty line parse error")
  }
}

///|
test "row get_int raises on missing column" {
  let text = "shopid\tnpcid\n1\t2\n"
  let sheet = @data_sheet.parse_tsv_sheet(text, "shops.tsv")
  let row = sheet.rows().collect()[0]
  try row.get_int("price") catch {
    Failure::Failure(msg) =>
      if !msg.contains("missing tsv column 'price'") {
        fail("expected missing column error")
      }
    _ => fail("expected missing column error")
  } noraise {
    _ => fail("expected missing column error")
  }
}

///|
test "row get_int_or_default returns default on invalid value" {
  let text = "shopid\tnpcid\nabc\t2\n"
  let sheet = @data_sheet.parse_tsv_sheet(text, "shops.tsv")
  let row = sheet.rows().collect()[0]
  inspect(row.get_int_or_default("shopid", 7), content="7")
}
