///|
/// Errors produced while parsing, resolving, or reading virtual resources.
pub(all) suberror ResourceLoadError {
  /// The public `res://` address or a file-relative reference is invalid.
  InvalidAddress(String)
  /// A resource-pack id or physical root is invalid.
  InvalidMount(String)
  /// No mounted pack contains the requested resource key.
  NotFound(String)
  /// A mounted resource exists but its text or structured payload is invalid.
  DecodeFailed(String, String)
} derive(Debug)

///|
/// A normalized pack-local path parsed from a public `res://` address.
///
/// `ResourceKey` never contains the `res://` scheme, a pack id, or a physical
/// installation path.
///
/// # Example
/// ```moonbit nocheck
/// let key = try! ResourceKey::parse("res://Mob/./0100100.img/mx.json")
/// assert_eq(key.to_address(), "res://Mob/0100100.img/mx.json")
/// ```
pub struct ResourceKey(String) derive(Eq, Debug)

///|
/// Parse and normalize a public resource address.
///
/// Backslashes and `.` segments are normalized. Parent segments may only remove
/// a preceding key segment; escaping above the resource root raises
/// `ResourceLoadError::InvalidAddress`.
///
/// # Example
/// ```moonbit nocheck
/// let key = try! ResourceKey::parse("res://Map\\Map1/../tiles/map.tmj")
/// assert_eq(key.to_address(), "res://Map/tiles/map.tmj")
/// ```
pub fn ResourceKey::parse(
  address : String,
) -> ResourceKey raise ResourceLoadError {
  guard address.has_prefix("res://") else {
    raise ResourceLoadError::InvalidAddress(
      "resource address must start with res://: \{address}",
    )
  }
  let raw = address
    .strip_prefix("res://")
    .map(fn(value) { value.to_owned() })
    .unwrap_or("")
    .replace(old="\\", new="/")
  guard raw.length() > 0 && !raw.has_prefix("/") && !raw.contains(":") else {
    raise ResourceLoadError::InvalidAddress(
      "resource address must contain a relative key: \{address}",
    )
  }
  let mut depth = 0
  for segment in raw.split("/") {
    if segment == "" || segment == "." {
      continue
    }
    if segment is ".." {
      guard depth > 0 else {
        raise ResourceLoadError::InvalidAddress(
          "resource address escapes its root: \{address}",
        )
      }
      depth = depth - 1
    } else {
      depth = depth + 1
    }
  }
  guard depth > 0 else {
    raise ResourceLoadError::InvalidAddress(
      "resource address must identify a file: \{address}",
    )
  }
  let raw_path : @posix.Path = raw
  let normalized = raw_path.normalize().to_string()
  guard normalized != "." && !normalized.has_prefix("../") && normalized != ".." else {
    raise ResourceLoadError::InvalidAddress(
      "resource address escapes its root: \{address}",
    )
  }
  ResourceKey(normalized)
}

///|
/// Return the normalized public address represented by this key.
///
/// # Example
/// ```moonbit nocheck
/// let key = try! ResourceKey::parse("res://UI/Basic.img/Cursor/cursor.png")
/// assert_eq(key.to_address(), "res://UI/Basic.img/Cursor/cursor.png")
/// ```
pub fn ResourceKey::to_address(self : ResourceKey) -> String {
  "res://" + self.0
}

///|
/// Return the scheme-free path used to look up this key inside each pack.
///
/// # Example
/// ```moonbit nocheck
/// let key = try! ResourceKey::parse("res://Data/shops.tsv")
/// assert_eq(key.to_string(), "Data/shops.tsv")
/// ```
pub fn ResourceKey::to_string(self : ResourceKey) -> String {
  self.0
}

///|
priv struct ResourceMount {
  id : String
  root : String
  files : Set[String]
}

///|
let resource_mounts : Array[ResourceMount] = []

///|
let resource_index : Map[String, String] = Map([])

