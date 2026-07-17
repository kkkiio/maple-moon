///|
test "default gamepad buttons cover gameplay quick slots and UI actions" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  let mapping = @keymap.default_keymap()
  assert_eq(mapping.length(), 17)
  @keymap.set_keymap(mapping)
  let gamepad = @inputs.Gamepad(9)
  let cases : Array[(@inputs.GamepadButton, Array[@keymap.Action])] = [
    (
      @inputs.GamepadButton::DPadUp,
      [@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP)],
    ),
    (
      @inputs.GamepadButton::DPadDown,
      [@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_DOWN)],
    ),
    (
      @inputs.GamepadButton::DPadLeft,
      [@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_LEFT)],
    ),
    (
      @inputs.GamepadButton::DPadRight,
      [@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_RIGHT)],
    ),
    (
      @inputs.GamepadButton::South,
      [@keymap.Action::BASIC(@keymap.BasicActionId::JUMP)],
    ),
    (
      @inputs.GamepadButton::West,
      [@keymap.Action::BASIC(@keymap.BasicActionId::ATTACK)],
    ),
    (
      @inputs.GamepadButton::North,
      [@keymap.Action::BASIC(@keymap.BasicActionId::INTERACT)],
    ),
    (
      @inputs.GamepadButton::LeftTrigger,
      [
        @keymap.Action::QUICK_SLOT(@keymap.QuickSlotId::SLOT_1),
        @keymap.Action::UI(@keymap.UiActionId::PREVIOUS_TAB),
      ],
    ),
    (
      @inputs.GamepadButton::RightTrigger,
      [
        @keymap.Action::QUICK_SLOT(@keymap.QuickSlotId::SLOT_2),
        @keymap.Action::UI(@keymap.UiActionId::NEXT_TAB),
      ],
    ),
    (
      @inputs.GamepadButton::LeftTrigger2,
      [@keymap.Action::QUICK_SLOT(@keymap.QuickSlotId::SLOT_3)],
    ),
    (
      @inputs.GamepadButton::RightTrigger2,
      [@keymap.Action::QUICK_SLOT(@keymap.QuickSlotId::SLOT_4)],
    ),
    (
      @inputs.GamepadButton::East,
      [@keymap.Action::UI(@keymap.UiActionId::CANCEL)],
    ),
    (
      @inputs.GamepadButton::Start,
      [@keymap.Action::UI(@keymap.UiActionId::TOGGLE_INVENTORY)],
    ),
    (
      @inputs.GamepadButton::Select,
      [@keymap.Action::UI(@keymap.UiActionId::TOGGLE_WORLD_MAP)],
    ),
    (
      @inputs.GamepadButton::RightThumb,
      [@keymap.Action::UI(@keymap.UiActionId::TOGGLE_QUEST_LOG)],
    ),
  ]
  for case in cases {
    let (button, expected_actions) = case
    let neutral = @inputs.empty_input_snapshot()
    neutral.connected_gamepads.add(gamepad)
    @inputs.apply_input_snapshot(neutral)
    @inputs.advanced_gamepad_system(0.0)
    @input_action.input_action_system(0.0)

    let pressed = @inputs.empty_input_snapshot()
    pressed.connected_gamepads.add(gamepad)
    pressed.pressed_gamepad_buttons.add(
      @inputs.GamepadButtonInput(gamepad, button),
    )
    @inputs.apply_input_snapshot(pressed)
    @inputs.advanced_gamepad_system(0.0)
    @input_action.input_action_system(0.0)
    let actual_actions = @keymap.just_pressed_actions()
    assert_eq(actual_actions.length(), expected_actions.length())
    for action in expected_actions {
      assert_true(actual_actions.contains(action))
      assert_true(@keymap.is_pressed(action))
      assert_true(@keymap.is_just_pressed(action))
    }
  }
  let neutral = @inputs.empty_input_snapshot()
  neutral.connected_gamepads.add(gamepad)
  @inputs.apply_input_snapshot(neutral)
  @inputs.advanced_gamepad_system(0.0)
  @input_action.input_action_system(0.0)
  @keymap.set_keymap(Map([]))
}

