struct Window {
  opacity : Double
}

let window : Window = Window::new()

fn Window::new() -> Window {
  { opacity: 1.0 }
}

pub fn Window::get() -> Window {
  window
}

fn begin(self : Window) -> Unit {
  GraphicsGL::get().clear_scene()
}

fn end(self : Window) -> Unit {
  GraphicsGL::get().flush(self.opacity)
}

pub fn onmousemove(self : Window, x : Int, y : Int) -> Unit {
  g_ui.send_cursor_pos({ x, y })
}

pub fn onmouseup(self : Window) -> Unit {
  g_ui.send_cursor_pressed(false)
}

pub fn onmousedown(self : Window) -> Unit {
  g_ui.send_cursor_pressed(true)
}

// fn fadeout(self : Window, step : Double, fadeproc : () -> Unit) -> Unit {
//   fadeproc()
// }
pub fn key_callback(self : Window, keyCode : Int, pressed : Bool) -> Unit {
  UI::get().send_key(keyCode, pressed)
}
