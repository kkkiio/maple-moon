// Logic frame time in milliseconds.
pub let step_time_ms = 8

pub(all) struct Constants {
  mut viewWidth : Int
  mut viewHeight : Int
}

pub let constants : Constants = { viewWidth: 1366, viewHeight: 768 }

pub fn get_viewwidth(self : Constants) -> Int {
  self.viewWidth
}

pub fn get_viewheight(self : Constants) -> Int {
  self.viewHeight
}

pub fn set_viewwidth(self : Constants, value : Int) -> Unit {
  self.viewWidth = value
}

pub fn set_viewheight(self : Constants, value : Int) -> Unit {
  self.viewHeight = value
}
