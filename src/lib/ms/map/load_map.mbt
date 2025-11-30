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
pub async fn load_map(
  map_id : Int,
  map_portals_animations : MapPortalAnimations,
) -> SceneMap {
  let raw = load_map_raw(map_id)
  parse_scene_map(raw, map_portals_animations)
}

///|
pub fn parse_scene_map(
  raw : MapRawResources,
  map_portals_animations : MapPortalAnimations,
) -> SceneMap raise {
  // TODO: CashShopPreview
  let layers = raw.nx_map.layers
  let tiles_objs = MapTilesObjs::load(
    raw.tilesets,
    raw.object_animation_sets,
    layers,
  )
  let backgrounds = load_backgrounds(
    raw.nx_map.back,
    raw.background_animation_sets,
  )
  let physics = @physics.Physics::from_resource(raw.foothold)
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
  let mini_map_node = raw.root["miniMap"]
  let mini_map_resources = if mini_map_node.is_null() {
    None
  } else {
    Some(
      MiniMapRuntimeResource::load(
        @json.from_json(mini_map_node.value()),
        raw.get_portals(),
      ),
    )
  }
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
