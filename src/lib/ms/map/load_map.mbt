///|
pub(all) struct SceneMap {
  id : Int
  tiled_map : @tiled.TiledMap
  background_animations : Map[String, @resource.SeleneClip]
  life_spawns : Array[NxLife]
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
  let tiled_map = raw.tiled_map
  let life_spawns = from_tiled_life_spawns(tiled_map)
  let physics = @physics.Physics::from_resource(
    from_tiled_foothold_tree(tiled_map),
  )
  let map_info = MapInfo::from_tiled_map(
    tiled_map,
    physics.get_fht().get_walls(),
    physics.get_fht().get_borders(),
  )
  let portals = MapPortals::from_tiled_map(
    tiled_map,
    raw.id,
    map_portals_animations,
  )
  let mini_map_resources = from_tiled_mini_map_resource(tiled_map).map(fn(
    mini,
  ) {
    MiniMapRuntimeResource::from_tiled(mini, portals)
  })
  {
    id: raw.id,
    tiled_map,
    background_animations: raw.background_animations,
    life_spawns,
    physics,
    map_info,
    portals,
    mini_map_resources,
  }
}
