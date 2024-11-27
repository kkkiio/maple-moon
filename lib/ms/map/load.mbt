pub(all) struct MapStruct {
  tiles_objs : MapTilesObjs
  backgrounds : Array[Background]
  foregrounds : Array[Background]
  physics : @physics.Physics
  map_info : MapInfo
  portals : MapPortals
}

pub fn load_map(
  map_id : Int,
  map_portals_animations : MapPortalAnimations
) -> @utils.Future[Result[MapStruct, Error]] {
  // TODO: CashShopPreview
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @string_format.extend_id(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  @log.info({ "path": path }, "loading map")
  mapx_loader
  .load_res(path)
  .bind(
    fn(src) -> @utils.Future[Result[(NxNode, MapTilesObjs), Error]] {
      guard src.is_null().not() else {
        return @utils.Future::from_value(
          Err(@resource.LoadError("map not found, id=\{map_id}")),
        )
      }
      MapTilesObjs::load(src).map(
        fn(res) { res.map(fn(tiles_objs) { (src, tiles_objs) }) },
      )
    },
  )
  .map_exn(
    fn(res : Result[(NxNode, MapTilesObjs), Error]) {
      let (src, tiles_objs) = res.unwrap_or_error!()
      @log.info({ "map_id": map_id }, "map loaded")
      let (backgrounds, foregrounds) = load_backgrounds(src["back"])
      let physics = @physics.Physics::from_resource!(src["foothold"])
      let map_info = MapInfo::from_resource(
        src,
        physics.get_fht().get_walls(),
        physics.get_fht().get_borders(),
      )
      let portals = MapPortals::load(
        src["portal"],
        map_id,
        map_portals_animations,
      )
      { tiles_objs, backgrounds, foregrounds, physics, map_info, portals }
    },
  )
}

fn map_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("map")
}

let mapx_loader : @resource.AsyncLoader = @resource.AsyncLoader::new("mapx")
