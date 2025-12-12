///|
pub(all) struct SceneMap {
  id : Int
  tiles_objs : MapLayers
  backgrounds : Backgrounds
  physics : @physics.Physics
  map_info : MapInfo
  portals : MapPortals
  mini_map_resources : MiniMapRuntimeResource?
}

///|
/// Creates a new scene map from the given raw map resources.
pub fn create_scene_map(
  raw : MapRawResources,
  map_portals_animations : MapPortalAnimations,
) -> SceneMap raise {
  // TODO: CashShopPreview
  let layers = raw.nx_map.layers
  let tiles_objs = MapLayers::new(
    raw.tilesets,
    raw.object_animation_sets,
    layers,
  )
  let backgrounds = load_backgrounds(
    raw.nx_map.back,
    raw.background_animation_sets,
  )
  let physics = @physics.Physics::from_resource(raw.nx_map.foothold)
  let map_info = MapInfo::from_resource(
    raw.root,
    physics.get_fht().get_walls(),
    physics.get_fht().get_borders(),
  )
  let portals = MapPortals::new(
    raw.get_portals(),
    raw.id,
    map_portals_animations,
  )
  // Check if miniMap exists
  let mini_map_resources = raw.nx_map.mini_map.map(fn(it) {
    MiniMapRuntimeResource::load(it, raw.get_portals())
  })
  {
    id: raw.id,
    tiles_objs,
    backgrounds,
    physics,
    map_info,
    portals,
    mini_map_resources,
  }
}
