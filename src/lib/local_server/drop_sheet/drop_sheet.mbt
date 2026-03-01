///|
/// A row in drop CSV files.
pub struct NxMobDropRow {
  /// Dropper id. `-1` is used by global drop sheet.
  dropperid : Int
  /// Item id. `0` means meso.
  itemid : Int
  /// Minimum quantity.
  minimum_quantity : Int
  /// Maximum quantity.
  maximum_quantity : Int
  /// Quest id restriction. `0` means no restriction.
  questid : Int
  /// Drop chance with base `1_000_000`.
  chance : Int
}

///|
/// Parse rows from a drop CSV text.
pub fn parse_drop_rows(csv_content : String) -> Array[NxMobDropRow] {
  let rows : Array[NxMobDropRow] = []
  let lines = csv_content.split("\n").collect()

  for i = 1; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line.is_empty() {
      continue
    }

    let fields = @csv.parse_csv_line(line.to_string())
    if fields.length() < 7 {
      continue
    }

    let dropperid = @strconv.parse_int(@csv.strip_quotes(fields[1])) catch {
      _ => continue
    }
    let itemid = @strconv.parse_int(@csv.strip_quotes(fields[2])) catch {
      _ => continue
    }
    let min_qty = @strconv.parse_int(@csv.strip_quotes(fields[3])) catch {
      _ => continue
    }
    let max_qty = @strconv.parse_int(@csv.strip_quotes(fields[4])) catch {
      _ => continue
    }
    let questid = @strconv.parse_int(@csv.strip_quotes(fields[5])) catch {
      _ => continue
    }
    let chance = @strconv.parse_int(@csv.strip_quotes(fields[6])) catch {
      _ => continue
    }

    rows.push({
      dropperid,
      itemid,
      minimum_quantity: min_qty,
      maximum_quantity: max_qty,
      questid,
      chance,
    })
  }

  rows
}

///|
/// Build map grouped by `dropperid`.
pub fn build_drop_row_map(
  csv_content : String,
) -> Map[Int, Array[NxMobDropRow]] {
  let grouped : Map[Int, Array[NxMobDropRow]] = {}
  for row in parse_drop_rows(csv_content) {
    match grouped.get(row.dropperid) {
      Some(list) => list.push(row)
      None => grouped.set(row.dropperid, [row])
    }
  }
  grouped
}

///|
/// Load and parse drop rows through registered CSV loader.
pub async fn load_drop_row_map(
  csv_loader : @resource.CsvLoader,
  path : String,
) -> Map[Int, Array[NxMobDropRow]] {
  let content = csv_loader.load_text(path)
  build_drop_row_map(content)
}