///|
test "default left stick covers four directions and respects its dead zone" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  @keymap.set_keymap(@keymap.default_keymap())
  let gamepad = @inputs.Gamepad(11)
  let cases : Array[(@inputs.GamepadAxis, Double, @keymap.Action)] = [
    (
      @inputs.GamepadAxis::LeftStickY,
      -0.7,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP),
    ),
    (
      @inputs.GamepadAxis::LeftStickY,
      0.7,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_DOWN),
    ),
    (
      @inputs.GamepadAxis::LeftStickX,
      -0.7,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_LEFT),
    ),
    (
      @inputs.GamepadAxis::LeftStickX,
      0.7,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_RIGHT),
    ),
  ]
  for case in cases {
    let (axis, value, expected_action) = case
    let neutral = @inputs.empty_input_snapshot()
    neutral.connected_gamepads.add(gamepad)
    @inputs.apply_input_snapshot(neutral)
    @inputs.advanced_gamepad_system(0.0)
    @input_action.input_action_system(0.0)

    let deflected = @inputs.empty_input_snapshot()
    deflected.connected_gamepads.add(gamepad)
    deflected.gamepad_axis_values.set(
      @inputs.GamepadAxisInput(gamepad, axis),
      value,
    )
    @inputs.apply_input_snapshot(deflected)
    @inputs.advanced_gamepad_system(0.0)
    @input_action.input_action_system(0.0)
    let actual_actions = @keymap.just_pressed_actions()
    assert_eq(actual_actions.length(), 1)
    assert_true(actual_actions.contains(expected_action))
    assert_true(@keymap.is_pressed(expected_action))
  }
  let inside_dead_zone = @inputs.empty_input_snapshot()
  inside_dead_zone.connected_gamepads.add(gamepad)
  inside_dead_zone.gamepad_axis_values.set(
    @inputs.GamepadAxisInput(gamepad, @inputs.GamepadAxis::LeftStickX),
    0.19,
  )
  inside_dead_zone.gamepad_axis_values.set(
    @inputs.GamepadAxisInput(gamepad, @inputs.GamepadAxis::LeftStickY),
    -0.19,
  )
  @inputs.apply_input_snapshot(inside_dead_zone)
  @inputs.advanced_gamepad_system(0.0)
  @input_action.input_action_system(0.0)
  assert_true(@keymap.just_pressed_actions().is_empty())
  assert_false(
    @keymap.is_pressed(@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_RIGHT)),
  )
  assert_false(
    @keymap.is_pressed(@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP)),
  )
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_gamepad_system(0.0)
  @input_action.input_action_system(0.0)
  @keymap.set_keymap(Map([]))
}

///|
test "gameplay context composes while UI actions and any gamepad stay live" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  let jump = @keymap.Action::BASIC(@keymap.BasicActionId::JUMP)
  let cancel = @keymap.Action::UI(@keymap.UiActionId::CANCEL)
  let mapping : @keymap.Keymap = Map([
    (
      jump,
      [
        @input_action.InputBinding::Key(@inputs.Code::Space),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::South,
        ),
      ],
    ),
    (
      cancel,
      [
        @input_action.InputBinding::Key(@inputs.Code::Escape),
        @input_action.InputBinding::AnyGamepadButton(
          @inputs.GamepadButton::East,
        ),
      ],
    ),
  ])
  @keymap.set_keymap(mapping)
  let gamepad = @inputs.Gamepad(7)
  let snapshot = @inputs.empty_input_snapshot()
  snapshot.connected_gamepads.add(gamepad)
  snapshot.pressed_gamepad_buttons.add(
    @inputs.GamepadButtonInput(gamepad, @inputs.GamepadButton::South),
  )
  snapshot.pressed_gamepad_buttons.add(
    @inputs.GamepadButtonInput(gamepad, @inputs.GamepadButton::East),
  )
  @inputs.apply_input_snapshot(snapshot)
  @inputs.advanced_gamepad_system(0.0)
  @input_action.input_action_system(0.0)

  assert_true(@keymap.is_pressed(jump))
  assert_true(@keymap.is_just_pressed(jump))
  assert_true(@keymap.is_pressed(cancel))
  @keymap.set_gameplay_input_suppressed("inventory", true)
  @keymap.set_gameplay_input_suppressed("npc_talk", true)
  assert_false(@keymap.is_pressed(jump))
  assert_true(@keymap.is_pressed(cancel))
  @keymap.set_gameplay_input_suppressed("inventory", false)
  assert_false(@keymap.gameplay_input_enabled())
  @keymap.set_gameplay_input_suppressed("npc_talk", false)
  assert_true(@keymap.gameplay_input_enabled())
  assert_true(@keymap.is_pressed(jump))

  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_gamepad_system(0.0)
  @input_action.input_action_system(0.0)
  @keymap.set_keymap(Map([]))
}

