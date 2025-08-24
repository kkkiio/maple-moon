///| Logic frame time in milliseconds.
pub let step_time_ms = 8

///|
pub(all) struct Constants {
  mut view_width : Int
  mut view_height : Int
}

///|
pub let constants : Constants = { view_width: 1366, view_height: 768 } // Fixed to 1366x768 for now

///|
pub fn get_viewwidth(self : Constants) -> Int {
  self.view_width
}

///|
pub fn get_viewheight(self : Constants) -> Int {
  self.view_height
}

///|
pub fn set_viewwidth(self : Constants, value : Int) -> Unit {
  self.view_width = value
}

///|
pub fn set_viewheight(self : Constants, value : Int) -> Unit {
  self.view_height = value
}
