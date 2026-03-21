///|
/// Parsed TSV sheet with header index and row records.
pub struct Sheet {
  source_name : String
  header : Map[String, Int]
  rows : Array[Row]
}

///|
/// One TSV data row.
pub struct Row {
  source_name : String
  line_no : Int
  header : Map[String, Int]
  fields : Array[String]
}

///|
/// Parse DB-styled TSV text into a `Sheet`.
///
/// Rules:
/// - delimiter is tab (`\t`) only
/// - first line is header
/// - only the final trailing empty line is allowed
pub fn parse_tsv_sheet(text : String, source_name : String) -> Sheet raise {
  let header : Map[String, Int] = {}
  let rows : Array[Row] = []
  let lines = text.split("\n").collect()
  if lines.length() == 0 {
    fail("tsv '\{source_name}' is empty")
  }
  for i = 0; i < lines.length(); i = i + 1 {
    let line_no = i + 1
    let line = lines[i].to_string()
    if i > 0 && i == lines.length() - 1 && line.is_empty() {
      // Keep Unix-style trailing newline support.
      continue
    }
    if line.is_empty() {
      fail("empty tsv line at line \{line_no} in \{source_name}")
    }
    let fields = line.split("\t").to_array().map(s => s.to_string())
    if i == 0 {
      for idx = 0; idx < fields.length(); idx = idx + 1 {
        let col = fields[idx].trim().to_string()
        if col.is_empty() {
          fail("empty tsv header at line \{line_no} in \{source_name}")
        }
        if header.contains(col) {
          fail("duplicate tsv header '\{col}' in \{source_name}")
        }
        header[col] = idx
      }
      continue
    }
    rows.push({ source_name, line_no, header, fields })
  }
  { source_name, header, rows }
}

///|
/// Iterate all rows in this sheet.
pub fn Sheet::rows(self : Sheet) -> Iter[Row] {
  self.rows.iter()
}

///|
/// Get parsed row count.
pub fn Sheet::row_count(self : Sheet) -> Int {
  self.rows.length()
}

///|
/// Read a string field by column name.
///
/// Raises when the column does not exist or this row has no value for that column.
pub fn Row::get_string(self : Row, col : String) -> String raise {
  guard self.header.get(col) is Some(idx) else {
    fail("missing tsv column '\{col}' in \{self.source_name}")
  }
  if idx >= self.fields.length() {
    fail(
      "tsv line \{self.line_no} missing column '\{col}' in \{self.source_name}",
    )
  }
  self.fields[idx]
}

///|
/// Read an integer field by column name.
///
/// Raises when the field is missing or not a valid integer.
pub fn Row::get_int(self : Row, col : String) -> Int raise {
  let text = self.get_string(col)
  @strconv.parse_int(text) catch {
    _ =>
      fail(
        "invalid int '\{col}' at line \{self.line_no} in \{self.source_name}",
      )
  }
}

///|
/// Read an optional integer field by column name.
///
/// Returns `default` when column is absent, missing on this row, or invalid.
pub fn Row::get_int_or_default(self : Row, col : String, default : Int) -> Int {
  self.get_int(col) catch {
    _ => default
  }
}
