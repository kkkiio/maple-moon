///|
/// Identifies gameplay actions whose meaning does not depend on an input device.
pub(all) enum BasicActionId {
  MOVE_UP
  MOVE_DOWN
  MOVE_LEFT
  MOVE_RIGHT
  JUMP
  ATTACK
  INTERACT
} derive(Eq, Hash, Debug)

///|
/// Identifies one of the four compact skill or item slots shared by keyboard,
/// gamepad, and future touch controls.
pub(all) enum QuickSlotId {
  SLOT_1
  SLOT_2
  SLOT_3
  SLOT_4
} derive(Eq, Hash, Debug)

///|
/// Describes the gameplay content assigned to a quick slot.
pub(all) enum QuickSlotContent {
  /// Cast the skill with the supplied game skill ID.
  Skill(Int)
  /// Use the inventory item with the supplied game item ID.
  Item(Int)
} derive(Eq, Debug)

///|
/// Identifies the small set of UI actions currently shared by keyboard and
/// gamepad. Selene continues to own spatial focus navigation and activation.
pub(all) enum UiActionId {
  CANCEL
  PREVIOUS_TAB
  NEXT_TAB
  TOGGLE_INVENTORY
  TOGGLE_WORLD_MAP
  TOGGLE_QUEST_LOG
} derive(Eq, Hash, Debug)

///|
/// A logical input action. Gameplay actions are suppressed while a modal UI
/// owner is active; UI actions remain available so that the modal can close or
/// navigate without reconfiguring physical bindings.
pub(all) enum Action {
  /// A character movement, combat, or world-interaction action.
  BASIC(BasicActionId)
  /// Activates the content currently assigned to the supplied compact slot.
  QUICK_SLOT(QuickSlotId)
  /// A panel or focus-navigation action that remains live under modal gating.
  UI(UiActionId)
} derive(Eq, Hash, Debug)

///|
/// Maps logical actions to all physical bindings that may drive them at once.
pub type Keymap = Map[Action, Array[@input_action.InputBinding]]

///|
/// Maps each occupied quick slot to a skill or inventory item.
pub type QuickSlots = Map[QuickSlotId, QuickSlotContent]

///|
/// Builds Maple Moon's default keyboard and gamepad bindings. The returned map
/// contains every gameplay and UI action that can currently be triggered by a
/// player, and callers may customize the map before installing it.
///
/// # Example
/// ```moonbit nocheck
/// set_keymap(default_keymap())
/// ```
pub fn default_keymap() -> Keymap {
  Map([
    (
      Action::BASIC(BasicActionId::MOVE_UP),
      [
        @input_action.InputBinding::Key(@inputs.Code::ArrowUp),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::DPadUp,
        ),
        @input_action.InputBinding::AnyGamepadAxis(
          @inputs.GamepadAxis::LeftStickY,
          dead_zone=0.2,
          positive=false,
        ),
      ],
    ),
    (
      Action::BASIC(BasicActionId::MOVE_DOWN),
      [
        @input_action.InputBinding::Key(@inputs.Code::ArrowDown),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::DPadDown,
        ),
        @input_action.InputBinding::AnyGamepadAxis(
          @inputs.GamepadAxis::LeftStickY,
          dead_zone=0.2,
          positive=true,
        ),
      ],
    ),
    (
      Action::BASIC(BasicActionId::MOVE_LEFT),
      [
        @input_action.InputBinding::Key(@inputs.Code::ArrowLeft),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::DPadLeft,
        ),
        @input_action.InputBinding::AnyGamepadAxis(
          @inputs.GamepadAxis::LeftStickX,
          dead_zone=0.2,
          positive=false,
        ),
      ],
    ),
    (
      Action::BASIC(BasicActionId::MOVE_RIGHT),
      [
        @input_action.InputBinding::Key(@inputs.Code::ArrowRight),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::DPadRight,
        ),
        @input_action.InputBinding::AnyGamepadAxis(
          @inputs.GamepadAxis::LeftStickX,
          dead_zone=0.2,
          positive=true,
        ),
      ],
    ),
    (
      Action::BASIC(BasicActionId::JUMP),
      [
        @input_action.InputBinding::Key(@inputs.Code::Space),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::South,
        ),
      ],
    ),
    (
      Action::BASIC(BasicActionId::ATTACK),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyX),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::West,
        ),
      ],
    ),
    (
      Action::BASIC(BasicActionId::INTERACT),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyZ),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::North,
        ),
      ],
    ),
    (
      Action::QUICK_SLOT(QuickSlotId::SLOT_1),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyA),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::LeftTrigger,
        ),
      ],
    ),
    (
      Action::QUICK_SLOT(QuickSlotId::SLOT_2),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyS),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::RightTrigger,
        ),
      ],
    ),
    (
      Action::QUICK_SLOT(QuickSlotId::SLOT_3),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyD),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::LeftTrigger2,
        ),
      ],
    ),
    (
      Action::QUICK_SLOT(QuickSlotId::SLOT_4),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyF),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::RightTrigger2,
        ),
      ],
    ),
    (
      Action::UI(UiActionId::CANCEL),
      [
        @input_action.InputBinding::Key(@inputs.Code::Escape),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::East,
        ),
      ],
    ),
    (
      Action::UI(UiActionId::PREVIOUS_TAB),
      [
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::LeftTrigger,
        ),
      ],
    ),
    (
      Action::UI(UiActionId::NEXT_TAB),
      [
        @input_action.InputBinding::Key(@inputs.Code::Tab),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::RightTrigger,
        ),
      ],
    ),
    (
      Action::UI(UiActionId::TOGGLE_INVENTORY),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyI),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::Start,
        ),
      ],
    ),
    (
      Action::UI(UiActionId::TOGGLE_WORLD_MAP),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyW),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::Select,
        ),
      ],
    ),
    (
      Action::UI(UiActionId::TOGGLE_QUEST_LOG),
      [
        @input_action.InputBinding::Key(@inputs.Code::KeyQ),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::RightThumb,
        ),
      ],
    ),
  ])
}

