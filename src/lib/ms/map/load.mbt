///|
pub(all) struct SceneMap {
  id : Int
  tiles_objs : MapTilesObjs
  backgrounds : Backgrounds
  physics : @physics.Physics
  map_info : MapInfo
  portals : MapPortals
  mini_map_resources : MiniMapRuntimeResource?
}

///|
fn get_mapx_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("mapx")
}

///|
pub fn load_map(
  map_id : Int,
  map_portals_animations : MapPortalAnimations
) -> @utils.Future[Result[SceneMap, Error]] {
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
    let res : MapTilesObjsNxResource = @json.from_json!(src.value())
    let res = res.unwrap()
    let tiles_objs_f = MapTilesObjs::load(res.layers)
    let backgrounds_f = load_backgrounds(background_loader, res.back)
    let physics = @physics.Physics::from_resource!(src["foothold"])
    let map_info = MapInfo::from_resource(
      src,
      physics.get_fht().get_walls(),
      physics.get_fht().get_borders(),
    )
    let portals = MapPortals::new(res.portal, map_id, map_portals_animations)
    // Check if miniMap exists
    let mini_map_node = src["miniMap"]
    let mini_map_resources = if mini_map_node.is_null() {
      None
    } else {
      Some(
        MiniMapRuntimeResource::load(
          @json.from_json!(mini_map_node.value()),
          res.portal,
          src.name(),
          src.get_image_loader(),
        ),
      )
    }
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
