///|
/// A standard maplestory-button with 4 states and a texture for each state.
pub(all) struct MapleButton {
  // textures : Map[ButtonState, @graphics.Texture]
  // animations : Map[ButtonState, @graphics.Animation]
  entity : @system.Entity
}

///|
pub impl UIButton for MapleButton with get_button_base(self : MapleButton) -> ButtonModel {
  ...
}

///|
pub(all) struct MapleButtonResource(Map[ButtonState, @resource.NxAnimation])

///|
pub fn MapleButtonResource::from_resource(
  src : @resource.NxNode,
) -> MapleButtonResource {
  ...
}

///|
pub impl @json.FromJson for MapleButtonResource with from_json(
  src : Json,
  path : @json.JsonPath,
) -> MapleButtonResource {
  guard src
    is {
      "normal": { "0": normal0, .. } as normal,
      "pressed": { "0": pressed0, .. },
      "mouseOver": { "0": mouseOver0, .. },
      "disabled": { "0": disabled0, .. },
      ..
    } else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let animations = {}
  animations[ButtonState::NORMAL] = @json.from_json(
    normal,
    path=path.add_key("normal"),
  )
  animations[ButtonState::PRESSED] = @json.from_json(
    pressed0,
    path=path.add_key("pressed").add_key("0"),
  )
  animations[ButtonState::MOUSEOVER] = @json.from_json(
    mouseOver0,
    path=path.add_key("mouseOver").add_key("0"),
  )
  animations[ButtonState::DISABLED] = @json.from_json(
    disabled0,
    path=path.add_key("disabled").add_key("0"),
  )
  animations
}

// ///|

///|
pub fn MapleButton::from_resource(
  src : @resource.NxNode,
  pos? : Point[Int] = @struct.Point::default(),
) -> MapleButton {
  ...
  // let res = MapleButtonResource::from_resource(src)
  // MapleButton::new(res, pos~)
}

///|
pub fn MapleButton::new(
  res : MapleButtonResource,
  pos? : Point[Int] = @struct.Point::default(),
  on_click? : () -> Unit = fn() { () },
) -> MapleButton {
  let button = @system.Entity::new()
  @position.positions.set(
    button,
    @selene_math.Vec2D(pos.x.to_double(), pos.y.to_double()),
  )
  let animation = res.inner().get(ButtonState::NORMAL).unwrap()
  let sp = @graphics.AnimationData::from_nx_animation(animation).to_selene_sprite(
    z=@graphics.UI_ZINDEX,
  )
  @sprite.sprites.set(button, sp)
  @collision.shapes.set(
    button,
    @collision.CollisionShape::Rect(
      size=@selene_math.Vec2D(21.0, 22.0),
      offset=@selene_math.Vec2D::zero(),
    ),
  )
  let pickable = @collision.Pickable::new()
  pickable.on_just_released(fn(mouse_button) {
    if mouse_button == Left {
      on_click()
    }
  })
  @collision.pickables.set(button, pickable)
  @ui.uis.set(button, @ui.Ui::new())
  { entity: button }
}

// ///|
// pub fn MapleButton::from_resource_with_x_y(
//   src : @resource.NxNode,
//   x : Int,
//   y : Int,
// ) -> MapleButton {
//   MapleButton::from_resource(src, pos=Point::new(x, y))
// }

///|
pub impl UIButton for MapleButton with draw(
  self : MapleButton,
  parentpos : Point[Int],
) -> Unit {
  ...
}

///|
pub impl UIButton for MapleButton with update(self : MapleButton) -> Unit {
  // if self.base.active {
  //   match self.animations.get(self.base.get_state()) {
  //     Some(animation) => animation.update(timestep=6) |> ignore
  //     None => ()
  //   }
  // }
}

///|
pub impl UIButton for MapleButton with bounds(self : MapleButton) -> @struct.Rectangle[
  Int,
] {
  // let (origin, dimensions) = match self.textures.get(self.base.get_state()) {
  //   Some(texture) => (texture.get_origin(), texture.get_dimensions())
  //   None => {
  //     let animation = self.animations.get(self.base.get_state()).unwrap()
  //     (animation.get_origin(), animation.get_dimensions())
  //   }
  // }
  // let lt = self.base.position - origin
  // let rb = lt + dimensions
  // @struct.Rectangle::new(lt, rb)
  ...
}

///|
pub impl UIButton for MapleButton with width(self : MapleButton) -> Int {
  // match self.textures.get(self.base.get_state()) {
  //   Some(texture) => texture.width()
  //   None => 0
  // }
  ...
}

///|
pub impl UIButton for MapleButton with origin(self : MapleButton) -> Point[Int] {
  // match self.textures.get(self.base.get_state()) {
  //   Some(texture) => texture.get_origin()
  //   None => @struct.Point::default()
  // }
  ...
}

///|
fn get_dimensions(animation : @resource.NxAnimation) -> @struct.Point[Int] {
  let texture = animation.frames[0].texture
  { x: texture.w, y: texture.h }
}