///|
/// The most recently used meaningful input method. This state changes prompt
/// presentation, UI focus behavior, and rumble routing; it never disables the
/// other input methods.
pub(all) enum InputMethod {
  KeyboardMouse
  /// The gamepad whose button or newly deflected stick was used most recently.
  Gamepad(@inputs.Gamepad)
  Touch
} derive(Eq, Debug)

///|
/// Emitted once whenever the most recently used meaningful input method changes.
pub(all) struct InputMethodChangedEvent {
  /// The input method that was active before this frame's meaningful input.
  previous : InputMethod
  /// The input method selected by this frame's meaningful input.
  current : InputMethod
} derive(Eq, Debug)

///|
/// Input-method transition bus owned by `keymap`. `game_app` registers this
/// single bus to each world; Selene keeps its event queues and reader cursors
/// isolated per world for frame-lifetime delivery to prompt, cursor, and
/// rumble systems.
pub let input_method_changed_event_bus : @event.Events[InputMethodChangedEvent] = @event.Events()

///|
priv struct KeymapWorldRuntime {
  mut keymap : Keymap?
  mut quick_slots : QuickSlots
  gameplay_suppressors : Set[String]
  mut active_input_method : InputMethod
  armed_gamepad_axes : Set[@inputs.GamepadAxisInput]
  mouse_wheel_reader : @event.EventReader[@inputs.MouseWheelEvent]
  mut accumulated_mouse_travel : Double
}

///|
let runtimes_by_world : Map[UInt, KeymapWorldRuntime] = Map([])

///|
fn make_world_runtime() -> KeymapWorldRuntime {
  {
    keymap: None,
    quick_slots: Map([]),
    gameplay_suppressors: Set([]),
    active_input_method: KeyboardMouse,
    armed_gamepad_axes: Set([]),
    mouse_wheel_reader: @event.EventReader(),
    accumulated_mouse_travel: 0.0,
  }
}

///|
fn world_runtime(world : @ecs.World) -> KeymapWorldRuntime {
  runtimes_by_world.get_or_init(world.id(), make_world_runtime)
}

///|
fn current_world_runtime() -> KeymapWorldRuntime {
  world_runtime(@ecs.require_current_world())
}

///|
const GAMEPAD_AXIS_ARM_THRESHOLD : Double = 0.25

///|
const GAMEPAD_AXIS_ACTIVATION_THRESHOLD : Double = 0.55

///|
const MOUSE_ACTIVATION_DISTANCE : Double = 4.0

