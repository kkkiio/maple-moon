///|
pub(all) struct GameState {
  mut phase : GamePhase
}

///|
pub(all) enum GamePhase {
  Login
  GameStart(map_id~ : Int, portal_id~ : Int)
  GameTransiting(
    map_id~ : Int,
    portal_id~ : Int,
    mut loading_map~ : @utils.Future[Result[@map.SceneMap, Error]]?
  )
  GameActive(
    map_id~ : Int,
    portal_id~ : Int,
    tiles_objs~ : @map.MapLayers,
    backgrounds~ : @map.Backgrounds,
    physics~ : @physics.Physics,
    map_info~ : @map.MapInfo,
    portals~ : @map.MapPortals,
    mobs~ : @monster.MapMobs
  )
}

///|
pub let game_state : GameState = { phase: GamePhase::Login }
