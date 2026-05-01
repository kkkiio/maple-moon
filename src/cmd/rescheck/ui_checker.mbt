///|
fn register_ui_checker() -> Checker {
  { name: "ui", run: fn(ctx) { check_ui_resources(ctx) } }
}

///|
fn check_ui_resources(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []

  let ui_window2_dir = "ui/UIWindow2.img"
  let ui_window4_dir = "ui/UIWindow4.img"
  let ui_window2_abs = path_join(ctx.assets_root, ui_window2_dir)
  let ui_window4_abs = path_join(ctx.assets_root, ui_window4_dir)
  if !file_exists(ui_window2_abs) {
    issues.push(
      make_issue("ui", Error, ui_window2_dir, "missing UIWindow2 directory"),
    )
  }
  if !file_exists(ui_window4_abs) {
    issues.push(
      make_issue("ui", Error, ui_window4_dir, "missing UIWindow4 directory"),
    )
  }

  let item_rel = "ui/UIWindow2.img/Item.json"
  let item_abs = path_join(ctx.assets_root, item_rel)
  if !file_exists(item_abs) {
    issues.push(
      make_issue("ui", Error, item_rel, "missing UI item window resource json"),
    )
    return issues
  }

  let item_json = @json.parse(read_text_file(item_abs)) catch {
    e => {
      issues.push(make_issue("ui", Error, item_rel, "invalid json: \{e}"))
      return issues
    }
  }

  let item_obj = match item_json {
    Object(obj) => obj
    _ => {
      issues.push(
        make_issue("ui", Error, item_rel, "Item.json root must be object"),
      )
      return issues
    }
  }

  check_texture_field(item_obj, "FullBackgrnd", item_rel, ctx, issues)
  check_texture_field(item_obj, "FullBackgrnd2", item_rel, ctx, issues)
  check_texture_field(item_obj, "FullBackgrnd3", item_rel, ctx, issues)
  check_texture_field(item_obj, "disabled", item_rel, ctx, issues)
  check_tab_resources(item_obj, item_rel, ctx, issues)
  issues
}

///|
fn check_tab_resources(
  item_obj : Map[String, Json],
  rel_path : String,
  ctx : RescheckContext,
  issues : Array[CheckIssue],
) -> Unit {
  guard item_obj.get("Tab") is Some(Object(tab_obj)) else {
    issues.push(make_issue("ui", Error, rel_path, "missing object field Tab"))
    return
  }
  guard tab_obj.get("enabled") is Some(Object(enabled)) else {
    issues.push(
      make_issue("ui", Error, rel_path, "missing object field Tab.enabled"),
    )
    return
  }
  guard tab_obj.get("disabled") is Some(Object(disabled)) else {
    issues.push(
      make_issue("ui", Error, rel_path, "missing object field Tab.disabled"),
    )
    return
  }
  for i in 0..<4 {
    let key = i.to_string()
    check_texture_value(enabled, key, rel_path, "Tab.enabled", ctx, issues)
    check_texture_value(disabled, key, rel_path, "Tab.disabled", ctx, issues)
  }
}

///|
fn check_texture_field(
  obj : Map[String, Json],
  field : String,
  rel_path : String,
  ctx : RescheckContext,
  issues : Array[CheckIssue],
) -> Unit {
  check_texture_value(obj, field, rel_path, "", ctx, issues)
}

///|
fn check_texture_value(
  obj : Map[String, Json],
  key : String,
  rel_path : String,
  parent : String,
  ctx : RescheckContext,
  issues : Array[CheckIssue],
) -> Unit {
  let label = if parent == "" { key } else { "\{parent}.\{key}" }
  guard obj.get(key) is Some(value) else {
    issues.push(make_issue("ui", Error, rel_path, "missing field \{label}"))
    return
  }
  let texture : @resource.NxTexture = @json.from_json(value) catch {
    e => {
      issues.push(
        make_issue(
          "ui",
          Error,
          rel_path,
          "invalid nx texture at \{label}: \{e}",
        ),
      )
      return
    }
  }
  let image_rel_path = resolve_ui_image_path(texture.i)
  let image_abs_path = path_join(ctx.assets_root, image_rel_path)
  if !file_exists(image_abs_path) {
    issues.push(
      make_issue(
        "ui",
        Error,
        rel_path,
        "image missing for \{label}: \{image_rel_path}",
      ),
    )
  }
}

///|
fn resolve_ui_image_path(raw_path : String) -> String {
  let p = normalize_path(raw_path).trim_start(chars="/").to_owned()
  let parts = p.split("/").to_array()
  if parts.length() > 1 && parts[0] == "assets" {
    let out : Array[String] = []
    for i = 1; i < parts.length(); i = i + 1 {
      out.push(parts[i].to_owned())
    }
    out.join("/")
  } else {
    p
  }
}
