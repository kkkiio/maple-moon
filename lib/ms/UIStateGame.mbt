///|
typealias ButtonState = @ui.ButtonState

///|
typealias UIElementType = @ui.UIElementType

///|
let min_delay_next_grab : @utils.Duration = 10 |> @utils.Duration::from_micro

///|
struct UIStateGame {
  ui : UI
  stage : Stage
  registry : @action.Registry
  timer : @utils.Timer
  elements : Map[UIElementType, @ui.Element]
  element_order : Array[UIElementType]
  mut focused : UIElementType
  mut dragged : @ui.Element?
  // eq_tooltip : EquipTooltip
  // it_tooltip : ItemTooltip
  // sk_tooltip : SkillTooltip
  // te_tooltip : TextTooltip
  // ma_tooltip : MapTooltip
  // mut tooltip : Option[Tooltip]
  // tooltip_parent : TooltipParent
  time_rel_grabbed : @utils.TimePoint
  mut vwidth : Int
  mut vheight : Int
}

///|
pub fn UIStateGame::new(
  ui : UI,
  stage : Stage,
  registry : @action.Registry,
  timer : @utils.Timer
) -> UIStateGame {
  {
    ui,
    stage,
    registry,
    timer,
    elements: Map::new(),
    element_order: [],
    focused: UIElementType::UI_ELEMENT_NONE,
    dragged: None,
    // eq_tooltip: @Tooltip.EquipTooltip::default(),
    // it_tooltip: @Tooltip.ItemTooltip::default(),
    // sk_tooltip: @Tooltip.SkillTooltip::default(),
    // te_tooltip: @Tooltip.TextTooltip::default(),
    // ma_tooltip: @Tooltip.MapTooltip::default(),
    // tooltip: None,
    // tooltip_parent: TooltipParent::NONE,
    time_rel_grabbed: timer.now(),
    vwidth: @constants.constants.get_viewwidth(),
    vheight: @constants.constants.get_viewheight(),
  }
  // icon_map: Map::from_array([
  //   (Icon.IconType::NONE, Widget.Type::NONE),
  //   (Icon.IconType::SKILL, Widget.Type::SKILL_BOOK),
  //   (Icon.IconType::EQUIP, Widget.Type::EQUIP_INVENTORY),
  //   (Icon.IconType::ITEM, Widget.Type::ITEM_INVENTORY),
  //   (Icon.IconType::KEY, Widget.Type::KEY_CONFIG),
  //   (Icon.IconType::NUM_TYPES, Widget.Type::NUM_TYPES),
  // ]),
}

///|
pub fn UIStateGame::draw(
  self : UIStateGame,
  inter : Double,
  cursor : @struct.Point[Int]
) -> Unit {
  self.element_order.each(fn(t) {
    match self.elements.get(t) {
      Some(element) => if element.get_ui_model().is_active() { element.draw() }
      None => ()
    }
  })

  // if (tooltip_) {
  //     tooltip_->get().draw(cursor + Point<int16_t>(0, 22));
  // }
  //TODO: draw tooltip

}

///|
pub fn UIStateGame::update(self : UIStateGame) -> Unit {
  let mut update_screen = false
  let new_width = @constants.constants.get_viewwidth()
  let new_height = @constants.constants.get_viewheight()
  if self.vwidth != new_width || self.vheight != new_height {
    update_screen = true
    self.vwidth = new_width
    self.vheight = new_height
    //TODO: adjust status bar
  }
  self.element_order.each(fn(t) {
    match self.elements.get(t) {
      Some(element) =>
        if element.get_ui_model().is_active() {
          element.update()
          if update_screen {
            //TODO: update screen
            // element.update_screen(new_width, new_height)
          }
        }
      None => ()
    }
  })
}

///|
pub fn UIStateGame::send_key(
  self : UIStateGame,
  mapping : @keyboard.Mapping?,
  pressed : Bool,
  escape : Bool
) -> Unit {
  match self.get(self.focused) {
    Some(focusedelement) => {
      if focusedelement.get_ui_model().is_active() {
        return focusedelement.object.send_key(
          mapping.map_or(0, fn(it) { it.action }),
          pressed,
          escape,
        )
      }
      self.focused = UIElementType::UI_ELEMENT_NONE
      return
    }
    None => ()
  }
  guard let Some(mapping) = mapping else { None => return }
  match mapping.t {
    @keyboard.KeyType::MENU =>
      if pressed {
        let action = @keyboard.BasicActionId::from_int(mapping.action).unwrap() // TODO: handle error
        match self.registry.get_action(action) {
          Some(descriptor) =>
            match descriptor {
              @action.Descriptor::UI(key~, make_element~, focused~) =>
                self.toggle_element(key, focused, make_element)
            }
          None => ()
        }
      }
    @keyboard.KeyType::ACTION
    | @keyboard.KeyType::FACE
    | @keyboard.KeyType::ITEM
    | @keyboard.KeyType::SKILL =>
      self.stage.send_key(mapping.t, mapping.action, pressed)
    _ => ()
  }
}

