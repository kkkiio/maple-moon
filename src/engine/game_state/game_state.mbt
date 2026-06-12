///|
pub(all) enum GamePhase {
  GameSetup
  SelectCharacter
  GameStart(
    map_id~ : Int,
    portal_id~ : Int,
    set_field_message~ : @server_proto.SetFieldMessage
  )
  GameTransiting(map_id~ : Int, portal_id~ : Int)
  GameActive(map_id~ : Int, portal_id~ : Int)
}

///|
let app_state_ref : Ref[@state.State[GamePhase]?] = Ref(None)

///|
fn require_state() -> @state.State[GamePhase] {
  match app_state_ref.val {
    Some(state) => state
    None => abort("game_state not initialized, call init_state first")
  }
}

///|
pub fn init_state(initial : GamePhase) -> Unit {
  app_state_ref.val = Some(@state.State(initial))
}

///|
pub fn current_phase() -> GamePhase {
  require_state().get()
}

///|
pub fn previous_phase() -> GamePhase? {
  require_state().previous.val
}

///|
pub fn set_next_phase(phase : GamePhase) -> Unit {
  require_state().next().set(phase)
}

///|
pub fn in_phase(predicate : (GamePhase) -> Bool) -> (@ecs.World) -> Bool {
  let cond = @state.in_state(require_state(), predicate)
  fn(_world) { cond() }
}

///|
pub fn on_enter_phase(predicate : (GamePhase) -> Bool) -> () -> Bool {
  @state.on_enter(require_state(), predicate)
}

///|
pub fn on_exit_phase(predicate : (GamePhase) -> Bool) -> () -> Bool {
  @state.on_exit(require_state(), predicate)
}

///|
pub fn transition(
  from~ : (GamePhase) -> Bool,
  to~ : (GamePhase) -> Bool,
) -> () -> Bool {
  fn() {
    let state = require_state()
    if !@state.transitioned_this_frame(state) {
      return false
    }
    guard state.previous.val is Some(previous) else { return false }
    from(previous) && to(state.get())
  }
}

///|
fn current_phase_name() -> String {
  match current_phase() {
    GamePhase::GameSetup => "GameSetup"
    GamePhase::SelectCharacter => "SelectCharacter"
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
