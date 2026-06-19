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
/// Capture one WebGPU frame after a strict number of rendered frames.
///
/// The function initializes the browser WebGPU runtime, waits for already
/// preloaded render assets to become ready, attaches Selene's graphics capture
/// plugin, starts the app loop, and waits until the requested artifact is
/// produced. The frame count is strict and is not a warmup duration.
///
/// # Example
/// ```moonbit nocheck
/// let artifact = @capture_app.capture_after_frames(
///   app, 12, width=800, height=540, raw_delta=0.016,
/// )
/// @capture_app.snapshot("src/tests/example/__snapshot__/frame.png", artifact.png)
/// ```
pub async fn capture_after_frames(
  app : @app.App,
  frames : Int,
  width~ : Int,
  height~ : Int,
  raw_delta? : Double = 0.016,
  image_smooth? : Bool = false,
) -> @runtime_debug.FrameCaptureArtifact {
  if frames <= 0 {
    fail("capture_after_frames requires frames > 0")
  }
  if width <= 0 || height <= 0 {
    fail("capture_after_frames requires positive width and height")
  }
  ensure_webgpu_capture_runtime(
    width.to_double(),
    height.to_double(),
    image_smooth~,
  )
  @asset.wait_render_ready()
  let capture = @test_graphics.OffscreenCapture::new(
    width~,
    height~,
    raw_delta~,
    frames=[frames - 1],
  )
  let app = app.add_plugin(@test_graphics.capture_plugin(capture))
  app.run()
  capture.wait_artifact()
}