///|
fn input_action_for(action : Action) -> @input_action.InputAction {
  let name = match action {
    BASIC(MOVE_UP) => "maple.gameplay.move_up"
    BASIC(MOVE_DOWN) => "maple.gameplay.move_down"
    BASIC(MOVE_LEFT) => "maple.gameplay.move_left"
    BASIC(MOVE_RIGHT) => "maple.gameplay.move_right"
    BASIC(JUMP) => "maple.gameplay.jump"
    BASIC(ATTACK) => "maple.gameplay.attack"
    BASIC(INTERACT) => "maple.gameplay.interact"
    QUICK_SLOT(SLOT_1) => "maple.gameplay.quick_slot_1"
    QUICK_SLOT(SLOT_2) => "maple.gameplay.quick_slot_2"
    QUICK_SLOT(SLOT_3) => "maple.gameplay.quick_slot_3"
    QUICK_SLOT(SLOT_4) => "maple.gameplay.quick_slot_4"
    UI(CANCEL) => "maple.ui.cancel"
    UI(PREVIOUS_TAB) => "maple.ui.previous_tab"
    UI(NEXT_TAB) => "maple.ui.next_tab"
    UI(TOGGLE_INVENTORY) => "maple.ui.toggle_inventory"
    UI(TOGGLE_WORLD_MAP) => "maple.ui.toggle_world_map"
    UI(TOGGLE_QUEST_LOG) => "maple.ui.toggle_quest_log"
  }
  @input_action.InputAction(name)
}

///|
fn is_gameplay_action(action : Action) -> Bool {
  match action {
    BASIC(_) | QUICK_SLOT(_) => true
    UI(_) => false
  }
}

///|
/// Installs a complete logical action map in the current ECS world and replaces
/// the bindings previously owned by Maple Moon in that world without disturbing
/// actions registered by other systems.
///
/// # Example
/// ```moonbit nocheck
/// set_keymap(Map([]))
/// ```
pub fn set_keymap(mapping : Keymap) -> Unit {
  let runtime = current_world_runtime()
  match runtime.keymap {
    Some(previous) =>
      for action, _ in previous {
        @input_action.clear_action_bindings(input_action_for(action))
      }
    None => ()
  }
  let installed : Keymap = Map([])
  for action, bindings in mapping {
    let copied = []
    for binding in bindings {
      @input_action.bind_action(input_action_for(action), binding)
      copied.push(binding)
    }
    installed.set(action, copied)
  }
  runtime.keymap = Some(installed)
}

///|
/// Returns the logical action map installed in the current ECS world, or `None`
/// before that world's game input initialization.
///
/// # Example
/// ```moonbit nocheck
/// inspect(get_keymap() is Some(_), content="true")
/// ```
pub fn get_keymap() -> Keymap? {
  current_world_runtime().keymap
}

///|
/// Returns the physical bindings configured for one logical action.
///
/// # Example
/// ```moonbit nocheck
/// let mapping : Keymap = Map([])
/// inspect(get_bindings(mapping, BASIC(JUMP)).length(), content="0")
/// ```
pub fn get_bindings(
  mapping : Keymap,
  action : Action,
) -> Array[@input_action.InputBinding] {
  mapping.get(action).map(fn(bindings) { bindings.copy() }).unwrap_or([])
}

///|
/// Replaces all four quick-slot assignments in the current ECS world. Missing
/// entries represent empty slots and safely perform no gameplay action.
///
/// # Example
/// ```moonbit nocheck
/// set_quick_slots(Map([(SLOT_1, Skill(3101005))]))
/// ```
pub fn set_quick_slots(slots : QuickSlots) -> Unit {
  let runtime = current_world_runtime()
  let installed : QuickSlots = Map([])
  for slot, content in slots {
    installed.set(slot, content)
  }
  runtime.quick_slots = installed
}

///|
/// Returns the skill or item assigned to a quick slot in the current ECS world,
/// or `None` for an empty slot.
///
/// # Example
/// ```moonbit nocheck
/// inspect(quick_slot_content(SLOT_4), content="None")
/// ```
pub fn quick_slot_content(slot : QuickSlotId) -> QuickSlotContent? {
  current_world_runtime().quick_slots.get(slot)
}

///|
/// Adds or removes a named modal owner that suppresses Gameplay action queries
/// in the current ECS world. Owners compose, so closing one panel cannot
/// re-enable gameplay while another modal panel remains active.
///
/// # Example
/// ```moonbit nocheck
/// set_gameplay_input_suppressed("inventory", true)
/// set_gameplay_input_suppressed("inventory", false)
/// ```
pub fn set_gameplay_input_suppressed(owner : String, suppressed : Bool) -> Unit {
  let suppressors = current_world_runtime().gameplay_suppressors
  if suppressed {
    suppressors.add(owner)
  } else {
    suppressors.remove(owner)
  }
}

