struct Window {
  opacity : Double
  ui : UI
}

fn Window::new(ui : UI) -> Window {
  { opacity: 1.0, ui }
}

fn begin(self : Window, g : GraphicsGL) -> Unit {
  g.clear_scene()
}

fn end(self : Window, g : GraphicsGL) -> Unit {
  g.flush(self.opacity)
  // glfmSwapBuffers(display)
}

pub fn onmousemove(self : Window, x : Int, y : Int) -> Unit {
  self.ui.send_cursor_pos({ x, y })
}
