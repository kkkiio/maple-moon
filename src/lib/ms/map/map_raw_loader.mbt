///|
pub(all) struct MapRawResources {
  id : Int
  nx_map : NxMap
  tilesets : Map[String, NxTileSet]
  object_animation_sets : Map[
    String,
    Map[ObjectAnimationPath, @resource.NxAnimation],
  ]
  background_animation_sets : Map[
    String,
    Map[BackgroundAnimationPath, @resource.NxAnimation],
  ]
  foothold : @physics.NxFootholdTree
  root : @resource.NxNode
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
      // "https://maple-res.kkkiiox.work/Map/Map1",
      "/assets/map/map1",
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
pub async fn load_map_raw(map_id : Int) -> MapRawResources {
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  @log.info({ "path": path }, "loading raw map resource")
  let src = get_mapx_loader().load_res_async(path)
  guard not(src.is_null()) else {
    raise @resource.LoadError("map not found, id=\{map_id}")
  }
  let nx_map : NxMap = @json.from_json(src.value())
  let tilesets = {}
  for layer in nx_map.layers {
    if layer.info is Some({ tS }) {
      tilesets[tS] = load_tileset(tS)
    }
  }
  let object_animation_sets = {}
  for layer in nx_map.layers {
    for obj in layer.obj {
      let path = ObjectAnimationPath::from_obj(obj)
      let sets = object_animation_sets.get_or_init(obj.oS, fn() { Map::new() })
      sets[path] = load_obj_animation(obj.oS, path)
    }
  }
  let bs_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
    "background_set_loader",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Back",
      "/assets/map/back",
    ),
    base_url="/assets",
    image_base_url="/",
  )
  let background_animation_sets = {}
  for background in nx_map.back.0 {
    let sets = background_animation_sets.get_or_init(background.bS, fn() {
      Map::new()
    })
    let path = BackgroundAnimationPath::from_nx(background)
    sets[path] = load_background_animation(bs_loader, background.bS, path)
  }
  let foothold = @json.from_json(src["foothold"].value())
  {
    id: map_id,
    nx_map,
    tilesets,
    object_animation_sets,
    background_animation_sets,
    foothold,
    root: src,
  }
}

///|
pub fn MapRawResources::get_layers(self : MapRawResources) -> Array[NxLayer] {
  self.nx_map.layers
}

///|
pub fn MapRawResources::get_backgrounds(
  self : MapRawResources,
) -> BackgroundsResource {
  self.nx_map.back
}

///|
pub fn MapRawResources::get_portals(
  self : MapRawResources,
) -> Array[PortalMarker] {
  self.nx_map.portal
}
