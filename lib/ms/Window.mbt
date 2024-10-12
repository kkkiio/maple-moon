struct Window {
  opacity : Double
  mut last_click : TimePoint
}

let g_window : @utils.Singleton[Window] = @utils.Singleton::new()

fn Window::new() -> Window {
  { opacity: 1.0, last_click: TimePoint::default() }
}

pub fn Window::get() -> Window {
  g_window.must_get()
}

fn begin(self : Window) -> Unit {
  @graphics.GraphicsGL::get().clear_scene()
}

fn end(self : Window) -> Unit {
  @graphics.GraphicsGL::get().flush(self.opacity)
}

pub fn onmousemove(self : Window, x : Int, y : Int) -> Unit {
  UI::get().send_cursor_pos({ x, y })
}

pub fn onmouseup(self : Window) -> Unit {
  UI::get().send_cursor_pressed(false)
}

pub fn onmousedown(self : Window) -> Unit {
  let now = TimePoint::from_micro(now_micro())
  let diff_ms = now.since(self.last_click).to_milliseconds()
  self.last_click = now
  if diff_ms > 10 && diff_ms < 200 {
    UI::get().doubleclick()
  }
  UI::get().send_cursor_pressed(true)
}

// fn fadeout(self : Window, step : Double, fadeproc : () -> Unit) -> Unit {
//   fadeproc()
// }
pub fn key_callback(self : Window, keyCode : String, pressed : Bool) -> Unit {
  UI::get().send_key(keyCode, pressed)
}
