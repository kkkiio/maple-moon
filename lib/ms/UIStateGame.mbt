let min_delay_next_grab : Duration = 10 |> Duration::from_micro

struct UIStateGame {
  // stats : CharStats
  elements : Map[UIElementType, UIElement]
  element_order : Array[UIElementType]
  mut focused : UIElementType
  mut dragged : UIElement?
  // eq_tooltip : EquipTooltip
  // it_tooltip : ItemTooltip
  // sk_tooltip : SkillTooltip
  // te_tooltip : TextTooltip
  // ma_tooltip : MapTooltip
  // mut tooltip : Option[Tooltip]
  // tooltip_parent : TooltipParent
  mut dragged_icon : Icon?
  mut time_rel_grabbed : TimePoint
  channel_count : Int
  // icon_map : Map[Icon.IconType, UIElement.Type]
}

pub fn UIStateGame::new(channel_count : Int) -> UIStateGame {
  {
    // stats: CharStats::default(),
    elements: Map::new(),
    element_order: [],
    focused: UIElementType::NONE,
    dragged: None,
    // eq_tooltip: @Tooltip.EquipTooltip::default(),
    // it_tooltip: @Tooltip.ItemTooltip::default(),
    // sk_tooltip: @Tooltip.SkillTooltip::default(),
    // te_tooltip: @Tooltip.TextTooltip::default(),
    // ma_tooltip: @Tooltip.MapTooltip::default(),
    // tooltip: None,
    // tooltip_parent: TooltipParent::NONE,
    dragged_icon: None,
    time_rel_grabbed: Timer::get().now(),
    channel_count,
  }
  // icon_map: Map::from_array([
  //   (Icon.IconType::NONE, UIElement.Type::NONE),
  //   (Icon.IconType::SKILL, UIElement.Type::SKILL_BOOK),
  //   (Icon.IconType::EQUIP, UIElement.Type::EQUIP_INVENTORY),
  //   (Icon.IconType::ITEM, UIElement.Type::ITEM_INVENTORY),
  //   (Icon.IconType::KEY, UIElement.Type::KEY_CONFIG),
  //   (Icon.IconType::NUM_TYPES, UIElement.Type::NUM_TYPES),
  // ]),
}

pub fn draw(self : UIStateGame, inter : Double, cursor : Point[Int]) -> Unit {
  // Implementation goes here
}

pub fn update(self : UIStateGame) -> Unit {
  // Implementation goes here
}

pub fn doubleclick(self : UIStateGame, pos : Point[Int]) -> Unit {
  // Implementation goes here
}

pub fn rightclick(self : UIStateGame, pos : Point[Int]) -> Unit {
  // Implementation goes here
}

pub fn send_key(
  self : UIStateGame,
  t : @KeyType.Id,
  action : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // Implementation goes here
}

pub fn send_cursor(
  self : UIStateGame,
  cursorstate : CursorState,
  cursorpos : Point[Int]
) -> CursorState {
  match self.dragged_icon {
    Some(dragged_icon) => {
      if cursorstate == CursorState::CLICKING {
        if self.drop_icon(dragged_icon, cursorpos) {
          remove_icon(self)
          self.time_rel_grabbed = Timer::get().now()
        }
        return cursorstate
      }
      return CursorState::GRABBING
    }
    None => ()
  }
  let clicked = cursorstate == CursorState::CLICKING || cursorstate == CursorState::VSCROLL_IDLE
  match self.get(self.focused) {
    Some(focusedelement) => {
      if focusedelement.is_active() {
        self.remove_cursor(focusedelement.get_type())
        return focusedelement.send_cursor(clicked, cursorpos)
      }
      self.focused = UIElementType::NONE
      return cursorstate
    }
    None => ()
  }
  if clicked.not() {
    self.dragged = None
    match self.get_front(cursorpos) {
      Some(front) => {
        let front_type = front.get_type()

        // if self.tooltip_parent != UIElementType::NONE {
        //   if front_type != self.tooltip_parent {
        //     clear_tooltip(self, self.tooltip_parent)
        //   }
        // }

        self.remove_cursor(front_type)
        return front.send_cursor(clicked, cursorpos)
      }
      None => ()
    }
    self.remove_cursors()
    return Stage::get().send_cursor(clicked, cursorpos)
  }
  if self.dragged.is_empty() {
    let mut drag_element_type = UIElementType::NONE
    let mut i = self.element_order.length()
    while i > 0 {
      i -= 1
      let t = self.element_order[i]
      match self.elements[t] {
        Some(element) =>
          if element.is_active() && element.is_in_range(cursorpos) {
            self.dragged = Some(element)
            drag_element_type = t
            break
          }
        None => ()
      }
    }
    if drag_element_type != UIElementType::NONE {
      match self.element_order.search(drag_element_type) {
        Some(i) => self.element_order.remove(i) |> ignore
        None => ()
      }
      self.element_order.push(drag_element_type)
    }
  }
  if Timer::get().now().since(self.time_rel_grabbed) < min_delay_next_grab {
    return CursorState::IDLE
  }
  match self.dragged {
    Some(dragged) => return dragged.send_cursor(clicked, cursorpos)
    None => ()
  }
  return Stage::get().send_cursor(clicked, cursorpos)
}