///|
/// Atomically replace all mounted packs.
///
/// `packs` is ordered from lowest to highest priority. Duplicate ids update the
/// root at their first position, so changing a pack installation path does not
/// silently change its priority. If validation fails, the previous mount table
/// remains installed.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([
///   ("base", "assets/base"),
///   ("dlc-elnath", "assets/dlc-elnath"),
///   ("patch-1", "assets/patch-1"),
/// ])
/// ```
pub fn configure_packs(
  packs : Array[(String, String)],
) -> Unit raise ResourceLoadError {
  guard !packs.is_empty() else {
    raise ResourceLoadError::InvalidMount(
      "resource pack configuration must contain at least one pack",
    )
  }
  let next_mounts : Array[ResourceMount] = []
  for pack in packs {
    let (pack_id, root) = pack
    guard pack_id.length() > 0 &&
      !pack_id.contains("/") &&
      !pack_id.contains("\\") &&
      !pack_id.contains(":") &&
      pack_id != "." &&
      pack_id != ".." else {
      raise ResourceLoadError::InvalidMount(
        "invalid resource pack id: \{pack_id}",
      )
    }
    let physical_root = root.replace(old="\\", new="/")
    guard physical_root.length() > 0 && !physical_root.contains("://") else {
      raise ResourceLoadError::InvalidMount(
        "invalid physical root for resource pack \{pack_id}: \{root}",
      )
    }
    let root_path : @posix.Path = physical_root
    let normalized_root = root_path.normalize().to_string()
    guard normalized_root.length() > 0 &&
      normalized_root != "." &&
      normalized_root != "/" else {
      raise ResourceLoadError::InvalidMount(
        "resource pack root must identify a dedicated directory: \{pack_id}",
      )
    }
    let next : ResourceMount = {
      id: pack_id,
      root: normalized_root,
      files: Set([]),
    }
    let mut replaced = false
    for index, mounted in next_mounts {
      if mounted.id == pack_id {
        next_mounts[index] = next
        replaced = true
        break
      }
    }
    if !replaced {
      next_mounts.push(next)
    }
  }
  let next_index : Map[String, String] = Map([])
  let next_owners : Map[String, String] = Map([])
  for _, mounted in next_mounts {
    let manifest_path = mounted.root + "/pack.json"
    guard @platform_asset_io.read_bytes(manifest_path) is Some(bytes) else {
      raise ResourceLoadError::InvalidMount(
        "resource pack manifest not found: pack=\{mounted.id}, path=\{manifest_path}",
      )
    }
    let source = @encoding/utf8.decode(bytes) catch {
      error =>
        raise ResourceLoadError::InvalidMount(
          "resource pack manifest is not UTF-8: pack=\{mounted.id}, path=\{manifest_path}, error=\{to_repr(error)}",
        )
    }
    let manifest = @json.parse(source) catch {
      error =>
        raise ResourceLoadError::InvalidMount(
          "resource pack manifest is not JSON: pack=\{mounted.id}, path=\{manifest_path}, error=\{to_repr(error)}",
        )
    }
    guard manifest
      is {
        "schema": 2,
        "id": String(manifest_id),
        "overrides": Array(override_values),
        "files": Array(files),
        ..
      } else {
      raise ResourceLoadError::InvalidMount(
        "resource pack manifest must contain schema=2, id, overrides, and files: \{manifest_path}",
      )
    }
    guard manifest_id == mounted.id else {
      raise ResourceLoadError::InvalidMount(
        "resource pack id does not match manifest: mounted=\{mounted.id}, manifest=\{manifest_id}",
      )
    }
    let overrides : Set[String] = Set([])
    for value in override_values {
      guard value is String(address) else {
        raise ResourceLoadError::InvalidMount(
          "resource pack overrides must contain strings: pack=\{mounted.id}",
        )
      }
      let key = ResourceKey::parse(address) catch {
        error =>
          raise ResourceLoadError::InvalidMount(
            "invalid override address in pack \{mounted.id}: address=\{address}, error=\{to_repr(error)}",
          )
      }
      guard key.to_address() == address && !overrides.contains(key.to_string()) else {
        raise ResourceLoadError::InvalidMount(
          "resource pack override address must be normalized and unique: pack=\{mounted.id}, address=\{address}",
        )
      }
      overrides.add(key.to_string())
    }
    for file in files {
      guard file is String(path) else {
        raise ResourceLoadError::InvalidMount(
          "resource pack files must contain strings: \{manifest_path}",
        )
      }
      let key = ResourceKey::parse("res://" + path) catch {
        error =>
          raise ResourceLoadError::InvalidMount(
            "invalid resource path in pack \{mounted.id}: path=\{path}, error=\{to_repr(error)}",
          )
      }
      guard key.to_string() == path && path != "pack.json" else {
        raise ResourceLoadError::InvalidMount(
          "resource pack file path must be normalized and cannot name pack.json: pack=\{mounted.id}, path=\{path}",
        )
      }
      guard !mounted.files.contains(path) else {
        raise ResourceLoadError::InvalidMount(
          "duplicate resource path in pack \{mounted.id}: \{path}",
        )
      }
      mounted.files.add(path)
      if next_owners.get(path) is Some(owner) {
        guard overrides.contains(path) else {
          raise ResourceLoadError::InvalidMount(
            "resource pack path conflict requires an explicit override: pack=\{mounted.id}, previous=\{owner}, address=res://\{path}",
          )
        }
      }
      let mounted_root : @posix.Path = mounted.root
      next_index.set(path, mounted_root.join(path).normalize().to_string())
      next_owners.set(path, mounted.id)
    }
  }
  resource_mounts.clear()
  for mounted in next_mounts {
    resource_mounts.push(mounted)
  }
  resource_index.clear()
  for key, physical_path in next_index {
    resource_index.set(key, physical_path)
  }
}

