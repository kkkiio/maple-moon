///|
fn register_json_format_checker() -> Checker {
  { name: "json", run: fn(ctx) { check_json_format(ctx) } }
}

///|
fn check_json_format(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []
  for abs_path in ctx.all_files {
    if not(is_json_file(abs_path)) {
      continue
    }
    let rel_path = path_relative(abs_path, ctx.assets_root)
    let content = read_text_file(abs_path)
    ignore(@json.parse(content)) catch {
      e =>
        issues.push(make_issue("json", Error, rel_path, "invalid json: \{e}"))
    }
  }
  issues
}