///|
/// Returns whether Gameplay actions are allowed through the current ECS world's
/// query boundary.
///
/// # Example
/// ```moonbit nocheck
/// inspect(gameplay_input_enabled(), content="true")
/// ```
pub fn gameplay_input_enabled() -> Bool {
  current_world_runtime().gameplay_suppressors.is_empty()
}

///|
/// Returns the current ECS world's most recently used meaningful input method.
/// All physical action bindings remain live regardless of this value.
///
/// # Example
/// ```moonbit nocheck
/// debug_inspect(active_input_method())
/// ```
pub fn active_input_method() -> InputMethod {
  current_world_runtime().active_input_method
}

///|
/// Returns the current ECS world's most recently used gamepad, or `None` when
/// keyboard/mouse or touch is currently active.
///
/// # Example
/// ```moonbit nocheck
/// debug_inspect(active_gamepad())
/// ```
pub fn active_gamepad() -> @inputs.Gamepad? {
  match active_input_method() {
    Gamepad(gamepad) => Some(gamepad)
    KeyboardMouse | Touch => None
  }
}

///|
/// Updates the supplied ECS world's most recently used meaningful input method
/// once per frame.
/// Keyboard presses, mouse clicks/wheel/movement, gamepad button presses, and
/// touch changes switch immediately. A stick must first return within `0.25`
/// before crossing `0.55`, preventing held or drifting sticks from stealing the
/// active method after keyboard input. Active touches suppress browser-generated
/// compatibility mouse activity while still allowing a real key or button press
/// to take over.
///
/// # Example
/// ```moonbit nocheck
/// input_method_system(@ecs.require_current_world())
/// ```
pub fn input_method_system(world : @ecs.World) -> Unit {
  let runtime = world_runtime(world)
  let touch_activity = !@inputs.touch_changes_this_frame().is_empty()
  let has_touch_compat = !@inputs.active_touches().is_empty() || touch_activity
  let mut keyboard_mouse_activity = false
  for code in @inputs.pressed_keys {
    if @inputs.is_just_pressed(code) {
      keyboard_mouse_activity = true
    }
  }
  let mouse_delta = @inputs.mouse_movement.movement
  let mouse_distance_squared = mouse_delta[@selene_math.X] *
    mouse_delta[@selene_math.X] +
    mouse_delta[@selene_math.Y] * mouse_delta[@selene_math.Y]
  let wheel_activity = !@inputs.mouse_wheel_event_bus
    .read(runtime.mouse_wheel_reader)
    .is_empty()
  if has_touch_compat {
    runtime.accumulated_mouse_travel = 0.0
  } else {
    if mouse_distance_squared > 0.0 {
      runtime.accumulated_mouse_travel += mouse_distance_squared.sqrt()
    } else {
      runtime.accumulated_mouse_travel = 0.0
    }
    keyboard_mouse_activity = keyboard_mouse_activity ||
      @inputs.is_mouse_just_pressed(@inputs.MouseButton::Left) ||
      @inputs.is_mouse_just_pressed(@inputs.MouseButton::Right) ||
      @inputs.is_mouse_just_pressed(@inputs.MouseButton::Middle) ||
      runtime.accumulated_mouse_travel >= MOUSE_ACTIVATION_DISTANCE ||
      wheel_activity
  }

  let mut gamepad_activity : @inputs.Gamepad? = None
  for input in @inputs.just_pressed_gamepad_buttons() {
    if !@inputs.connected_gamepads().contains(input.gamepad) {
      continue
    }
    match gamepad_activity {
      Some(current) if current.id() <= input.gamepad.id() => ()
      _ => gamepad_activity = Some(input.gamepad)
    }
  }
  let stale_axes = []
  for input in runtime.armed_gamepad_axes {
    if !@inputs.connected_gamepads().contains(input.gamepad) {
      stale_axes.push(input)
    }
  }
  for input in stale_axes {
    runtime.armed_gamepad_axes.remove(input)
  }
  for input, value in @inputs.gamepad_axis_values() {
    let is_stick = match input.axis {
      LeftStickX | LeftStickY | RightStickX | RightStickY => true
      LeftZ | RightZ => false
    }
    if !is_stick {
      continue
    }
    let magnitude = value.abs()
    if magnitude <= GAMEPAD_AXIS_ARM_THRESHOLD {
      runtime.armed_gamepad_axes.add(input)
    } else if magnitude >= GAMEPAD_AXIS_ACTIVATION_THRESHOLD &&
      runtime.armed_gamepad_axes.contains(input) {
      runtime.armed_gamepad_axes.remove(input)
      match gamepad_activity {
        Some(current) if current.id() <= input.gamepad.id() => ()
        _ => gamepad_activity = Some(input.gamepad)
      }
    }
  }

  let previous_method = runtime.active_input_method
  let mut next_method = match previous_method {
    Gamepad(gamepad) if !@inputs.connected_gamepads().contains(gamepad) =>
      KeyboardMouse
    _ => previous_method
  }
  if keyboard_mouse_activity {
    next_method = KeyboardMouse
  }
  if gamepad_activity is Some(gamepad) {
    next_method = Gamepad(gamepad)
  }
  if touch_activity {
    next_method = Touch
  }
  if next_method != previous_method {
    runtime.active_input_method = next_method
    runtime.accumulated_mouse_travel = 0.0
    input_method_changed_event_bus.send({
      previous: previous_method,
      current: next_method,
    })
  }
}

