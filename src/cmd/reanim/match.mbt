/// Match module: Filter JSON entries by path pattern
/// Pattern format: "key1/key2/key3" (e.g., "BasicEff.img/Teleport")
/// Future: support '*' wildcard

///|
/// Match entries in nested JSON by path pattern.
/// Returns array of (matched_path, value) tuples.
pub fn match_entries(json : Json, pattern : String) -> Array[(String, Json)] {
  let pattern_views = pattern.split("/").to_array()
  let patterns : Array[String] = []
  for p in pattern_views {
    patterns.push(p.to_string())
  }
  if patterns.is_empty() {
    return []
  }
  match_entries_recursive(json, patterns, 0, "")
}

///|
fn match_entries_recursive(
  json : Json,
  patterns : Array[String],
  pattern_index : Int,
  current_path : String,
) -> Array[(String, Json)] {
  guard json is Object(obj) else { return [] }
  guard pattern_index < patterns.length() else { return [] }
  let current_pattern = patterns[pattern_index].to_string()
  let is_last = pattern_index == patterns.length() - 1
  let results : Array[(String, Json)] = []
  for key, value in obj {
    // Check if key matches pattern (exact match for now, future: wildcard)
    if key == current_pattern || current_pattern == "*" {
      let new_path = if current_path.is_empty() {
        key.to_string()
      } else {
        "\{current_path}/\{key}"
      }
      if is_last {
        // Reached end of pattern, yield this entry
        results.push((new_path, value))
      } else {
        // Continue matching deeper
        let sub_results = match_entries_recursive(
          value,
          patterns,
          pattern_index + 1,
          new_path,
        )
        for r in sub_results {
          results.push(r)
        }
      }
    }
  }
  results
}