///|
pub fn UIStateGame::send_cursor(
  self : UIStateGame,
  cursorstate : @ui.CursorState,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  let clicked = cursorstate == @ui.CursorState::CLICKING ||
    cursorstate == @ui.CursorState::VSCROLL_IDLE
  match self.get(self.focused) {
    Some(focusedelement) => {
      if focusedelement.get_ui_model().is_active() {
        self.remove_cursor(self.focused)
        return focusedelement.send_cursor(clicked, cursorpos)
      }
      self.focused = UIElementType::UI_ELEMENT_NONE
      return cursorstate
    }
    None => ()
  }
  if not(clicked) {
    self.dragged = None
    match self.get_front(cursorpos) {
      Some(front) => {
        let front_type = front.key

        // if self.tooltip_parent != UIElementType::UI_ELEMENT_NONE {
        //   if front_type != self.tooltip_parent {
        //     clear_tooltip(self, self.tooltip_parent)
        //   }
        // }

        self.remove_cursor(front_type)
        return front.send_cursor(clicked, cursorpos)
      }
      None => ()
    }
    // self.remove_cursors()
    return self.stage.send_cursor(clicked, cursorpos)
  }
  if self.dragged.is_empty() {
    let mut drag_element_type = UIElementType::UI_ELEMENT_NONE
    let mut i = self.element_order.length()
    while i > 0 {
      i -= 1
      let t = self.element_order[i]
      match self.elements[t] {
        Some(element) =>
          if element.get_ui_model().is_active() &&
            element.get_ui_model().is_in_range(cursorpos) {
            self.dragged = Some(element)
            drag_element_type = t
            break
          }
        None => ()
      }
    }
    if drag_element_type != UIElementType::UI_ELEMENT_NONE {
      match self.element_order.search(drag_element_type) {
        Some(i) => self.element_order.remove(i) |> ignore
        None => ()
      }
      self.element_order.push(drag_element_type)
    }
  }
  if self.timer.now().since(self.time_rel_grabbed) < min_delay_next_grab {
    return @ui.CursorState::IDLE
  }
  match self.dragged {
    Some(dragged) => return dragged.send_cursor(clicked, cursorpos)
    None => ()
  }
  return self.stage.send_cursor(clicked, cursorpos)
}

///|
pub fn set_element(
  self : UIStateGame,
  is_focused : Bool,
  elem : @ui.Element
) -> Unit {
  let t = elem.key
  self.remove(t)
  self.element_order.push(t)
  if is_focused {
    self.focused = t
  }
  self.elements[t] = elem
}

///|
pub fn toggle_element(
  self : UIStateGame,
  t : UIElementType,
  is_focused : Bool,
  f : () -> @ui.Element
) -> Unit {
  match self.elements[t] {
    Some(element) => {
      match self.element_order.search(t) {
        Some(i) => self.element_order.remove(i) |> ignore
        None => ()
      }
      self.element_order.push(t)
      let active = element.get_ui_model().is_active()
      (element.toggle_active)()
      if active != element.get_ui_model().is_active() {
        if element.get_ui_model().is_active() {
          if t == UIElementType::WORLD_MAP {
            // Sound::new(SoundName::WORLD_MAP_OPEN).play()
          } else {
            // Sound::new(SoundName::MENU_UP).play()
          }
          self.ui.send_cursor_pressed(false)
        } else {
          if t == UIElementType::WORLD_MAP {
            // Sound::new(SoundName::WORLD_MAP_CLOSE).play()
          } else {
            // Sound::new(SoundName::MENU_DOWN).play()
          }
          element.object.remove_cursor()
          self.ui.send_cursor_pressed(false)
        }
      }
    }
    None => self.set_element(is_focused, f())
  }
}

///|
pub fn UIStateGame::remove(self : UIStateGame, t : UIElementType) -> Unit {
  if t == self.focused {
    self.focused = UIElementType::UI_ELEMENT_NONE
  }
  // if (type == tooltip_parent_) {
  //     clear_tooltip(tooltip_parent_);
  // }
  match self.element_order.search(t) {
    Some(i) => self.element_order.remove(i) |> ignore
    None => ()
  }
  match self.elements.get(t) {
    Some(element) => element.get_ui_model().deactivate()
    None => ()
  }
  self.elements.remove(t)
}

///|
pub fn UIStateGame::get(self : UIStateGame, t : UIElementType) -> @ui.Element? {
  self.elements[t].map(fn(e) { e })
}

///|
pub fn UIStateGame::get_front_by_types(
  self : UIStateGame,
  types : Array[UIElementType]
) -> @ui.Element? {
  // let mut i = self.element_order.length() - 1
  (self.element_order.length() - 1)
  .until(step=-1, 0, inclusive=true)
  .map_while(fn(i) {
    let t = self.element_order[i]
    if types.contains(t) {
      self.elements[t].map(fn(e) { e })
    } else {
      None
    }
  })
  .find_first(fn(it) { it.get_ui_model().is_active() })
}

///|
pub fn UIStateGame::get_front_by_pos(
  self : UIStateGame,
  pos : @struct.Point[Int]
) -> @ui.Element? {
  (self.element_order.length() - 1)
  .until(step=-1, 0, inclusive=true)
  .map_while(fn(i) {
    let t = self.element_order[i]
    self.elements[t]
  })
  .find_first(fn(e) {
    e.get_ui_model().is_active() && e.get_ui_model().is_in_range(pos)
  })
}

///|
pub fn UIStateGame::remove_cursor(
  self : UIStateGame,
  _t : UIElementType
) -> Unit {
  // Implementation goes here
}

///|
pub fn UIStateGame::get_front(
  self : UIStateGame,
  pos : @struct.Point[Int]
) -> @ui.Element? {
  self.element_order
  .iter()
  .map_while(fn(t) { self.elements[t] })
  .find_first(fn(e) {
    e.get_ui_model().is_active() && e.get_ui_model().is_in_range(pos)
  })
}

///|
fn doubleclick(self : UIStateGame, pos : @struct.Point[Int]) -> Unit {
  match self.get_front_by_pos(pos) {
    Some(e) => e.doubleclick(pos)
    None => ()
  }
}
