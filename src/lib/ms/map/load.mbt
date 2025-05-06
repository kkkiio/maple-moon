///|
pub(all) struct MapStruct {
  id : Int
  tiles_objs : MapTilesObjs
  backgrounds : Backgrounds
  physics : @physics.Physics
  map_info : MapInfo
  portals : MapPortals
  mini_map_resources : MiniMapResource?
}

///|
fn get_mapx_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("mapx")
}

///|
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
  get_mapx_loader()
  .load_res(path)
  .map_exn(fn(src) {
    guard not(src.is_null()) else {
      raise @resource.LoadError("map not found, id=\{map_id}")
    }
    let tiles_objs_f = MapTilesObjs::load(src)
    let spec : BackgroundsSpec = @json.from_json!(src["back"].value())
    let backgrounds_f = load_backgrounds(background_loader, spec)
    let physics = @physics.Physics::from_resource!(src["foothold"])
    let map_info = MapInfo::from_resource(
      src,
      physics.get_fht().get_walls(),
      physics.get_fht().get_borders(),
    )
    let portal_res : @resource.MapBasedArray[PortalMarker] = @json.from_json!(
      src["portal"].value(),
    )
    let portals = MapPortals::new(portal_res._, map_id, map_portals_animations)
    let mini_map_resources = MiniMapResource::load!(src, portal_res._)
    (
      tiles_objs_f, backgrounds_f, physics, map_info, portals, mini_map_resources,
    )
  })
  .bind(fn(res) {
    match res {
      Ok(
        (
          tiles_objs_f,
          backgrounds_f,
          physics,
          map_info,
          portals,
          mini_map_resources,
        )
      ) =>
        tiles_objs_f
        .combine(backgrounds_f)
        .map(fn(it) {
          let (tiles_objs_res, backgrounds) = it
          tiles_objs_res.map(fn(it) {
            (it, backgrounds, physics, map_info, portals, mini_map_resources)
          })
        })
      Err(err) => @utils.Future::from_value(Err(err))
    }
  })
  .map_exn(fn(res) {
    let (tiles_objs, backgrounds, physics, map_info, portals, mini_map_resources
    ) = res.unwrap_or_error!()
    {
      id: map_id,
      tiles_objs,
      backgrounds,
      physics,
      map_info,
      portals,
      mini_map_resources,
    }
  })
}
