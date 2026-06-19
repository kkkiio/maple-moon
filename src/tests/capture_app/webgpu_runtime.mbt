///|
let webgpu_capture_runtime_started : Ref[Bool] = Ref(false)

///|
/// Start the WebGPU window runtime used by browser snapshot captures.
///
/// Selene's graphics capture plugin renders through the platform render
/// backend but does not initialize the browser canvas runtime itself. Calling
/// this before a capture lets tests preload backend resources before the strict
/// capture frame is reached.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.ensure_webgpu_capture_runtime(800.0, 600.0)
/// @asset.wait_render_ready()
/// ```
pub fn ensure_webgpu_capture_runtime(
  width : Double,
  height : Double,
  image_smooth? : Bool = false,
) -> Unit {
  if webgpu_capture_runtime_started.val {
    return
  }
  let stop = @platform_window.initialize(
    {
      viewport_width: width,
      viewport_height: height,
      screen_width: width,
      screen_height: height,
      fps: 60,
      image_smooth,
    },
    {
      startup: fn() {  },
      service_frame: fn() {  },
      render_loop: fn(_delta) {  },
      game_loop: fn(_delta) {  },
    },
  )
  ignore(stop)
  webgpu_capture_runtime_started.val = true
}