///|
/// Returns all distinct logical actions that became pressed this frame under the
/// current map and Gameplay/UI context.
///
/// # Example
/// ```moonbit nocheck
/// let actions = just_pressed_actions()
/// ```
pub fn just_pressed_actions() -> Array[Action] {
  just_pressed_actions_in(get_keymap().unwrap_or(Map([])))
}

///|
/// Returns all distinct logical actions currently held under the current map
/// and Gameplay/UI context.
///
/// # Example
/// ```moonbit nocheck
/// let actions = pressed_actions()
/// ```
pub fn pressed_actions() -> Array[Action] {
  pressed_actions_in(get_keymap().unwrap_or(Map([])))
}

///|
/// Returns actions in `mapping` that became pressed this frame. The mapping must
/// have been installed with `set_keymap` so Selene owns their runtime states.
///
/// # Example
/// ```moonbit nocheck
/// let actions = just_pressed_actions_in(Map([]))
/// ```
pub fn just_pressed_actions_in(mapping : Keymap) -> Array[Action] {
  collect_actions_in(mapping, @input_action.action_just_pressed)
}

///|
/// Returns actions in `mapping` that are currently held. The mapping must have
/// been installed with `set_keymap` so Selene owns their runtime states.
///
/// # Example
/// ```moonbit nocheck
/// let actions = pressed_actions_in(Map([]))
/// ```
pub fn pressed_actions_in(mapping : Keymap) -> Array[Action] {
  collect_actions_in(mapping, @input_action.action_pressed)
}

///|
/// Checks whether one logical action is held in the current map. Gameplay
/// actions return `false` while any modal owner suppresses Gameplay input.
///
/// # Example
/// ```moonbit nocheck
/// inspect(is_pressed(BASIC(JUMP)), content="false")
/// ```
pub fn is_pressed(action : Action) -> Bool {
  is_pressed_in(get_keymap().unwrap_or(Map([])), action)
}

///|
/// Checks whether one logical action became pressed this frame in the current
/// map. Gameplay actions return `false` while a modal owner is active.
///
/// # Example
/// ```moonbit nocheck
/// inspect(is_just_pressed(UI(CANCEL)), content="false")
/// ```
pub fn is_just_pressed(action : Action) -> Bool {
  is_just_pressed_in(get_keymap().unwrap_or(Map([])), action)
}

///|
/// Checks a held logical action against an explicitly supplied installed map.
///
/// # Example
/// ```moonbit nocheck
/// inspect(is_pressed_in(Map([]), BASIC(JUMP)), content="false")
/// ```
pub fn is_pressed_in(mapping : Keymap, action : Action) -> Bool {
  mapping.contains(action) &&
  (!is_gameplay_action(action) || gameplay_input_enabled()) &&
  @input_action.action_pressed(input_action_for(action))
}

///|
/// Checks a newly pressed logical action against an explicitly supplied
/// installed map.
///
/// # Example
/// ```moonbit nocheck
/// inspect(is_just_pressed_in(Map([]), BASIC(JUMP)), content="false")
/// ```
pub fn is_just_pressed_in(mapping : Keymap, action : Action) -> Bool {
  mapping.contains(action) &&
  (!is_gameplay_action(action) || gameplay_input_enabled()) &&
  @input_action.action_just_pressed(input_action_for(action))
}

///|
fn collect_actions_in(
  mapping : Keymap,
  is_triggered : (@input_action.InputAction) -> Bool,
) -> Array[Action] {
  let actions = []
  for action, _ in mapping {
    if (!is_gameplay_action(action) || gameplay_input_enabled()) &&
      is_triggered(input_action_for(action)) {
      actions.push(action)
    }
  }
  actions
}
