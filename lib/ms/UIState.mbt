trait UIState {
  draw(Self, Double, Point[Int]) -> Unit
  update(Self) -> Unit
  send_key(Self, @KeyType.Id, Int, Bool, Bool) -> Unit
  send_cursor(Self, CursorState, Point[Int]) -> CursorState
  doubleclick(Self, Point[Int]) -> Unit
  set_element(Self, Bool, @ui.Element) -> Unit
  get(Self, UIElementType) -> UIElement?
  get_front_by_types(Self, Array[UIElementType]) -> UIElement?
}
