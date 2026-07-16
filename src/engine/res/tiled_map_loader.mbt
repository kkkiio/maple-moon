///|
/// Resolve a public Tiled resource address and delegate loading to Selene.
///
/// Selene receives the winning pack's physical entry path. The current Selene
/// API owns nested TMJ/TSJ/image loading and does not preserve an explicit pack
/// identity or propagate every nested dependency error; callers should only
/// treat this function as a fallible entry-resource boundary.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let map = try! load_tiled_map("res://Map/tiles/100000000.img.tmj")
/// ignore(map)
/// ```
pub fn load_tiled_map(
  address : String,
) -> @tiled.TiledMap raise ResourceLoadError {
  let physical_path = resolve(address)
  ignore(read_resolved_bytes(physical_path, address))
  @tiled.load_tiled_map(physical_path)
}

///|
/// Load Maple map metadata and its referenced Tiled map from one pack.
///
/// `mx_address` must be a public `res://` address. A relative `tiled_path` in
/// the metadata is resolved from the winning metadata file's physical directory,
/// which prevents nested map resources from crossing to another pack. The
/// returned path is the physical Tiled source path used by Selene.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let (source_path, map) = try! load_tiled_map_from_mx(
///   "res://Map/Map1/100000000.img.mx.json",
/// )
/// ignore(source_path)
/// ignore(map)
/// ```
pub fn load_tiled_map_from_mx(
  mx_address : String,
) -> (String, @tiled.TiledMap) raise ResourceLoadError {
  let mx_path = resolve(mx_address)
  let mx_json = load_json_from_resolved_path(mx_path)
  let tiled_reference = match mx_json {
    { "tiled_path": String(path), .. } if path.length() > 0 => path
    _ =>
      raise ResourceLoadError::DecodeFailed(
        mx_address, "map metadata must contain a non-empty tiled_path",
      )
  }
  let referenced_path = resolve_ref(mx_path, tiled_reference)
  let tiled_path = if referenced_path.has_prefix("res://") {
    resolve(referenced_path)
  } else {
    referenced_path
  }
  ignore(read_resolved_bytes(tiled_path, mx_address + " -> " + tiled_reference))
  (tiled_path, @tiled.load_tiled_map(tiled_path))
}
