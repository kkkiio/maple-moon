///|
using @resource {type NxTexture}

///|
struct ItemRef {
  item_id : Int
  category : String
  file_name : String
  zid : String
}

///|
fn register_item_checker() -> Checker {
  { name: "item", run: fn(ctx) { check_item_resources(ctx) } }
}

///|
fn check_item_resources(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []

  let categories = ["Consume", "Cash", "Etc", "Install", "Pet"]
  for category in categories {
    let rel_dir = "Item/\{category}"
    let abs_dir = path_join(ctx.assets_root, rel_dir)
    if not(file_exists(abs_dir)) {
      issues.push(
        make_issue("item", Error, rel_dir, "missing item category directory"),
      )
    }
  }

  let refs = collect_drop_item_refs(ctx)
  let checked_file : Map[String, Bool] = Map::new()
  let parsed_file : Map[String, Json] = Map::new()
  let missing_bundle_ids : Map[String, Array[Int]] = Map::new()

  for item_ref in refs {
    let rel_file = "Item/\{item_ref.category}/\{item_ref.file_name}"
    let abs_file = path_join(ctx.assets_root, rel_file)
    if not(file_exists(abs_file)) {
      append_missing_bundle_id(missing_bundle_ids, rel_file, item_ref.item_id)
      continue
    }

    if not(checked_file.contains(abs_file)) {
      checked_file[abs_file] = true
      let content = read_text_file(abs_file)
      let json = @json.parse(content) catch {
        e => {
          issues.push(
            make_issue(
              "item",
              Error,
              rel_file,
              "invalid item bundle json: \{e}",
            ),
          )
          continue
        }
      }
      parsed_file[abs_file] = json
    }

    guard parsed_file.get(abs_file) is Some(bundle) else { continue }
    match bundle {
      Object(obj) =>
        if not(obj.contains(item_ref.zid)) {
          issues.push(
            make_issue(
              "item",
              Error,
              rel_file,
              "missing item key '\{item_ref.zid}'",
            ),
          )
        } else {
          let entry = obj[item_ref.zid]
          validate_item_entry_texture(entry, rel_file, item_ref.zid, issues)
        }
      _ =>
        issues.push(
          make_issue("item", Error, rel_file, "item bundle root must be object"),
        )
    }
  }

  for rel_file in missing_bundle_ids.keys() {
    if should_skip_missing_item_bundle(rel_file) {
      continue
    }
    let item_ids = missing_bundle_ids.get(rel_file).unwrap()
    let sample_ids : Array[String] = []
    let sample_len = if item_ids.length() < 3 { item_ids.length() } else { 3 }
    for i = 0; i < sample_len; i = i + 1 {
      sample_ids.push(item_ids[i].to_string())
    }
    let sample = sample_ids.join(",")
    let detail = if item_ids.length() <= 3 {
      "missing item bundle, referenced drop item_ids=\{sample}"
    } else {
      "missing item bundle, referenced by \{item_ids.length()} drop item_ids (sample: \{sample})"
    }
    issues.push(make_issue("item", Error, rel_file, detail))
  }

  check_shop_equip_item_resources(ctx, issues)

  issues
}

///|
priv struct ShopEquipRef {
  item_id : Int
  category : String
  file_name : String
}

///|
fn check_shop_equip_item_resources(
  ctx : RescheckContext,
  issues : Array[CheckIssue],
) -> Unit {
  let shops_rel_file = "data/shops.csv"
  let shops_abs_file = path_join(ctx.assets_root, shops_rel_file)
  if not(file_exists(shops_abs_file)) {
    issues.push(
      make_issue("item", Error, shops_rel_file, "missing npc shop data file"),
    )
    return
  }
  let shopitems_rel_file = "data/shopitems.csv"
  let shopitems_abs_file = path_join(ctx.assets_root, shopitems_rel_file)
  if not(file_exists(shopitems_abs_file)) {
    issues.push(
      make_issue(
        "item",
        Error,
        shopitems_rel_file,
        "missing npc shop item data file",
      ),
    )
    return
  }
  let equip_refs = collect_shop_equip_refs(shopitems_abs_file, issues)
  let parsed_file : Map[String, Json] = Map::new()
  for equip_ref in equip_refs {
    let equip_rel_file = "Character/\{equip_ref.category}/\{equip_ref.file_name}"
    let equip_abs_file = path_join(ctx.assets_root, equip_rel_file)
    if not(file_exists(equip_abs_file)) {
      issues.push(
        make_issue(
          "item",
          Error,
          equip_rel_file,
          "missing equip json referenced by npc shop item_id=\{equip_ref.item_id}",
        ),
      )
      continue
    }
    if not(parsed_file.contains(equip_abs_file)) {
      let content = read_text_file(equip_abs_file)
      let json = @json.parse(content) catch {
        e => {
          issues.push(
            make_issue(
              "item",
              Error,
              equip_rel_file,
              "invalid equip json: \{e}",
            ),
          )
          continue
        }
      }
      parsed_file[equip_abs_file] = json
    }
    guard parsed_file.get(equip_abs_file) is Some(equip_json) else { continue }
    validate_equip_json_images(
      ctx,
      equip_json,
      equip_rel_file,
      equip_ref.item_id,
      issues,
    )
  }
}

