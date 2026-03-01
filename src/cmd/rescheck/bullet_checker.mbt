///|
fn register_bullet_checker() -> Checker {
  { name: "bullet", run: fn(ctx) { check_bullet_resources(ctx) } }
}

///|
fn check_bullet_resources(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []
  let bullet_ids_by_prefix : Map[String, Array[String]] = {}
  for bullet_id in @bullet.all_bullet_ids {
    guard bullet_id.length() >= 4 else {
      issues.push(
        make_issue(
          "bullet",
          Error,
          "lib/ms/bullet/module.mbt",
          "invalid bullet id: \{bullet_id}",
        ),
      )
      continue
    }
    let prefix = bullet_id[:4].to_string() catch {
      _ => {
        issues.push(
          make_issue(
            "bullet",
            Error,
            "lib/ms/bullet/module.mbt",
            "invalid bullet id: \{bullet_id}",
          ),
        )
        continue
      }
    }
    match bullet_ids_by_prefix.get(prefix) {
      Some(ids) => ids.push(bullet_id)
      None => bullet_ids_by_prefix.set(prefix, [bullet_id])
    }
  }

  let prefixes = bullet_ids_by_prefix.keys().collect()
  prefixes.sort()
  for prefix in prefixes {
    let rel_file = "Item/Consume/\{prefix}.img.json"
    let abs_file = path_join(ctx.assets_root, rel_file)
    if not(file_exists(abs_file)) {
      issues.push(
        make_issue(
          "bullet",
          Error,
          rel_file,
          "missing bullet bundle json for prefix \{prefix}",
        ),
      )
      continue
    }
    let content = read_text_file(abs_file)
    let json = @json.parse(content) catch {
      e => {
        issues.push(make_issue("bullet", Error, rel_file, "invalid json: \{e}"))
        continue
      }
    }
    guard json is Object(bundle_obj) else {
      issues.push(
        make_issue("bullet", Error, rel_file, "bundle root must be object"),
      )
      continue
    }

    let ids = bullet_ids_by_prefix.get(prefix).unwrap()
    for bullet_id in ids {
      match bundle_obj.get(bullet_id) {
        Some(entry) =>
          bullet_validate_entry(ctx, rel_file, bullet_id, entry, issues)
        None =>
          issues.push(
            make_issue(
              "bullet",
              Error,
              rel_file,
              "missing bullet key '\{bullet_id}'",
            ),
          )
      }
    }
  }

  issues
}

///|
fn bullet_validate_entry(
  ctx : RescheckContext,
  rel_file : String,
  bullet_id : String,
  entry : Json,
  issues : Array[CheckIssue],
) -> Unit {
  guard entry is Object(entry_obj) else {
    issues.push(
      make_issue(
        "bullet",
        Error,
        rel_file,
        "bullet '\{bullet_id}' entry must be object",
      ),
    )
    return
  }

  match entry_obj.get("info") {
    Some(Object(info_obj)) => {
      bullet_validate_texture_field(
        ctx, rel_file, bullet_id, info_obj, "icon", issues,
      )
      bullet_validate_texture_field(
        ctx, rel_file, bullet_id, info_obj, "iconRaw", issues,
      )
    }
    Some(_) =>
      issues.push(
        make_issue(
          "bullet",
          Error,
          rel_file,
          "bullet '\{bullet_id}' field info must be object",
        ),
      )
    None =>
      issues.push(
        make_issue(
          "bullet",
          Error,
          rel_file,
          "bullet '\{bullet_id}' missing field info",
        ),
      )
  }

  bullet_check_image_refs_field(
    ctx, rel_file, bullet_id, entry_obj, "bullet", issues,
  )
  bullet_check_image_refs_field(
    ctx, rel_file, bullet_id, entry_obj, "hit", issues,
  )
}

///|
fn bullet_validate_texture_field(
  ctx : RescheckContext,
  rel_file : String,
  bullet_id : String,
  info_obj : Map[String, Json],
  field : String,
  issues : Array[CheckIssue],
) -> Unit {
  match info_obj.get(field) {
    Some(value) => {
      let texture : @resource.NxTexture = @json.from_json(value) catch {
        e => {
          issues.push(
            make_issue(
              "bullet",
              Error,
              rel_file,
              "bullet '\{bullet_id}' invalid info.\{field}: \{e}",
            ),
          )
          return
        }
      }
      let image_rel_path = bullet_resolve_asset_relative_path(texture.i)
      let image_abs_path = path_join(ctx.assets_root, image_rel_path)
      if not(file_exists(image_abs_path)) {
        issues.push(
          make_issue(
            "bullet",
            Error,
            rel_file,
            "bullet '\{bullet_id}' info.\{field} image missing: \{image_rel_path}",
          ),
        )
      }
    }
    None =>
      issues.push(
        make_issue(
          "bullet",
          Error,
          rel_file,
          "bullet '\{bullet_id}' missing info.\{field}",
        ),
      )
  }
}

///|
fn bullet_check_image_refs_field(
  ctx : RescheckContext,
  rel_file : String,
  bullet_id : String,
  entry_obj : Map[String, Json],
  field : String,
  issues : Array[CheckIssue],
) -> Unit {
  match entry_obj.get(field) {
    Some(value) => {
      let refs : Array[String] = []
      bullet_collect_i_refs_rec(value, refs)
      let uniq = bullet_unique_paths(refs)
      for raw_path in uniq {
        let image_rel_path = bullet_resolve_asset_relative_path(raw_path)
        let image_abs_path = path_join(ctx.assets_root, image_rel_path)
        if not(file_exists(image_abs_path)) {
          issues.push(
            make_issue(
              "bullet",
              Error,
              rel_file,
              "bullet '\{bullet_id}' \{field} image missing: \{image_rel_path}",
            ),
          )
        }
      }
    }
    None => ()
  }
}

///|
fn bullet_collect_i_refs_rec(json : Json, out : Array[String]) -> Unit {
  match json {
    Object(obj) => {
      match obj.get("__i") {
        Some(String(path)) => out.push(path)
        _ => ()
      }
      for _, child in obj {
        bullet_collect_i_refs_rec(child, out)
      }
    }
    Array(arr) =>
      for child in arr {
        bullet_collect_i_refs_rec(child, out)
      }
    _ => ()
  }
}

///|
fn bullet_unique_paths(paths : Array[String]) -> Array[String] {
  let seen : Map[String, Bool] = {}
  let unique : Array[String] = []
  for p in paths {
    if not(seen.contains(p)) {
      seen[p] = true
      unique.push(p)
    }
  }
  unique
}

///|
fn bullet_resolve_asset_relative_path(raw_path : String) -> String {
  let path = normalize_path(raw_path).trim_start(chars="/").to_string()
  if path.has_prefix("assets/") {
    path[7:path.length()].to_string() catch {
      _ => path
    }
  } else {
    path
  }
}
