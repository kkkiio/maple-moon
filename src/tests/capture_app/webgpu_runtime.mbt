///|
let webgpu_capture_runtime_started : Ref[Bool] = Ref(false)

///|
/// Start the WebGPU window runtime used by browser snapshot captures.
///
/// `App::run_frames_capture` renders through the platform render backend but
/// does not initialize the browser canvas runtime itself. Calling this before a
/// capture lets the external WebGPU runner warm the runtime in its first pass
/// and compare snapshots in its second pass.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.ensure_webgpu_capture_runtime(800.0, 600.0)
/// let captures = app.run_frames_capture(1)
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
