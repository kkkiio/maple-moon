pub trait Container {
  /// Adds a UI element to the container.
  add_ui(Self, Element, Bool) -> Unit
}
