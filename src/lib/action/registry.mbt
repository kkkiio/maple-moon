///|
struct Registry {
  mut entries : @immut/hashmap.T[@keyboard.BasicActionId, Descriptor]
}

///|
pub(all) enum Descriptor {
  UI(
    key~ : @ui.UIElementType,
    make_element~ : () -> @ui.Element,
    focused~ : Bool
  )
}

///|
pub fn Registry::new() -> Registry {
  { entries: @immut/hashmap.new() }
}

///|
pub fn get_action(self : Registry, id : @keyboard.BasicActionId) -> Descriptor? {
  self.entries.find(id)
}

///|
pub fn reset_actions(
  self : Registry,
  entries : @immut/hashmap.T[@keyboard.BasicActionId, Descriptor]
) -> Unit {
  self.entries = entries
}
