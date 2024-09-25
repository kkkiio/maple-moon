trait UIState {
  draw(Self, Double, Point[Int]) -> Unit
  update(Self) -> Unit
  send_key(Self, @KeyType.Id, Int, Bool, Bool) -> Unit
  send_cursor(Self, CursorState, Point[Int]) -> CursorState
  // drag_icon(Self, Icon) -> Unit
  set_element(Self, Bool, UIElement) -> Unit
  toggle_element(Self, UIElementType, Bool, () -> UIElement) -> Unit
  remove(Self, UIElementType) -> Unit
  get(Self, UIElementType) -> UIElement?
  get_front_by_types(Self, Array[UIElementType]) -> UIElement?
  get_front_by_pos(Self, Point[Int]) -> UIElement?
}
