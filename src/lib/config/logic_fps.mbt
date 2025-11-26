///|
/// Logic frame time in milliseconds.
pub let step_time_ms = 8

///|
priv struct LogicFPSState {
  mut delta : Double
  mut current_times : Int
}

///|
let state : LogicFPSState = { delta: 0.0, current_times: 0 }

///|
pub fn logic_fps_system(delta : Double) -> Unit {
  state.delta += delta
  let times = (state.delta * 1000 / step_time_ms.to_double()).to_int()
  state.delta -= (step_time_ms * times).to_double() / 1000.0
  state.current_times = times
}

///|
/// Get the number of logic times to update.
pub fn get_logic_times() -> Int {
  state.current_times
}

///|
/// Get the delta time for the logic update.
pub fn get_logic_time_delta() -> Double {
  state.delta
}
