///|
/// 基础动作类型（无额外参数）。
pub(all) enum BasicActionId {
  MOVE_UP
  MOVE_DOWN
  MOVE_LEFT
  MOVE_RIGHT
  JUMP
  ATTACK
  PICKUP
} derive(Eq, Hash, Show)

///|
/// 可绑定动作：基础动作 / 技能 / 物品。
pub(all) enum Action {
  BASIC(BasicActionId)
  SKILL(Int)
  ITEM(Int)
} derive(Eq, Hash, Show)

///|
pub type Keymap = Map[@inputs.Code, Action]

///|
let current_keymap_ref : Ref[Keymap?] = Ref::new(None)

///|
/// 设置当前按键映射。
pub fn set_keymap(mapping : Keymap) -> Unit {
  current_keymap_ref.val = Some(mapping)
}

///|
/// 获取当前按键映射；未初始化时返回 None。
pub fn get_keymap() -> Keymap? {
  current_keymap_ref.val
}

///|
fn expect_keymap() -> Keymap {
  match get_keymap() {
    Some(mapping) => mapping
    None => panic()
  }
}

///|
/// 按键查动作；无映射时返回 None。
pub fn get_action(mapping : Keymap, key : @inputs.Code) -> Action? {
  mapping.get(key)
}

///|
/// 当前按键映射下，本帧刚触发的动作列表（去重）。
pub fn just_pressed_actions() -> Array[Action] {
  just_pressed_actions_in(get_keymap().unwrap_or(Map::new()))
}

///|
/// 当前按键映射下，正在按住的动作列表（去重）。
pub fn pressed_actions() -> Array[Action] {
  pressed_actions_in(get_keymap().unwrap_or(Map::new()))
}

///|
/// 在指定映射下，本帧刚触发的动作列表（去重）。
pub fn just_pressed_actions_in(mapping : Keymap) -> Array[Action] {
  collect_actions_in(mapping, fn(code) { @inputs.is_just_pressed(code) })
}

///|
/// 在指定映射下，正在按住的动作列表（去重）。
pub fn pressed_actions_in(mapping : Keymap) -> Array[Action] {
  collect_actions_in(mapping, fn(code) { @inputs.is_pressed(code) })
}

///|
/// 当前按键映射下，检查某个动作是否按住。
pub fn is_pressed(action : Action) -> Bool {
  is_pressed_in(expect_keymap(), action)
}

///|
/// 当前按键映射下，检查某个动作是否刚按下。
pub fn is_just_pressed(action : Action) -> Bool {
  is_just_pressed_in(expect_keymap(), action)
}

///|
/// 在指定映射下，检查某个动作是否按住。
pub fn is_pressed_in(mapping : Keymap, action : Action) -> Bool {
  for code, mapped_action in mapping {
    if mapped_action == action && @inputs.is_pressed(code) {
      return true
    }
  }
  false
}

///|
/// 在指定映射下，检查某个动作是否刚按下。
pub fn is_just_pressed_in(mapping : Keymap, action : Action) -> Bool {
  for code, mapped_action in mapping {
    if mapped_action == action && @inputs.is_just_pressed(code) {
      return true
    }
  }
  false
}

///|
fn collect_actions_in(
  mapping : Keymap,
  is_triggered : (@inputs.Code) -> Bool,
) -> Array[Action] {
  let actions = []
  let seen : Map[Action, Bool] = Map::new()
  for code, action in mapping {
    if is_triggered(code) && !seen.contains(action) {
      seen[action] = true
      actions.push(action)
    }
  }
  actions
}
