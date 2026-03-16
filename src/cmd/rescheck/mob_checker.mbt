///|
fn register_mob_checker() -> Checker {
  { name: "mob", run: fn(ctx) { check_mob_resources(ctx) } }
}

///|
fn check_mob_resources(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []
  let mob_dir = "Mob"
  let mob_abs_dir = path_join(ctx.assets_root, mob_dir)
  if not(file_exists(mob_abs_dir)) {
    issues.push(
      make_issue(
        "mob",
        Error,
        mob_dir,
        "missing mob directory (expect assets/Mob)",
      ),
    )
    return issues
  }

  let mob_ids = collect_map_mob_ids(ctx)
  if mob_ids.is_empty() {
    return issues
  }

  for mob_id in mob_ids {
    let rel_file = "Mob/\{mob_id}.img.json"
    let abs_file = path_join(ctx.assets_root, rel_file)
    if not(file_exists(abs_file)) {
      issues.push(
        make_issue(
          "mob",
          Error,
          rel_file,
          "missing mob bundle referenced by map life",
        ),
      )
      continue
    }
    let json = @json.parse(read_text_file(abs_file)) catch {
      e => {
        issues.push(make_issue("mob", Error, rel_file, "invalid json: \{e}"))
        continue
      }
    }
    let refs = collect_i_refs(json)
    for img_ref in refs {
      if img_ref.contains("#") {
        issues.push(
          make_issue(
            "mob",
            Error,
            rel_file,
            "unprocessed spritesheet ref contains '#': \{img_ref}",
          ),
        )
        continue
      }
      let image_rel = resolve_asset_ref_path(img_ref)
      let image_abs = path_join(ctx.assets_root, image_rel)
      if not(file_exists(image_abs)) {
        issues.push(
          make_issue(
            "mob",
            Error,
            rel_file,
            "missing referenced image: \{image_rel}",
          ),
        )
      }
    }
  }

  issues
}

///|
fn collect_map_mob_ids(ctx : RescheckContext) -> Array[String] {
  let out : Array[String] = []
  let seen : Map[String, Bool] = Map::new()
  let preferred_map_file = "map/map1/104030000.img.json"
  let mut preferred_found = false
  for abs_path in ctx.all_files {
    if path_relative(abs_path, ctx.assets_root) == preferred_map_file {
      preferred_found = true
      collect_map_file_mob_ids(abs_path, out, seen)
      break
    }
  }
  if preferred_found {
    return out
  }

  for abs_path in ctx.all_files {
    let rel = path_relative(abs_path, ctx.assets_root)
    if not(rel.has_prefix("map/")) || not(rel.has_suffix(".img.json")) {
      continue
    }
    collect_map_file_mob_ids(abs_path, out, seen)
  }
  out
}

///|
fn collect_map_file_mob_ids(
  abs_path : String,
  out : Array[String],
  seen : Map[String, Bool],
) -> Unit {
  let json = @json.parse(read_text_file(abs_path)) catch { _ => return }
  let life = match json {
    { "life": Object(life), .. } => life
    _ => return
  }
  for _, node in life {
    match node {
      { "type": String("m"), "id": String(id), .. } =>
        if not(seen.contains(id)) {
          seen[id] = true
          out.push(id)
        }
      _ => ()
    }
  }
}

///|
fn collect_i_refs(json : Json) -> Array[String] {
  let out : Array[String] = []
  collect_i_refs_rec(json, out)
  let unique : Array[String] = []
  let seen : Map[String, Bool] = Map::new()
  for p in out {
    if not(seen.contains(p)) {
      seen[p] = true
      unique.push(p)
    }
  }
  unique
}

///|
fn collect_i_refs_rec(json : Json, out : Array[String]) -> Unit {
  match json {
    Object(obj) => {
      match obj.get("__i") {
        Some(String(path)) => out.push(path)
        _ => ()
      }
      for _, child in obj {
        collect_i_refs_rec(child, out)
      }
    }
    Array(arr) =>
      for child in arr {
        collect_i_refs_rec(child, out)
      }
    _ => ()
  }
}

///|
fn resolve_asset_ref_path(raw : String) -> String {
  let path = normalize_path(raw).trim_start(chars="/").to_string()
  if path.has_prefix("assets/") {
    path[7:path.length()].to_string()
  } else {
    path
  }
}