///|
fn collect_shop_equip_refs(
  shopitems_file_abs_path : String,
  issues : Array[CheckIssue],
) -> Array[ShopEquipRef] {
  let refs : Array[ShopEquipRef] = []
  let seen : Map[String, Bool] = Map::new()
  let lines = read_text_file(shopitems_file_abs_path).split("\n").collect()
  if lines.length() == 0 {
    issues.push(
      make_issue("item", Error, "data/shopitems.csv", "shopitems.csv is empty"),
    )
    return refs
  }
  let header = @csv.parse_csv_header(lines[0].to_string())
  for i = 1; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line.is_empty() {
      continue
    }
    let fields = @csv.parse_csv_line(line.to_string())
    let item_id = @csv.parse_csv_int_field_or_default(
      fields, header, "itemid", -1,
    )
    if item_id <= 0 {
      continue
    }
    guard classify_local_equip_category(item_id) is Some(category) else {
      continue
    }
    let file_name = "0\{item_id}.img.json"
    let key = "\{category}|\{file_name}"
    if seen.contains(key) {
      continue
    }
    seen[key] = true
    refs.push({ item_id, category, file_name })
  }
  refs
}

///|
fn classify_local_equip_category(item_id : Int) -> String? {
  if item_id / 1000000 != 1 {
    return None
  }
  let item_prefix = item_id / 10000
  let index = item_prefix - 100
  if index == 4 {
    return Some("Coat")
  }
  if index == 6 {
    return Some("Pants")
  }
  if index == 7 {
    return Some("Shoes")
  }
  if index >= 30 && index <= 70 {
    return Some("Weapon")
  }
  None
}

///|
fn validate_equip_json_images(
  ctx : RescheckContext,
  json : Json,
  rel_file : String,
  item_id : Int,
  issues : Array[CheckIssue],
) -> Unit {
  fn walk(
    node : Json,
    ctx : RescheckContext,
    rel_file : String,
    item_id : Int,
    issues : Array[CheckIssue],
  ) -> Unit {
    match node {
      Object(obj) => {
        match obj.get("__i") {
          Some(String(image_path)) => {
            if image_path.contains("#") {
              issues.push(
                make_issue(
                  "item",
                  Error,
                  rel_file,
                  "item_id=\{item_id} still uses '#'-framed __i, reanim output expected",
                ),
              )
            }
            if not(obj.contains("__off")) {
              issues.push(
                make_issue(
                  "item",
                  Error,
                  rel_file,
                  "item_id=\{item_id} image node missing __off",
                ),
              )
            }
            let image_rel_path = resolve_asset_relative_path(image_path)
            let image_abs_path = path_join(ctx.assets_root, image_rel_path)
            if not(file_exists(image_abs_path)) {
              issues.push(
                make_issue(
                  "item",
                  Error,
                  rel_file,
                  "item_id=\{item_id} image missing: \{image_rel_path}",
                ),
              )
            }
          }
          _ => ()
        }
        for _, value in obj {
          walk(value, ctx, rel_file, item_id, issues)
        }
      }
      Array(arr) =>
        for value in arr {
          walk(value, ctx, rel_file, item_id, issues)
        }
      _ => ()
    }
  }
  walk(json, ctx, rel_file, item_id, issues)
}

///|
fn resolve_asset_relative_path(raw_path : String) -> String {
  let p = normalize_path(raw_path).trim_start(chars="/").to_string()
  let parts = p.split("/").to_array()
  if parts.length() > 1 && parts[0] == "assets" {
    let out : Array[String] = []
    for i = 1; i < parts.length(); i = i + 1 {
      out.push(parts[i].to_string())
    }
    out.join("/")
  } else {
    p
  }
}

