typealias UIButtons = @ui.UIButtons

typealias ButtonState = @ui.ButtonState

typealias UIElementBase = @ui.UIElementBase

typealias UIElementType = @ui.UIElementType

typealias UIElement = @ui.UIElement

let min_delay_next_grab : Duration = 10 |> Duration::from_micro

struct UIStateGame {
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
  mut dragged_icon : @inventory.Icon?
  mut time_rel_grabbed : TimePoint
  mut vwidth : Int
  mut vheight : Int
}

let icon_map : @immut/hashmap.T[@inventory.IconType, UIElementType] = @immut/hashmap.from_array(
  [
    (@inventory.IconType::ICON_NONE, UIElementType::UI_ELEMENT_NONE),
    (@inventory.IconType::SKILL, UIElementType::SKILL_BOOK),
    (@inventory.IconType::EQUIP, UIElementType::EQUIP_INVENTORY),
    (@inventory.IconType::ITEM, UIElementType::ITEM_INVENTORY),
    (@inventory.IconType::KEY, UIElementType::KEY_CONFIG),
  ],
)

pub fn UIStateGame::new() -> UIStateGame {
  {
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
    dragged_icon: None,
    time_rel_grabbed: Timer::get().now(),
    vwidth: @constants.constants.get_viewwidth(),
    vheight: @constants.constants.get_viewheight(),
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

pub fn draw(
  self : UIStateGame,
  inter : Double,
  cursor : @struct.Point[Int]
) -> Unit {
  self.element_order.each(
    fn(t) {
      match self.elements.get(t) {
        Some(element) =>
          if element.get_ui_element_base().is_active() {
            element.draw(inter)
          }
        None => ()
      }
    },
  )

  // if (tooltip_) {
  //     tooltip_->get().draw(cursor + Point<int16_t>(0, 22));
  // }
  //TODO: draw tooltip

  match self.dragged_icon {
    Some(icon) => icon.dragdraw(cursor)
    None => ()
  }
}

pub fn update(self : UIStateGame) -> Unit {
  let mut update_screen = false
  let new_width = @constants.constants.get_viewwidth()
  let new_height = @constants.constants.get_viewheight()
  if self.vwidth != new_width || self.vheight != new_height {
    update_screen = true
    self.vwidth = new_width
    self.vheight = new_height
    //TODO: adjust status bar
  }
  self.element_order.each(
    fn(t) {
      match self.elements.get(t) {
        Some(element) =>
          if element.get_ui_element_base().is_active() {
            element.update()
            if update_screen {
              //TODO: update screen
              // element.update_screen(new_width, new_height)
            }
          }
        None => ()
      }
    },
  )
}

pub fn send_key(
  self : UIStateGame,
  t : @KeyType.Id,
  action : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  match self.get(self.focused) {
    Some(focusedelement) => {
      if focusedelement.get_ui_element_base().is_active() {
        return focusedelement.send_key(action, pressed, escape)
      }
      self.focused = UIElementType::UI_ELEMENT_NONE
      return
    }
    None => ()
  }
  match t {
    @KeyType.Id::MENU =>
      if pressed {
        match @KeyAction.get_action_by_id?(action).unwrap() {
          //         @KeyAction.Id::EQUIPMENT => {
          //             self.emplace(UIEquipInventory::new(Stage::get().get_player().get_inventory()))
          //         }
          @KeyAction.Id::ITEMS =>
            self.toggle_element(
              UIElementType::ITEM_INVENTORY,
              @inventory.UIItemInventory::is_focused(),
              fn() {
                @inventory.UIItemInventory::new(Stage::get().get_inventory())
              },
            )
          //         @KeyAction.Id::STATS => {
          //             self.emplace(UIStatsInfo::new(Stage::get().get_player().get_stats()))
          //         }
          @KeyAction.Id::SKILLS =>
            self.toggle_element(
              UIElementType::SKILL_BOOK,
              @player.SkillBookUI::is_focused(),
              fn() {
                let player = Stage::get().get_player().unwrap()
                @player.SkillBookUI::new(
                  player.get_skills(),
                  player.get_stats(),
                )
              },
            )
          //         // @KeyAction.Id::FRIENDS => {
          //         //     self.handle_user_list(@KeyAction.Id::FRIENDS)
          //         // }
          //         // @KeyAction.Id::PARTY => {
          //         //     self.handle_user_list(@KeyAction.Id::PARTY)
          //         // }
          //         // @KeyAction.Id::BOSS_PARTY => {
          //         //     self.handle_user_list(@KeyAction.Id::BOSS_PARTY)
          //         // }
          //         @KeyAction.Id::WORLD_MAP => {
          //             self.emplace(UIWorldMap::new())
          //         }
          //         @KeyAction.Id::MAPLE_CHAT => {
          //           match  UI::get().get_element(UIElementType::CHAT) {
          //             Some(chat) =>
          //                 if chat.is_active().not() {
          //                     self.emplace(UIChat::new)
          //                 }
          //             None=> {
          //                 self.emplace(UIChat::new)
          //             }
          //           }
          //         }
          //         @KeyAction.Id::MINI_MAP => {
          //             match UI::get().get_element(UIElementType::MINI_MAP) {
          //                 Some(minimap) => minimap.send_key(action, pressed, escape)
          //                 None => ()
          //             }
          //         }
          //         @KeyAction.Id::QUEST_LOG => {
          //             self.emplace(UIQuestLog::new(Stage::get().get_player().get_quests()))
          //         }
          //         @KeyAction.Id::MENU => {
          //             match UI::get().get_element(UIElementType::STATUS_BAR) {
          //                 Some(statusbar) => statusbar.toggle_menu()
          //                 None => ()
          //             }
          //         }
          //         @KeyAction.Id::QUICK_SLOTS => {
          //             match UI::get().get_element(UIElementType::STATUS_BAR) {
          //                 Some(statusbar) => statusbar.toggle_qs()
          //                 None => (),
          //             }
          //         }
          //         @KeyAction.Id::CASHSHOP => {
          //             fn_enter_cashshop()
          //         }
          //         @KeyAction.Id::TOGGLE_CHAT => {
          //             match UI::get().get_element(UIElementType::CHAT_BAR) {
          //                 Some(chatbar) => {
          //                     if !chatbar.is_chatfield_open() {
          //                         chatbar.toggle_chat()
          //                     }
          //                 }
          //                 None => ()
          //             }
          //         }
          //         @KeyAction.Id::KEY_BINDINGS => {
          //         match UI::get().get_element(UIElementType::KEY_CONFIG) {
          //             Some(keyconfig) =>
          //                 if keyconfig.is_active() {
          //                     keyconfig.close()
          //                 } else {
          //                     self.emplace(UIKeyConfig::new(Stage::get().get_player().get_inventory(), Stage::get().get_player().get_skills()))
          //                 }
          //             None=> {
          //                 self.emplace(UIKeyConfig::new(Stage::get().get_player().get_inventory(), Stage::get().get_player().get_skills()))
          //             }
          //           }
          //         }
          //         // @KeyAction.Id::MAIN_MENU => {
          //         //     match UI::get().get_element(UIElementType::StatusBar) {
          //         //         Some(statusbar) => statusbar.send_key(action, pressed, escape),
          //         //         None => (),
          //         //     }
          //         // }
          //         // @KeyAction.Id::EVENT => {
          //         //     self.emplace(UIEvent::new)
          //         // }
          //         // @KeyAction.Id::CHANGE_CHANNEL => {
          //         //     self.emplace(fn(){UIChannel::new(Stage::get().get_player().get_world_id(), Stage::get().get_player().get_channel_id(), self.channel_count)})
          //         // }
          //         _ => {
          //             println("Action \(action) not handled!")
          //         }
          _ => ()
        }
      }
    @KeyType.Id::ACTION
    | @KeyType.Id::FACE | @KeyType.Id::ITEM | @KeyType.Id::SKILL =>
      Stage::get().send_key?(t, action, pressed).unwrap()
    _ => ()
  }
}

type UIUserListTab

pub fn handle_user_list(self : UIStateGame, tab : UIUserListTab) -> Unit {
  // let tab = match action {
  //     @KeyAction.Id::FRIENDS => UIUserListTab::FRIEND,
  //     @KeyAction.Id::PARTY => UIUserListTab::PARTY,
  //     @KeyAction.Id::BOSS_PARTY => UIUserListTab::BOSS,
  //     _ => return,
  // }
  // if let Some(userlist) = UI::get().get_element(UIElementType::UserList) {
  //     if userlist.get_tab() != tab && userlist.is_active() {
  //         userlist.change_tab(tab)
  //     } else {
  //         self.emplace(UIUserList::new(tab))
  //         if userlist.get_tab() != tab && userlist.is_active() {
  //             userlist.change_tab(tab)
  //         }
  //     }
  // } else {
  //     self.emplace(UIUserList::new(tab))
  // }
}

pub fn send_cursor(
  self : UIStateGame,
  cursorstate : CursorState,
  cursorpos : @struct.Point[Int]
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
  let clicked = cursorstate == CursorState::CLICKING ||
    cursorstate == CursorState::VSCROLL_IDLE
  match self.get(self.focused) {
    Some(focusedelement) => {
      if focusedelement.get_ui_element_base().is_active() {
        self.remove_cursor(self.focused)
        return focusedelement.send_cursor(clicked, cursorpos)
      }
      self.focused = UIElementType::UI_ELEMENT_NONE
      return cursorstate
    }
    None => ()
  }
  if clicked.not() {
    self.dragged = None
    match self.get_front(cursorpos) {
      Some(front) => {
        let front_type = front.get_type()

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
    self.remove_cursors()
    return Stage::get().send_cursor(clicked, cursorpos)
  }
  if self.dragged.is_empty() {
    let mut drag_element_type = UIElementType::UI_ELEMENT_NONE
    let mut i = self.element_order.length()
    while i > 0 {
      i -= 1
      let t = self.element_order[i]
      match self.elements[t] {
        Some(element) =>
          if element.get_ui_element_base().is_active() &&
            element.is_in_range(cursorpos) {
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
  if Timer::get().now().since(self.time_rel_grabbed) < min_delay_next_grab {
    return CursorState::IDLE
  }
  match self.dragged {
    Some(dragged) => return dragged.send_cursor(clicked, cursorpos)
    None => ()
  }
  return Stage::get().send_cursor(clicked, cursorpos)
}

pub fn drag_icon(self : UIStateGame, icon : @inventory.Icon) -> Unit {
  // Implementation goes here
}

pub fn set_element(
  self : UIStateGame,
  is_focused : Bool,
  elem : UIElement
) -> Unit {
  let t = elem.get_type()
  self.remove(t)
  self.element_order.push(t)
  if is_focused {
    self.focused = t
  }
  self.elements[t] = elem
}

pub fn toggle_element(
  self : UIStateGame,
  t : UIElementType,
  is_focused : Bool,
  f : () -> UIElement
) -> Unit {
  match self.elements[t] {
    Some(element) => {
      match self.element_order.search(t) {
        Some(i) => self.element_order.remove(i) |> ignore
        None => ()
      }
      self.element_order.push(t)
      let active = element.get_ui_element_base().is_active()
      element.toggle_active()
      if active != element.get_ui_element_base().is_active() {
        if element.get_ui_element_base().is_active() {
          if t == UIElementType::WORLD_MAP {
            Sound::new(SoundName::WORLD_MAP_OPEN).play()
          } else {
            Sound::new(SoundName::MENU_UP).play()
          }
          UI::get().send_cursor_pressed(false)
        } else {
          if t == UIElementType::WORLD_MAP {
            Sound::new(SoundName::WORLD_MAP_CLOSE).play()
          } else {
            Sound::new(SoundName::MENU_DOWN).play()
          }
          element.remove_cursor()
          match self.dragged_icon {
            Some(dragged_icon) =>
              if (element.get_type() |> @option.some) ==
                icon_map[dragged_icon.get_type()] {
                self.remove_icon()
              }
            None => ()
          }
          UI::get().send_cursor_pressed(false)
        }
      }
    }
    None => self.set_element(is_focused, f())
  }
}

pub fn remove(self : UIStateGame, t : UIElementType) -> Unit {
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
    Some(element) => element.get_ui_element_base().deactivate()
    None => ()
  }
  self.elements.remove(t)
}

fn get(self : UIStateGame, t : UIElementType) -> UIElement? {
  self.elements[t]
}

pub fn get_front_by_types(
  self : UIStateGame,
  types : Array[UIElementType]
) -> UIElement? {
  let mut i = self.element_order.length() - 1
  while i >= 0 {
    let t = self.element_order[i]
    if types.contains(t) {
      let res = self.elements[t].filter(
        fn(it) { it.get_ui_element_base().is_active() },
      )
      match res {
        Some(_) as r => return r
        None => ()
      }
    }
    i -= 1
  }
  return None
}

pub fn get_front_by_pos(
  self : UIStateGame,
  pos : @struct.Point[Int]
) -> UIElement? {
  let mut i = self.element_order.length() - 1
  while i >= 0 {
    let t = self.element_order[i]
    let res = self.elements[t].filter(
      fn(it) { it.get_ui_element_base().is_active() && it.is_in_range(pos) },
    )
    match res {
      Some(_) as r => return r
      None => ()
    }
    i -= 1
  }
  return None
}

pub fn drop_icon(
  self : UIStateGame,
  _icon : @inventory.Icon,
  _pos : @struct.Point[Int]
) -> Bool {
  // Implementation goes here
  abort("TODO")
}

pub fn remove_icon(self : UIStateGame) -> Unit {
  // Implementation goes here
}

pub fn remove_cursors(self : UIStateGame) -> Unit {
  // Implementation goes here
}

pub fn remove_cursor(self : UIStateGame, _t : UIElementType) -> Unit {
  // Implementation goes here
}

fn get_front(self : UIStateGame, pos : @struct.Point[Int]) -> UIElement? {
  self.element_order
  .iter()
  .flat_map(
    fn(t) {
      let res = self.elements[t].filter(
        fn(it) { it.get_ui_element_base().is_active() && it.is_in_range(pos) },
      )
      match res {
        Some(e) => Iter::singleton(e)
        None => Iter::empty()
      }
    },
  )
  .find_first(fn(_it) { true })
}
