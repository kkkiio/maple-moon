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
let mapx_loader : Ref[@resource.AsyncLoader?] = Ref::new(None)

///|
fn get_mapx_loader() -> @resource.AsyncLoader {
  if mapx_loader.val is Some(loader) {
    return loader
  }
  let loader = @resource.CompositeAsyncResourceLoader::new({
    "Map0/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map0",
    ),
    "Map1/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map1",
    ),
    "Map2/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map2",
    ),
    "Map3/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map3",
    ),
    "Map4/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map4",
    ),
    "Map5/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map5",
    ),
    "Map6/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map6",
    ),
    "Map7/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map7",
    ),
    "Map8/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map8",
    ),
    "Map9/": @resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Map9",
    ),
  })
  let loader = @resource.AsyncLoader::new("mapx", loader~)
  mapx_loader.val = Some(loader)
  loader
}

///|
pub async fn load_map(
  map_id : Int,
  map_portals_animations : MapPortalAnimations,
) -> SceneMap raise {
  // TODO: CashShopPreview
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  @log.info({ "path": path }, "loading map")
  let src = get_mapx_loader().load_res_async(path)
  guard not(src.is_null()) else {
    raise @resource.LoadError("map not found, id=\{map_id}")
  }
  let res : MapTilesObjsNxResource = @json.from_json(src.value())
  let res = res.unwrap()
  let tiles_objs = MapTilesObjs::load(res.layers)
  let background_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
    "background",
    loader=@resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Back",
    ),
  )
  let backgrounds = load_backgrounds(background_loader, res.back)
  let foothold_tree = @json.from_json(src["foothold"].value())
  let physics = @physics.Physics::from_resource(foothold_tree)
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
        @json.from_json(mini_map_node.value()),
        res.portal,
      ),
    )
  }
  {
    id: map_id,
    tiles_objs,
    backgrounds,
    physics,
    map_info,
    portals,
    mini_map_resources,
  }
}
