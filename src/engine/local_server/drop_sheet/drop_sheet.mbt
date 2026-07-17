///|
/// A row in drop TSV files.
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
/// Parse rows from a drop TSV text.
pub fn parse_drop_rows(tsv_content : String) -> Array[NxMobDropRow] {
  let rows : Array[NxMobDropRow] = []
  let sheet = @data_sheet.parse_tsv_sheet(tsv_content, "drop_sheet.tsv") catch {
    _ => return rows
  }
  for row in sheet.rows() {
    let dropperid = row.get_int("dropperid") catch { _ => continue }
    let itemid = row.get_int("itemid") catch { _ => continue }
    let min_qty = row.get_int("minimum_quantity") catch { _ => continue }
    let max_qty = row.get_int("maximum_quantity") catch { _ => continue }
    let questid = row.get_int("questid") catch { _ => continue }
    let chance = row.get_int("chance") catch { _ => continue }

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
  tsv_content : String,
) -> Map[Int, Array[NxMobDropRow]] {
  let grouped : Map[Int, Array[NxMobDropRow]] = Map([])
  for row in parse_drop_rows(tsv_content) {
    match grouped.get(row.dropperid) {
      Some(list) => list.push(row)
      None => grouped.set(row.dropperid, [row])
    }
  }
  grouped
}

///|
/// Load and parse drop rows through registered TSV loader.
pub fn load_drop_row_map(path : String) -> Map[Int, Array[NxMobDropRow]] raise {
  let content = @res.load_text(path)
  build_drop_row_map(content)
}
