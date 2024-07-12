struct UIStateLogin {
  ui_element : UIElement
}

fn UIStateLogin::new(ui_element : UIElement) -> UIStateLogin {
  { ui_element, }
}

// fn draw(self, inter: Double, cursor: Point[Int16]) -> Unit {
//   // Drawing logic here
// }

// fn update(self) -> Unit {
//   // Update logic here
// }

// fn doubleclick(self, pos: Point[Int16]) -> Unit {
//   // Double click logic here
// }

// fn rightclick(self, pos: Point[Int16]) -> Unit {
//   // Right click logic here
// }

// fn send_key(self, type: KeyType::Id, action: Int32, pressed: Bool, escape: Bool) -> Unit {
//   // Key send logic here
// }

fn send_cursor(
  self : UIStateLogin,
  mst : CursorState,
  pos : Point[Int]
) -> CursorState {
  // self.ui_element.send_cursor(clicked, cursorpos)
  CursorState::IDLE
}

// fn send_scroll(self, yoffset: Double) -> Unit {
//   // Scroll send logic here
// }

// fn send_close(self) -> Unit {
//   // Close send logic here
// }

// fn drag_icon(self, icon: Icon) -> Unit {
//   // Drag icon logic here
// }

// fn clear_tooltip(self, parent: TooltipParent) -> Unit {
//   // Clear tooltip logic here
// }

// fn show_equip(self, parent: TooltipParent, slot: Int16) -> Unit {
//   // Show equip logic here
// }

// fn show_item(self, parent: TooltipParent, itemid: Int32) -> Unit {
//   // Show item logic here
// }

// fn show_skill(self, parent: TooltipParent, skill_id: Int32, level: Int32, masterlevel: Int32, expiration: Int64) -> Unit {
//   // Show skill logic here
// }

// fn show_text(self, parent: TooltipParent, text: String) -> Unit {
//   // Show text logic here
// }

// fn show_map(self, parent: TooltipParent, name: String, description: String, mapid: Int32, bolded: Bool) -> Unit {
//   // Show map logic here
// }

// fn pre_add(self, type: UIElementType, toggled: Bool, focused: Bool) -> @iter.Iter[(UIElementType, UIElement)] {
//   // Pre add logic here
//   @iter.empty()
// }

// fn remove(self, type: UIElementType) -> Unit {
//   // Remove logic here
// }

// fn get(self, type: UIElementType) -> UIElement? {
//   // Get element logic here
//   None
// }

// fn get_front_by_types(self, types: Array[UIElementType]) -> UIElement? {
//   // Get front element by types logic here
//   None
// }

// fn get_front_by_pos(self, pos: Point[Int16]) -> UIElement? {
//   // Get front element by position logic here
//   None
// }
// }

// impl UIElement for UIStateLogin {
// fn draw(self, alpha: Double) -> Unit {
//   // Draw logic here
// }

// fn update(self) -> Unit {
//   // Update logic here
// }

// impl UIStateLogin {
// fn login(self) -> Unit {
//   // Login logic here
// }

// fn open_url(self, id: UInt16) -> Unit {
//   // Open URL logic here
// }

// fn button_pressed(self, id: UInt16) -> ButtonState {
//   // Button pressed logic here
//   ButtonState::NORMAL
// }

// fn get_type(self) -> UIElementType {
//   // Get type logic here
//   UIElementType::UI_ELEMENT_NONE
// }
