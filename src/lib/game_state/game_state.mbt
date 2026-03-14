///|
pub(all) struct GameState {
  mut phase : GamePhase
}

///|
pub(all) enum GamePhase {
  SelectCharacter
  ExplorerCharacterCreation
  GameStart(
    map_id~ : Int,
    portal_id~ : Int,
    set_field_message~ : @server_proto.SetFieldMessage
  )
  GameTransiting(
    map_id~ : Int,
    portal_id~ : Int,
    mut loading_map~ : @utils.Future[Result[@map.SceneMap, Error]]?
  )
  GameActive(map_id~ : Int, portal_id~ : Int)
}

///|
pub let game_state : GameState = { phase: GamePhase::SelectCharacter }
