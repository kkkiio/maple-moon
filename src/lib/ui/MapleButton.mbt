///|
/// A parsed MapleStory button resource with four visual states.
pub(all) struct NxMapleButton {
  /// Visual for the normal state.
  normal : @resource.NxAnimation
  /// Visual for the hover state.
  mouse_over : @resource.NxAnimation
  /// Visual for the pressed state.
  pressed : @resource.NxAnimation
  /// Visual for the disabled state.
  disabled : @resource.NxAnimation
}

///|
pub impl @json.FromJson for NxMapleButton with from_json(
  src : Json,
  path : @json.JsonPath,
) -> NxMapleButton {
  guard src
    is {
      "normal": normal,
      "mouseOver": mouse_over,
      "pressed": pressed,
      "disabled": disabled,
      ..
    } else {
    raise @json.JsonDecodeError((path, "expect maple button resource object"))
  }
  {
    normal: @json.from_json(normal, path=path.add_key("normal")),
    mouse_over: @json.from_json(mouse_over, path=path.add_key("mouseOver")),
    pressed: @json.from_json(pressed, path=path.add_key("pressed")),
    disabled: @json.from_json(disabled, path=path.add_key("disabled")),
  }
}

///|
/// Parsed MapleStory button visuals for selene-based UIs.
pub(all) struct MapleButtonResource {
  selene_animations : Map[ButtonState, @ms_animation.Animation]
  dimensions : Point[Int]
}

///|
/// Build a runtime button resource from parsed nx button data.
pub fn MapleButtonResource::from_nx(src : NxMapleButton) -> MapleButtonResource {
  let selene_animations : Map[ButtonState, @ms_animation.Animation] = {}
  let states : Array[(ButtonState, @resource.NxAnimation)] = [
    (ButtonState::NORMAL, src.normal),
    (ButtonState::PRESSED, src.pressed),
    (ButtonState::MOUSEOVER, src.mouse_over),
    (ButtonState::DISABLED, src.disabled),
  ]
  for item in states {
    let (state, animation) = item
    selene_animations[state] = @ms_animation.from_nx_animation(animation)
  }
  let (width, height) = src.normal.get_size()
  { selene_animations, dimensions: { x: width, y: height } }
}

///|
/// A headless MapleStory button model for selene scene UIs.
pub(all) struct MapleButton {
  pos : Point[Int]
  resource : MapleButtonResource
  on_click : () -> Unit
  mut state : ButtonState
  mut enabled : Bool
  mut pressed : Bool
}

///|
fn MapleButton::current_state(self : MapleButton) -> ButtonState {
  if self.enabled {
    self.state
  } else {
    ButtonState::DISABLED
  }
}

///|
fn MapleButton::update_visual_state(
  self : MapleButton,
  hovered : Bool,
  is_pressed : Bool,
) -> Unit {
  self.state = if not(self.enabled) {
    ButtonState::DISABLED
  } else if self.pressed && is_pressed && hovered {
    ButtonState::PRESSED
  } else if hovered {
    ButtonState::MOUSEOVER
  } else {
    ButtonState::NORMAL
  }
}

///|
pub fn MapleButton::new(
  res : MapleButtonResource,
  pos? : Point[Int] = @struct.Point::default(),
  on_click? : () -> Unit = fn() { () },
) -> MapleButton {
  {
    pos,
    resource: res,
    on_click,
    state: ButtonState::NORMAL,
    enabled: true,
    pressed: false,
  }
}

///|
pub fn MapleButton::set_enabled(self : MapleButton, enabled : Bool) -> Unit {
  self.enabled = enabled
  if not(enabled) {
    self.pressed = false
    self.state = ButtonState::DISABLED
  } else {
    self.state = ButtonState::NORMAL
  }
}

///|
pub fn MapleButton::contains(self : MapleButton, x : Int, y : Int) -> Bool {
  x >= self.pos.x &&
  x <= self.pos.x + self.resource.dimensions.x &&
  y >= self.pos.y &&
  y <= self.pos.y + self.resource.dimensions.y
}

///|
/// Update pointer state for a selene-driven scene.
pub fn MapleButton::update_pointer(
  self : MapleButton,
  x : Int,
  y : Int,
  is_pressed : Bool,
  just_pressed : Bool,
  just_released : Bool,
) -> Unit {
  let hovered = self.contains(x, y)
  if not(self.enabled) {
    self.pressed = false
    self.state = ButtonState::DISABLED
    return
  }
  if just_pressed && hovered {
    self.pressed = true
  }
  if just_released {
    let should_click = self.pressed && hovered
    self.pressed = false
    if should_click {
      (self.on_click)()
    }
  }
  self.update_visual_state(hovered, is_pressed)
}

///|
/// Returns the selene animation for the current visual state.
pub fn MapleButton::current_selene_animation(
  self : MapleButton,
) -> @ms_animation.Animation {
  self.resource.selene_animations.get(self.current_state()).unwrap()
}
