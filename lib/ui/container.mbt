///|
pub(open) trait Container {
  /// Adds a UI element to the container.
  add_ui(Self, Element, Bool) -> Unit
  /// Removes a UI element from the container by its key.
  remove_ui(Self, UIElementType) -> Unit
}