///|
fn should_skip_missing_item_bundle(rel_file : String) -> Bool {
  // Temporary whitelist: 0301 resources are intentionally not imported yet.
  rel_file == "Item/Install/0301.img.json"
}

///|
fn validate_item_entry_texture(
  entry : Json,
  rel_file : String,
  zid : String,
  issues : Array[CheckIssue],
) -> Unit {
  guard entry is { "info": Object(info), .. } else {
    issues.push(
      make_issue(
        "item",
        Error,
        rel_file,
        "item '\{zid}' missing object field 'info'",
      ),
    )
    return
  }
  validate_texture_field(info, "icon", rel_file, zid, issues)
  validate_texture_field(info, "iconRaw", rel_file, zid, issues)
}

///|
fn validate_texture_field(
  info : Map[String, Json],
  field : String,
  rel_file : String,
  zid : String,
  issues : Array[CheckIssue],
) -> Unit {
  match info.get(field) {
    Some(v) => {
      let texture : NxTexture = @json.from_json(v) catch {
        e => {
          issues.push(
            make_issue(
              "item",
              Error,
              rel_file,
              "item '\{zid}' invalid \{field} nx texture: \{e}",
            ),
          )
          return
        }
      }
      let image_rel_path = resolve_item_image_path(texture.i)
      let image_abs_path = path_join("assets", image_rel_path)
      if not(file_exists(image_abs_path)) {
        issues.push(
          make_issue(
            "item",
            Error,
            rel_file,
            "item '\{zid}' \{field} image missing: \{image_rel_path}",
          ),
        )
      }
    }
    None =>
      issues.push(
        make_issue(
          "item",
          Error,
          rel_file,
          "item '\{zid}' missing info.\{field}",
        ),
      )
  }
}

///|
fn resolve_item_image_path(raw_path : String) -> String {
  let p = normalize_path(raw_path).trim_start(chars="/").to_string()
  let parts = p.split("/").to_array()
  if parts.length() > 1 && parts[0] == "assets" {
    let out : Array[String] = []
    for i = 1; i < parts.length(); i = i + 1 {
      out.push(parts[i].to_string())
    }
    out.join("/")
  } else {
    p
  }
}

///|
fn append_missing_bundle_id(
  out : Map[String, Array[Int]],
  rel_file : String,
  item_id : Int,
) -> Unit {
  match out.get(rel_file) {
    Some(ids) => ids.push(item_id)
    None => out[rel_file] = [item_id]
  }
}

///|
fn collect_drop_item_refs(ctx : RescheckContext) -> Array[ItemRef] {
  let files = ["data/mob_drops.csv", "data/drop_data_global.csv"]
  let refs : Array[ItemRef] = []
  let seen : Map[String, Bool] = Map::new()

  for rel_file in files {
    let abs_file = path_join(ctx.assets_root, rel_file)
    if not(file_exists(abs_file)) {
      continue
    }
    let content = read_text_file(abs_file)
    let lines = content.split("\n").collect()
    for i = 1; i < lines.length(); i = i + 1 {
      let line = lines[i].trim()
      if line.is_empty() {
        continue
      }
      let fields = @csv.parse_csv_line(line.to_string())
      if fields.length() < 3 {
        continue
      }
      let item_id = @strconv.parse_int(@csv.strip_quotes(fields[2])) catch {
        _ => continue
      }
      if item_id <= 0 {
        continue
      }
      guard classify_item(item_id) is Some((category, file_name, zid)) else {
        continue
      }
      let key = "\{category}|\{file_name}|\{zid}"
      if seen.contains(key) {
        continue
      }
      seen[key] = true
      refs.push({ item_id, category, file_name, zid })
    }
  }

  refs
}

///|
fn classify_item(item_id : Int) -> (String, String, String)? {
  let cat_num = item_id / 1000000
  let category = match cat_num {
    2 => "Consume"
    3 => "Install"
    4 => "Etc"
    5 => "Cash"
    _ => return None
  }
  let prefix = zero_pad4((item_id / 10000).to_string())
  let file_name = "\{prefix}.img.json"
  let zid = "0\{item_id}"
  Some((category, file_name, zid))
}

///|
fn zero_pad4(s : String) -> String {
  let mut out = s
  while out.length() < 4 {
    out = "0" + out
  }
  out
}
