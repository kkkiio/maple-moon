///|
fn spawn_background_ffi(f : () -> Unit) -> Unit = "async" "spawn_background"

///|
fn spawn_background(f : async () -> Unit) -> Unit {
  spawn_background_ffi(fn() { @js.async_run(f) })
}