///|
/// Mount one resource pack after the existing packs.
///
/// A new id receives the highest priority. Mounting an existing id updates its
/// physical root in place and preserves its current priority.
///
/// # Example
/// ```moonbit nocheck
/// try! mount_pack("base", "assets/base")
/// try! mount_pack("patch-1", "assets/patch-1")
/// ```
pub fn mount_pack(
  pack_id : String,
  root : String,
) -> Unit raise ResourceLoadError {
  guard pack_id.length() > 0 &&
    !pack_id.contains("/") &&
    !pack_id.contains("\\") &&
    !pack_id.contains(":") &&
    pack_id != "." &&
    pack_id != ".." else {
    raise ResourceLoadError::InvalidMount(
      "invalid resource pack id: \{pack_id}",
    )
  }
  let physical_root = root.replace(old="\\", new="/")
  guard physical_root.length() > 0 && !physical_root.contains("://") else {
    raise ResourceLoadError::InvalidMount(
      "invalid physical root for resource pack \{pack_id}: \{root}",
    )
  }
  let root_path : @posix.Path = physical_root
  let normalized_root = root_path.normalize().to_string()
  guard normalized_root.length() > 0 &&
    normalized_root != "." &&
    normalized_root != "/" else {
    raise ResourceLoadError::InvalidMount(
      "resource pack root must identify a dedicated directory: \{pack_id}",
    )
  }
  let next_packs = resource_mounts.map(fn(mounted) {
    if mounted.id == pack_id {
      (pack_id, normalized_root)
    } else {
      (mounted.id, mounted.root)
    }
  })
  if !resource_mounts.any(fn(mounted) { mounted.id == pack_id }) {
    next_packs.push((pack_id, normalized_root))
  }
  configure_packs(next_packs)
}

///|
/// Remove all configured resource packs.
///
/// This is useful when replacing the complete runtime configuration or
/// isolating tests. Resource and renderer caches owned by other packages are not
/// modified.
///
/// # Example
/// ```moonbit nocheck
/// clear_mounts()
/// ```
pub fn clear_mounts() -> Unit {
  resource_mounts.clear()
  resource_index.clear()
}

