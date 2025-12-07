///|
// fn spawn_background_ffi(f : () -> Unit) -> Unit = "async" "spawn_background"
extern "js" fn spawn_background_ffi(f : () -> Unit) -> Unit =
  #| (f) => setTimeout(f, 0)

///|
fn spawn_background(f : async () -> Unit noraise) -> Unit {
  spawn_background_ffi(fn() { @js.async_run(f) })
}