///|
test "quick slots keep content independent from physical bindings" {
  @keymap.set_quick_slots(
    Map([
      (@keymap.QuickSlotId::SLOT_1, @keymap.QuickSlotContent::Skill(3101005)),
      (@keymap.QuickSlotId::SLOT_3, @keymap.QuickSlotContent::Item(2000000)),
    ]),
  )
  assert_eq(
    @keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_1),
    Some(@keymap.QuickSlotContent::Skill(3101005)),
  )
  assert_true(@keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_2) is None)
  assert_eq(
    @keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_3),
    Some(@keymap.QuickSlotContent::Item(2000000)),
  )
  @keymap.set_quick_slots(Map([]))
}

///|
test "input method switches by meaningful last input without stick stealing" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  let reader : @event.EventReader[@keymap.InputMethodChangedEvent] = @event.EventReader()
  let empty = @inputs.empty_input_snapshot()
  @inputs.apply_input_snapshot(empty)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  let keyboard = @inputs.empty_input_snapshot()
  keyboard.pressed_keys.add(@inputs.Code::KeyR)
  @inputs.apply_input_snapshot(keyboard)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  @keymap.input_method_changed_event_bus.read(reader) |> ignore

  let gamepad = @inputs.Gamepad(42)
  let axis = @inputs.GamepadAxisInput(gamepad, @inputs.GamepadAxis::LeftStickX)
  let unarmed = @inputs.empty_input_snapshot()
  unarmed.connected_gamepads.add(gamepad)
  unarmed.gamepad_axis_values.set(axis, 0.8)
  @inputs.apply_input_snapshot(unarmed)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  let neutral = @inputs.empty_input_snapshot()
  neutral.connected_gamepads.add(gamepad)
  neutral.gamepad_axis_values.set(axis, 0.0)
  @inputs.apply_input_snapshot(neutral)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  let deflected = @inputs.empty_input_snapshot()
  deflected.connected_gamepads.add(gamepad)
  deflected.gamepad_axis_values.set(axis, 0.7)
  @inputs.apply_input_snapshot(deflected)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )

  let held_with_keyboard = @inputs.empty_input_snapshot()
  held_with_keyboard.connected_gamepads.add(gamepad)
  held_with_keyboard.gamepad_axis_values.set(axis, 0.7)
  held_with_keyboard.pressed_keys.add(@inputs.Code::KeyY)
  @inputs.apply_input_snapshot(held_with_keyboard)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  @inputs.apply_input_snapshot(deflected)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  @inputs.apply_input_snapshot(neutral)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  @inputs.apply_input_snapshot(deflected)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)

  let gamepad_button = @inputs.empty_input_snapshot()
  gamepad_button.connected_gamepads.add(gamepad)
  gamepad_button.pressed_gamepad_buttons.add(
    @inputs.GamepadButtonInput(gamepad, @inputs.GamepadButton::North),
  )
  @inputs.apply_input_snapshot(gamepad_button)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  for x in 1..<5 {
    let jitter = @inputs.empty_input_snapshot()
    jitter.connected_gamepads.add(gamepad)
    jitter.mouse.pos = @selene_math.Vec2(x.to_double(), 0.0)
    @inputs.apply_input_snapshot(jitter)
    @inputs.advanced_key_system(0.0)
    @inputs.advanced_mouse_system(0.0)
    @inputs.advanced_touch_system(0.0)
    @inputs.advanced_gamepad_system(0.0)
    @keymap.input_method_system(world)
    assert_eq(
      @keymap.active_input_method(),
      @keymap.InputMethod::Gamepad(gamepad),
    )
    @inputs.apply_input_snapshot(jitter)
    @inputs.advanced_key_system(0.0)
    @inputs.advanced_mouse_system(0.0)
    @inputs.advanced_touch_system(0.0)
    @inputs.advanced_gamepad_system(0.0)
    @keymap.input_method_system(world)
    assert_eq(
      @keymap.active_input_method(),
      @keymap.InputMethod::Gamepad(gamepad),
    )
  }

  let touch_id = @inputs.TouchId(9)
  let touch_started = @inputs.empty_input_snapshot()
  touch_started.touches.set(touch_id, {
    id: touch_id,
    position: @selene_math.Vec2(30.0, 40.0),
    previous_position: @selene_math.Vec2(30.0, 40.0),
    delta: @selene_math.Vec2::zero(),
    primary: true,
  })
  touch_started.touch_changes.push({
    id: touch_id,
    phase: @inputs.TouchPhase::Started,
    position: @selene_math.Vec2(30.0, 40.0),
    previous_position: @selene_math.Vec2(30.0, 40.0),
    delta: @selene_math.Vec2::zero(),
    primary: true,
  })
  @inputs.apply_input_snapshot(touch_started)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::Touch)
  let static_touch_with_gamepad = @inputs.empty_input_snapshot()
  static_touch_with_gamepad.touches.set(touch_id, {
    id: touch_id,
    position: @selene_math.Vec2(30.0, 40.0),
    previous_position: @selene_math.Vec2(30.0, 40.0),
    delta: @selene_math.Vec2::zero(),
    primary: true,
  })
  static_touch_with_gamepad.connected_gamepads.add(gamepad)
  static_touch_with_gamepad.pressed_gamepad_buttons.add(
    @inputs.GamepadButtonInput(gamepad, @inputs.GamepadButton::North),
  )
  @inputs.apply_input_snapshot(static_touch_with_gamepad)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  let touch_moved = @inputs.empty_input_snapshot()
  touch_moved.touches.set(touch_id, {
    id: touch_id,
    position: @selene_math.Vec2(34.0, 40.0),
    previous_position: @selene_math.Vec2(30.0, 40.0),
    delta: @selene_math.Vec2(4.0, 0.0),
    primary: true,
  })
  touch_moved.touch_changes.push({
    id: touch_id,
    phase: @inputs.TouchPhase::Moved,
    position: @selene_math.Vec2(34.0, 40.0),
    previous_position: @selene_math.Vec2(30.0, 40.0),
    delta: @selene_math.Vec2(4.0, 0.0),
    primary: true,
  })
  @inputs.apply_input_snapshot(touch_moved)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::Touch)
  let touch_ended = @inputs.empty_input_snapshot()
  touch_ended.touch_changes.push({
    id: touch_id,
    phase: @inputs.TouchPhase::Ended,
    position: @selene_math.Vec2(34.0, 40.0),
    previous_position: @selene_math.Vec2(34.0, 40.0),
    delta: @selene_math.Vec2::zero(),
    primary: true,
  })
  @inputs.apply_input_snapshot(touch_ended)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::Touch)

  for x in 35..<39 {
    let mouse = @inputs.empty_input_snapshot()
    mouse.mouse.pos = @selene_math.Vec2(x.to_double(), 40.0)
    @inputs.apply_input_snapshot(mouse)
    @inputs.advanced_key_system(0.0)
    @inputs.advanced_mouse_system(0.0)
    @inputs.advanced_touch_system(0.0)
    @inputs.advanced_gamepad_system(0.0)
    @keymap.input_method_system(world)
    if x < 38 {
      assert_eq(@keymap.active_input_method(), @keymap.InputMethod::Touch)
    }
  }
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  let changes = @keymap.input_method_changed_event_bus.read(reader)
  assert_true(changes.length() >= 6)
  assert_eq(changes[0].current, @keymap.InputMethod::Gamepad(gamepad))
  assert_eq(
    changes[changes.length() - 1].current,
    @keymap.InputMethod::KeyboardMouse,
  )
}

