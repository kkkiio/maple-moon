///|
/// Reset mock server state recorded by capture tests.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.reset_mock_server()
/// ```
pub fn reset_mock_server() -> Unit {
  reset_mock_server_state()
}

///|
/// Emit a mock server message into the test-side game server bridge.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.emit_mock_server_message(message)
/// ```
pub fn[T : @server_proto.ServerMessage] emit_mock_server_message(
  message : T,
) -> Unit raise {
  emit_mock_server_state(T::type_code(), message.to_json())
}

///|
/// Return how many client messages with `type_code` the mock server received.
///
/// # Example
/// ```moonbit nocheck
/// let count = @capture_app.mock_server_sent_count(type_code)
/// ```
pub fn mock_server_sent_count(type_code : Int) -> Int {
  mock_server_sent_count_internal(type_code)
}

///|
/// Return the latest client message JSON recorded by the mock server.
///
/// # Example
/// ```moonbit nocheck
/// let latest = @capture_app.mock_server_latest_sent_json(type_code)
/// ```
pub fn mock_server_latest_sent_json(type_code : Int) -> Json? {
  mock_server_latest_sent_json_internal(type_code)
}

///|
let raylib_capture_window_open : Ref[Bool] = { val: false }

///|
/// Ensure the native raylib backend has a hidden window and OpenGL context.
///
/// Tests that load raylib textures before calling `capture_after_frames` should
/// call this once before resource setup. Repeated calls reuse the process-local
/// hidden window.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.ensure_native_context(width=420, height=240)
/// ```
pub fn ensure_native_context(width~ : Int, height~ : Int) -> Unit raise {
  if width <= 0 || height <= 0 {
    fail("ensure_native_context requires positive width and height")
  }
  if !raylib_capture_window_open.val {
    @raylib.set_config_flags(@raylib.FlagWindowHidden)
    @raylib.init_window(width, height, "maple moon graphics snapshot")
    raylib_capture_window_open.val = true
  }
}

///|
/// Create a fresh World and App for graphics snapshot tests.
/// Each call gets an isolated world, preventing cross-test state pollution.
///
/// # Example
/// ```moonbit nocheck
/// let (app, world) = @capture_app.new_graphics_test_app()
/// ```
pub fn new_graphics_test_app() -> (@app.App, @ecs.World) {
  let world = @ecs.World()
  @ecs.set_current_world(world)
  (@app.App().with_world(world), world)
}

///|
/// Capture one native raylib frame after a strict number of rendered frames.
///
/// The function creates one hidden raylib window to provide an OpenGL context,
/// runs the supplied app for exactly `frames`, and captures only the final
/// requested frame. The frame count is strict and is not a warmup duration.
///
/// # Example
/// ```moonbit nocheck
/// let artifact = @capture_app.capture_after_frames(
///   app, 12, width=800, height=540, raw_delta=0.016,
/// )
/// @capture_app.snapshot("src/graphics_test/__snapshot__/example/frame.png", artifact.png)
/// ```
pub fn capture_after_frames(
  app : @app.App,
  frames : Int,
  width~ : Int,
  height~ : Int,
  raw_delta? : Double = 0.016,
  image_smooth? : Bool = false,
) -> @runtime_debug.FrameCaptureArtifact raise {
  if frames <= 0 {
    fail("capture_after_frames requires frames > 0")
  }
  if width <= 0 || height <= 0 {
    fail("capture_after_frames requires positive width and height")
  }
  ensure_native_context(width~, height~)
  let captures = app
    .with_image_smooth(image_smooth)
    .run_frames_capture(
      frames,
      capture_width=width,
      capture_height=height,
      raw_delta~,
      capture_frame_indexes=Some([frames - 1]),
    )
  if captures.length() != 1 {
    fail(
      "capture_after_frames expected exactly one capture, got \{captures.length()}",
    )
  }
  captures[0]
}
