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
  selene_animations : Map[ButtonState, @sprite.Animation]
  dimensions : Point[Int]
}

///|
fn parse_button_animation(
  src : Json,
  path : @json.JsonPath,
) -> (@resource.NxAnimation, @sprite.Animation) raise @json.JsonDecodeError {
  let nx : @resource.NxAnimation = @json.from_json(src, path~)
  let selene = @resource.nx_animation_to_selene_animation(nx)
  (nx, selene)
}

///|
pub impl @json.FromJson for MapleButtonResource with from_json(
  src : Json,
  path : @json.JsonPath,
) -> MapleButtonResource raise {
  guard src
    is {
      "normal": normal,
      "pressed": pressed,
      "mouseOver": mouse_over,
      "disabled": disabled,
      ..
    } else {
    raise @json.JsonDecodeError((path, "expect maple button resource object"))
  }
  let selene_animations : Map[ButtonState, @sprite.Animation] = {}
  let states = [
    (ButtonState::NORMAL, normal, "normal"),
    (ButtonState::PRESSED, pressed, "pressed"),
    (ButtonState::MOUSEOVER, mouse_over, "mouseOver"),
    (ButtonState::DISABLED, disabled, "disabled"),
  ]
  let mut width = 0
  let mut height = 0
  for item in states {
    let (state, value, key) = item
    let (nx, selene) = parse_button_animation(value, path.add_key(key))
    if state == ButtonState::NORMAL {
      let (w, h) = nx.get_size()
      width = w
      height = h
    }
    selene_animations[state] = selene
  }
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
) -> @sprite.Animation {
  self.resource.selene_animations.get(self.current_state()).unwrap()
}
