///|
fn register_mini_map_ui_checker() -> Checker {
  { name: "mini_map_ui", run: fn(ctx) { check_mini_map_ui_resources(ctx) } }
}

///|
fn check_mini_map_ui_resources(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []
  let mini_map_rel = "ui/UIWindow2.img/MiniMap.json"
  let mini_map_abs = path_join(ctx.assets_root, mini_map_rel)
  if !file_exists(mini_map_abs) {
    issues.push(
      make_issue(
        "mini_map_ui",
        Error,
        mini_map_rel,
        "missing UI mini map resource json",
      ),
    )
    return issues
  }
  let mini_map_json = @json.parse(read_text_file(mini_map_abs)) catch {
    e => {
      issues.push(
        make_issue("mini_map_ui", Error, mini_map_rel, "invalid json: \{e}"),
      )
      return issues
    }
  }
  let minmap_obj = match mini_map_json {
    { "MinMap": Object(minmap), .. } => minmap
    _ => {
      issues.push(
        make_issue(
          "mini_map_ui",
          Error,
          mini_map_rel,
          "missing object field MinMap",
        ),
      )
      return issues
    }
  }
  for key in ["w", "e", "n", "nw", "ne", "s", "sw", "se"] {
    check_texture_value(minmap_obj, key, mini_map_rel, "MinMap", ctx, issues)
  }
  check_map_helper_minimap(ctx, issues)

  issues
}

///|
fn check_map_helper_minimap(
  ctx : RescheckContext,
  issues : Array[CheckIssue],
) -> Unit {
  let rel_path = "spritesheets/Map/MapHelper.img/minimap.json"
  let abs_path = path_join(ctx.assets_root, rel_path)
  if !file_exists(abs_path) {
    issues.push(
      make_issue(
        "mini_map_ui",
        Error,
        rel_path,
        "missing MapHelper minimap resource json",
      ),
    )
    return
  }
  let minimap_json = @json.parse(read_text_file(abs_path)) catch {
    e => {
      issues.push(
        make_issue("mini_map_ui", Error, rel_path, "invalid json: \{e}"),
      )
      return
    }
  }
  guard minimap_json is Object(minimap_obj) else {
    issues.push(
      make_issue(
        "mini_map_ui",
        Error,
        rel_path,
        "MapHelper minimap root must be object",
      ),
    )
    return
  }
  for key in ["portal", "user", "npc", "another"] {
    check_texture_value(minimap_obj, key, rel_path, "minimap", ctx, issues)
  }
}
