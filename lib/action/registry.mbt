struct Registry {
  entries : Map[Id, Descriptor]
}

pub enum Descriptor {
  UI(
    ~key : @ui.UIElementType,
    ~make_element : () -> @ui.Element,
    ~focused : Bool
  )
}

pub fn Registry::new() -> Registry {
  { entries: Map::new() }
}

pub fn register(self : Registry, id : Id, descriptor : Descriptor) -> Unit {
  self.entries.set(id, descriptor)
}

pub fn get_action(self : Registry, id : Id) -> Descriptor? {
  self.entries.get(id)
}
