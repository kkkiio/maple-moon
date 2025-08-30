///|
struct Window {
  ui : UI
}

///|
fn Window::new(ui : UI) -> Window {
  { ui, }
}

// ///|
// pub fn onmousedown(self : Window) -> Unit {
//   let now = (self.get_now)()
//   let diff_ms = now.since(self.last_click).to_milliseconds()
//   self.last_click = now
//   self.ui.send_cursor_pressed(true)
//   if diff_ms > 10 && diff_ms < 200 {
//     self.ui.doubleclick()
//   }
// }

///|
pub fn key_callback(self : Window, keyCode : String, pressed : Bool) -> Unit {
  self.ui.send_key(keyCode, pressed)
}
