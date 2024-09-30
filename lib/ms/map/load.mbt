pub struct MapStruct {
  tiles_objs : MapTilesObjs
  backgrounds : MapBackgrounds
  physics : @physics.Physics
  map_info : MapInfo
  portals : MapPortals
}

typealias MapLoader = () -> MapStruct?!Error

pub fn load_map(map_id : Int) -> MapLoader {
  // TODO: CashShopPreview
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @string_format.extend_id(map_id, 9)
  let path = ["Map", "Map\{prefix}", "\{strid}.img"]
  @log.info({ "path": path }, "loading map")
  let loading_res = map_loader().load_res(path)
  fn() {
    guard let Some(src) = loading_res.poll() else { None => None }
    @log.info({ "map_id": map_id }, "map loaded")
    let tiles_objs = MapTilesObjs::from_resource!(src)
    let backgrounds = MapBackgrounds::new(src["back"])
    let physics = @physics.Physics::from_resource(src["foothold"])
    let map_info = MapInfo::from_resource!(
      src,
      physics.get_fht().get_walls(),
      physics.get_fht().get_borders(),
    )
    let portals = MapPortals::from_resource(src["portal"], map_id)
    Some({ tiles_objs, backgrounds, physics, map_info, portals })
  }
}

fn map_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("map")
}