pub fn send_scroll(self : UIStateGame, yoffset : Double) -> Unit {
  // Implementation goes here
}

pub fn send_close(self : UIStateGame) -> Unit {
  // Implementation goes here
}

pub fn drag_icon(self : UIStateGame, icon : Icon) -> Unit {
  // Implementation goes here
}

pub fn clear_tooltip(self : UIStateGame, parent : TooltipParent) -> Unit {
  // Implementation goes here
}

pub fn show_equip(
  self : UIStateGame,
  parent : TooltipParent,
  slot : Int
) -> Unit {
  // Implementation goes here
}

pub fn show_item(
  self : UIStateGame,
  parent : TooltipParent,
  itemid : Int
) -> Unit {
  // Implementation goes here
}

pub fn show_skill(
  self : UIStateGame,
  parent : TooltipParent,
  skill_id : Int,
  level : Int,
  masterlevel : Int,
  expiration : Int64
) -> Unit {
  // Implementation goes here
}

pub fn show_text(
  self : UIStateGame,
  parent : TooltipParent,
  text : String
) -> Unit {
  // Implementation goes here
}

pub fn show_map(
  self : UIStateGame,
  parent : TooltipParent,
  name : String,
  description : String,
  mapid : Int,
  bolded : Bool
) -> Unit {
  // Implementation goes here
}

pub fn pre_add(
  self : UIStateGame,
  t : UIElementType,
  toggled : Bool,
  focused : Bool
) -> Iter[(UIElementType, UIElement)] {
  // Implementation goes here
  abort("TODO")
}

pub fn remove(self : UIStateGame, t : UIElementType) -> Unit {
  // Implementation goes here
  abort("TODO")
}

fn get(self : UIStateGame, t : UIElementType) -> UIElement? {
  self.elements[t]
}

pub fn get_front_by_types(
  self : UIStateGame,
  types : Array[UIElementType]
) -> UIElement? {
  // Implementation goes here
  abort("TODO")
}

pub fn get_front_by_pos(self : UIStateGame, pos : Point[Int]) -> UIElement? {
  // Implementation goes here
  abort("TODO")
}

pub fn drop_icon(self : UIStateGame, icon : Icon, pos : Point[Int]) -> Bool {
  // Implementation goes here
  abort("TODO")
}

pub fn remove_icon(self : UIStateGame) -> Unit {
  // Implementation goes here
}

pub fn remove_cursors(self : UIStateGame) -> Unit {
  // Implementation goes here
}

pub fn remove_cursor(self : UIStateGame, t : UIElementType) -> Unit {
  // Implementation goes here
}

// pub fn emplace[T, Args](self : UIStateGame, args : Args...) -> Unit {
//   // Implementation goes here
// }

// UIElement *UIStateGame::get_front(Point<int16_t> pos) {
//     auto begin = element_order_.rbegin();
//     auto end = element_order_.rend();

//     for (auto iter = begin; iter != end; ++iter) {
//         auto &element = elements_[*iter];

//         if (element && element->is_active() && element->is_in_range(pos)) {
//             return element.get();
//         }
//     }

//     return nullptr;
// }

fn get_front(self : UIStateGame, pos : Point[Int]) -> UIElement? {
  self.element_order.as_iter().flat_map(
    fn(t) {
      let res = self.elements[t].filter(
        fn(it) { it.is_active() && it.is_in_range(pos) },
      )
      match res {
        Some(e) => Iter::singleton(e)
        None => Iter::empty()
      }
    },
  ).find_first(fn(it) { true })
}
