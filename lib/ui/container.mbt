pub trait Container {
  /// Adds a UI element to the container.
  add_ui(Self, UIElementType, UIElement, Bool) -> Unit
}
