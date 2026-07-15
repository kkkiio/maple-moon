///|
using @struct {type Point}

///|
/// Lightweight window state shared by selene-based UI modules that still need
/// mutable position and size bookkeeping.
pub(all) struct UIModel {
  mut position : Point[Int]
  mut dimension : Point[Int]
  mut active : Bool
}

///|
pub fn UIModel::UIModel(
  position : Point[Int],
  dimension : Point[Int],
  active? : Bool = true,
) -> UIModel {
  { position, dimension, active }
}

///|
pub fn UIModel::makeactive(self : UIModel) -> Unit {
  self.active = true
}

///|
pub fn UIModel::deactivate(self : UIModel) -> Unit {
  self.active = false
}

///|
pub fn UIModel::is_active(self : UIModel) -> Bool {
  self.active
}

///|
pub fn UIModel::toggle_active(self : UIModel) -> Unit {
  if self.active {
    self.deactivate()
  } else {
    self.makeactive()
  }
}
