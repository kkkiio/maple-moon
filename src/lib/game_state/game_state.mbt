///|
pub(all) struct GameState {
  mut phase : GamePhase
}

///|
pub(all) enum GamePhase {
  SelectCharacter
  GameStart(
    map_id~ : Int,
    portal_id~ : Int,
    mut loading_data~ : @utils.Future[
      Result[(@item.ItemData, @char_look.Hair, @char_look.Face), Error],
    ]?
  )
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
pub let game_state : GameState = { phase: GamePhase::SelectCharacter }