///|
/// Resolve a public resource address to the first matching physical path.
///
/// Packs are searched from highest to lowest priority. The returned path keeps
/// the winning pack root so relative references remain inside that pack.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let path = try! resolve("res://Data/shops.tsv")
/// assert_eq(path, "assets/base/Data/shops.tsv")
/// ```
pub fn resolve(address : String) -> String raise ResourceLoadError {
  let key = ResourceKey::parse(address)
  if resource_index.get(key.0) is Some(physical_path) {
    return physical_path
  }
  let mounted_ids = resource_mounts.map(fn(mounted) { mounted.id }).join(",")
  raise ResourceLoadError::NotFound(
    "resource not found: address=\{key.to_address()}, mounted=[\{mounted_ids}]",
  )
}

///|
/// Resolve a resource that is required for the current runtime.
///
/// This is the explicit termination boundary for predefined resources. Use
/// `resolve` inside fallible loaders that should propagate errors.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let path = require_path("res://Data/shops.tsv")
/// ignore(path)
/// ```
pub fn require_path(address : String) -> String {
  resolve(address) catch {
    error =>
      abort(
        "failed to require resource path: address=\{address}, error=\{to_repr(error)}",
      )
  }
}

///|
/// Resolve a file-relative reference against a declaration file.
///
/// A logical `res://` base produces a logical address. A physical path returned
/// by `resolve` produces another path inside the same mounted pack. Explicit
/// `res://` references remain logical and are resolved by normal pack priority.
///
/// # Example
/// ```moonbit nocheck
/// let path = try! resolve_ref(
///   "res://Mob/0100100.img/mx.json",
///   "animation.json",
/// )
/// assert_eq(path, "res://Mob/0100100.img/animation.json")
/// ```
pub fn resolve_ref(
  base_path : String,
  reference : String,
) -> String raise ResourceLoadError {
  if reference.has_prefix("res://") {
    return ResourceKey::parse(reference).to_address()
  }
  let normalized_reference = reference.replace(old="\\", new="/")
  guard normalized_reference.length() > 0 &&
    !normalized_reference.has_prefix("/") &&
    !normalized_reference.contains(":") else {
    raise ResourceLoadError::InvalidAddress(
      "resource reference must be relative: \{reference}, base=\{base_path}",
    )
  }
  if base_path.has_prefix("res://") {
    let base_key = ResourceKey::parse(base_path)
    let base : @posix.Path = base_key.0
    let resolved = base
      .dirname()
      .join(normalized_reference)
      .normalize()
      .to_string()
    guard resolved != "." &&
      resolved != ".." &&
      !resolved.has_prefix("../") &&
      !resolved.has_prefix("/") else {
      raise ResourceLoadError::InvalidAddress(
        "resource reference escapes its pack: \{reference}, base=\{base_path}",
      )
    }
    return ResourceKey(resolved).to_address()
  }
  let base : @posix.Path = base_path.replace(old="\\", new="/")
  let normalized_base = base.normalize().to_string()
  let mut winning_mount : ResourceMount? = None
  let mut winning_root_length = -1
  for mounted in resource_mounts {
    if normalized_base.has_prefix(mounted.root + "/") &&
      mounted.root.length() > winning_root_length {
      winning_mount = Some(mounted)
      winning_root_length = mounted.root.length()
    }
  }
  guard winning_mount is Some(mounted) else {
    raise ResourceLoadError::InvalidAddress(
      "physical resource base is not inside a mounted pack: \{base_path}",
    )
  }
  let resolved = base
    .normalize()
    .dirname()
    .join(normalized_reference)
    .normalize()
    .to_string()
  guard resolved.has_prefix(mounted.root + "/") else {
    raise ResourceLoadError::InvalidAddress(
      "resource reference escapes pack \{mounted.id}: \{reference}, base=\{base_path}",
    )
  }
  guard resolved.strip_prefix(mounted.root + "/") is Some(pack_path) &&
    mounted.files.contains(pack_path.to_owned()) else {
    raise ResourceLoadError::NotFound(
      "resource reference is not declared by pack \{mounted.id}: reference=\{reference}, base=\{base_path}, physical=\{resolved}",
    )
  }
  resolved
}
