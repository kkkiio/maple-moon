// app/src/main/cpp/src/IO/UIState.h

trait UIState {
  draw(Self, Double, Point[Int]) -> Unit
  update(Self) -> Unit
  doubleclick(Self, Point[Int]) -> Unit
  // rightclick(Self, Point[Int]) -> Unit
  send_key(Self, @KeyType.Id, Int, Bool, Bool) -> Unit
  send_cursor(Self, CursorState, Point[Int]) -> CursorState
  // send_scroll(Self, Double) -> Unit
  send_close(Self) -> Unit
  // drag_icon(Self, Icon) -> Unit
  clear_tooltip(Self, TooltipParent) -> Unit
  // show_equip(Self, TooltipParent, Int) -> Unit
  // show_item(Self, TooltipParent, Int) -> Unit
  // show_skill(Self, TooltipParent, Int, Int, Int, Int64) -> Unit
  // show_map(Self, TooltipParent, String, String, Int, Bool) -> Unit
  set_element(Self, Bool, UIElement) -> Unit
  set_or_toggle_element(Self, UIElementType, Bool, () -> UIElement) -> Unit
  remove(Self, UIElementType) -> Unit
  get(Self, UIElementType) -> UIElement?
  get_front_by_types(Self, Array[UIElementType]) -> UIElement?
  get_front_by_pos(Self, Point[Int]) -> UIElement?
}

struct UIStateNull {} derive(Default)

fn draw(self : UIStateNull, a : Double, b : Point[Int]) -> Unit {

}

fn update(self : UIStateNull) -> Unit {

}

fn doubleclick(self : UIStateNull, a : Point[Int]) -> Unit {

}

fn rightclick(self : UIStateNull, a : Point[Int]) -> Unit {

}

fn send_key(
  self : UIStateNull,
  a : @KeyType.Id,
  b : Int,
  c : Bool,
  d : Bool
) -> Unit {

}

fn send_cursor(
  self : UIStateNull,
  a : CursorState,
  b : Point[Int]
) -> CursorState {
  CursorState::IDLE
}

fn send_scroll(self : UIStateNull, a : Double) -> Unit {

}

fn send_close(self : UIStateNull) -> Unit {

}

fn drag_icon(self : UIStateNull, a : Icon) -> Unit {

}

fn clear_tooltip(self : UIStateNull, a : TooltipParent) -> Unit {

}

fn show_equip(self : UIStateNull, a : TooltipParent, b : Int) -> Unit {

}

fn show_item(self : UIStateNull, a : TooltipParent, b : Int) -> Unit {

}

fn show_skill(
  self : UIStateNull,
  a : TooltipParent,
  b : Int,
  c : Int,
  d : Int,
  e : Int64
) -> Unit {

}

fn show_map(
  self : UIStateNull,
  a : TooltipParent,
  b : String,
  c : String,
  d : Int,
  e : Bool
) -> Unit {

}

fn set_element(self : UIStateNull, c : Bool, d : UIElement) -> Unit {

}

fn set_or_toggle_element(
  self : UIStateNull,
  t : UIElementType,
  c : Bool,
  d : () -> UIElement
) -> Unit {

}

fn remove(self : UIStateNull, a : UIElementType) -> Unit {

}

fn get(self : UIStateNull, a : UIElementType) -> UIElement? {
  None
}

fn get_front_by_types(
  self : UIStateNull,
  a : Array[UIElementType]
) -> UIElement? {
  None
}

fn get_front_by_pos(self : UIStateNull, a : Point[Int]) -> UIElement? {
  None
}