///|
test "runtime state and physical bindings are isolated per ECS world" {
  let previous_world = @ecs.current_world()
  let world_a = @ecs.World()
  let world_b = @ecs.World()
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  let jump = @keymap.Action::BASIC(@keymap.BasicActionId::JUMP)
  let mapping_a : @keymap.Keymap = Map([
    (jump, [@input_action.InputBinding::Key(@inputs.Code::KeyA)]),
  ])
  let mapping_b : @keymap.Keymap = Map([
    (jump, [@input_action.InputBinding::Key(@inputs.Code::KeyB)]),
  ])

  @ecs.set_current_world(world_a)
  @keymap.set_keymap(mapping_a)
  @keymap.set_quick_slots(
    Map([
      (@keymap.QuickSlotId::SLOT_1, @keymap.QuickSlotContent::Skill(3101005)),
    ]),
  )
  @keymap.set_gameplay_input_suppressed("inventory", true)
  let bindings_a = @keymap.get_bindings(@keymap.get_keymap().unwrap(), jump)
  assert_eq(bindings_a.length(), 1)
  assert_true(
    bindings_a[0] is @input_action.InputBinding::Key(@inputs.Code::KeyA),
  )
  assert_eq(
    @keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_1),
    Some(@keymap.QuickSlotContent::Skill(3101005)),
  )
  assert_false(@keymap.gameplay_input_enabled())

  @ecs.set_current_world(world_b)
  assert_true(@keymap.get_keymap() is None)
  assert_true(@keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_1) is None)
  assert_true(@keymap.gameplay_input_enabled())
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  @keymap.set_keymap(mapping_b)
  @keymap.set_quick_slots(
    Map([(@keymap.QuickSlotId::SLOT_1, @keymap.QuickSlotContent::Item(2000000))]),
  )

  let key_a = @inputs.empty_input_snapshot()
  key_a.pressed_keys.add(@inputs.Code::KeyA)
  @inputs.apply_input_snapshot(key_a)
  @inputs.advanced_key_system(0.0)
  @input_action.input_action_system(0.0)
  assert_false(@keymap.is_pressed(jump))
  let key_b = @inputs.empty_input_snapshot()
  key_b.pressed_keys.add(@inputs.Code::KeyB)
  @inputs.apply_input_snapshot(key_b)
  @inputs.advanced_key_system(0.0)
  @input_action.input_action_system(0.0)
  assert_true(@keymap.is_pressed(jump))

  @ecs.set_current_world(world_a)
  @inputs.apply_input_snapshot(key_b)
  @inputs.advanced_key_system(0.0)
  @input_action.input_action_system(0.0)
  assert_false(@keymap.is_pressed(jump))
  @inputs.apply_input_snapshot(key_a)
  @inputs.advanced_key_system(0.0)
  @input_action.input_action_system(0.0)
  assert_false(@keymap.is_pressed(jump))
  @keymap.set_gameplay_input_suppressed("inventory", false)
  assert_true(@keymap.is_pressed(jump))
  assert_eq(
    @keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_1),
    Some(@keymap.QuickSlotContent::Skill(3101005)),
  )
  @ecs.set_current_world(world_b)
  assert_eq(
    @keymap.quick_slot_content(@keymap.QuickSlotId::SLOT_1),
    Some(@keymap.QuickSlotContent::Item(2000000)),
  )

  let reader : @event.EventReader[@keymap.InputMethodChangedEvent] = @event.EventReader()
  let gamepad = @inputs.Gamepad(73)
  let axis = @inputs.GamepadAxisInput(gamepad, @inputs.GamepadAxis::LeftStickX)
  @ecs.set_current_world(world_a)
  let neutral_a = @inputs.empty_input_snapshot()
  neutral_a.connected_gamepads.add(gamepad)
  neutral_a.gamepad_axis_values.set(axis, 0.0)
  @inputs.apply_input_snapshot(neutral_a)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_a)

  @ecs.set_current_world(world_b)
  let deflected_b = @inputs.empty_input_snapshot()
  deflected_b.connected_gamepads.add(gamepad)
  deflected_b.gamepad_axis_values.set(axis, 0.8)
  @inputs.apply_input_snapshot(deflected_b)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_b)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)
  assert_true(@keymap.input_method_changed_event_bus.read(reader).is_empty())

  @ecs.set_current_world(world_a)
  let deflected_a = @inputs.empty_input_snapshot()
  deflected_a.connected_gamepads.add(gamepad)
  deflected_a.gamepad_axis_values.set(axis, 0.8)
  @inputs.apply_input_snapshot(deflected_a)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_a)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  let world_a_changes = @keymap.input_method_changed_event_bus.read(reader)
  assert_eq(world_a_changes.length(), 1)
  assert_eq(world_a_changes[0].current, @keymap.InputMethod::Gamepad(gamepad))
  @inputs.mouse_movement.movement = @selene_math.Vec2(2.0, 0.0)
  @keymap.input_method_system(world_a)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )

  @ecs.set_current_world(world_b)
  let button_b = @inputs.empty_input_snapshot()
  button_b.connected_gamepads.add(gamepad)
  button_b.pressed_gamepad_buttons.add(
    @inputs.GamepadButtonInput(gamepad, @inputs.GamepadButton::North),
  )
  @inputs.apply_input_snapshot(button_b)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_b)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  let quiet_b = @inputs.empty_input_snapshot()
  quiet_b.connected_gamepads.add(gamepad)
  @inputs.apply_input_snapshot(quiet_b)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @inputs.mouse_movement.movement = @selene_math.Vec2(2.0, 0.0)
  @keymap.input_method_system(world_b)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )

  @ecs.set_current_world(world_a)
  @inputs.apply_input_snapshot(deflected_a)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @inputs.mouse_movement.movement = @selene_math.Vec2(2.0, 0.0)
  @keymap.input_method_system(world_a)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)

  let button_a = @inputs.empty_input_snapshot()
  button_a.connected_gamepads.add(gamepad)
  button_a.pressed_gamepad_buttons.add(
    @inputs.GamepadButtonInput(gamepad, @inputs.GamepadButton::North),
  )
  @inputs.apply_input_snapshot(button_a)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_a)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  let wheel_a = @inputs.empty_input_snapshot()
  wheel_a.connected_gamepads.add(gamepad)
  wheel_a.mouse_wheel.delta = @selene_math.Vec2(0.0, 1.0)
  @inputs.apply_input_snapshot(wheel_a)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_a)
  assert_eq(@keymap.active_input_method(), @keymap.InputMethod::KeyboardMouse)

  @ecs.set_current_world(world_b)
  @inputs.apply_input_snapshot(quiet_b)
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
  @keymap.input_method_system(world_b)
  assert_eq(
    @keymap.active_input_method(),
    @keymap.InputMethod::Gamepad(gamepad),
  )
  let world_b_changes = @keymap.input_method_changed_event_bus.read(reader)
  assert_eq(world_b_changes.length(), 1)
  assert_eq(world_b_changes[0].current, @keymap.InputMethod::Gamepad(gamepad))

  @ecs.set_current_world(world_a)
  @keymap.set_keymap(Map([]))
  @keymap.set_quick_slots(Map([]))
  @ecs.set_current_world(world_b)
  @keymap.set_keymap(Map([]))
  @keymap.set_quick_slots(Map([]))
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
  @inputs.advanced_touch_system(0.0)
  @inputs.advanced_gamepad_system(0.0)
}
