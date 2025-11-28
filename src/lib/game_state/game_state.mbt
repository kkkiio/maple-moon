///|
pub(all) struct GameState {
  mut state : GameStateType
}

///|
pub(all) enum GameStateType {
  Login
  Game(
    map_id~ : Int,
    portal_id~ : Int,
    char_look~ : @char_look.CharLook,
    server~ : @net.Server
  )
}

///|
pub let game_state : GameState = { state: GameStateType::Login }
