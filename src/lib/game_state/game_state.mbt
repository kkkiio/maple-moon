///|
pub(all) struct GameState {
  mut phase : GamePhase
}

///|
pub(all) enum GamePhase {
  GameSetup(mut loading~ : @utils.Future[Result[Unit, Error]]?)
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
pub let game_state : GameState = { phase: GamePhase::GameSetup(loading=None) }

///|
fn current_phase_name() -> String {
  match game_state.phase {
    GamePhase::GameSetup(..) => "GameSetup"
    GamePhase::SelectCharacter => "SelectCharacter"
    GamePhase::ExplorerCharacterCreation => "ExplorerCharacterCreation"
    GamePhase::GameStart(..) => "GameStart"
    GamePhase::GameTransiting(..) => "GameTransiting"
    GamePhase::GameActive(..) => "GameActive"
  }
}

///|
fn init {
  @console.register_state_section("phase", fn() {
    current_phase_name().to_json()
  })
}
