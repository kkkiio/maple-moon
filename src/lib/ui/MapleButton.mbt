///| A standard maplestory-button with 4 states and a texture for each state.
pub(all) struct MapleButton {
  base : ButtonModel
  textures : Map[ButtonState, @graphics.Texture]
  animations : Map[ButtonState, @graphics.Animation]
}

///|
pub impl UIButton for MapleButton with get_button_base(self : MapleButton) -> ButtonModel {
  self.base
}

///|
pub(all) struct MapleButtonResource {
  textures : Map[ButtonState, @graphics.Texture]
  animations : Map[ButtonState, @graphics.Animation]
} derive(Default)

///|
pub fn MapleButtonResource::from_resource(
  src : @resource.NxNode
) -> MapleButtonResource {
  let normal = src["normal"]
  let textures = {}
  let animations = {}
  if normal.get_children_count() > 1 {
    animations[ButtonState::NORMAL] = @graphics.Animation::from_resource(normal)
  } else {
    textures[ButtonState::NORMAL] = @graphics.Texture::from_resource(
      normal["0"],
    )
  }
  textures[ButtonState::PRESSED] = @graphics.Texture::from_resource(
    src["pressed"]["0"],
  )
  textures[ButtonState::MOUSEOVER] = @graphics.Texture::from_resource(
    src["mouseOver"]["0"],
  )
  textures[ButtonState::DISABLED] = @graphics.Texture::from_resource(
    src["disabled"]["0"],
  )
  { textures, animations }
}

///|
pub fn MapleButton::from_resource(
  src : @resource.NxNode,
  pos~ : Point[Int] = @struct.Point::default()
) -> MapleButton {
  let res = MapleButtonResource::from_resource(src)
  MapleButton::new(res, pos~)
}

///|
pub fn MapleButton::new(
  res : MapleButtonResource,
  pos~ : Point[Int] = @struct.Point::default()
) -> MapleButton {
  let base = ButtonModel::default()
  base.set_position(pos)
  base.set_state(ButtonState::NORMAL)
  { base, textures: res.textures, animations: res.animations }
}

///|
pub fn MapleButton::from_resource_with_x_y(
  src : @resource.NxNode,
  x : Int,
  y : Int
) -> MapleButton {
  MapleButton::from_resource(src, pos=Point::new(x, y))
}

///|
pub impl UIButton for MapleButton with draw(
  self : MapleButton,
  parentpos : Point[Int]
) -> Unit {
  if self.base.active {
    match self.textures.get(self.base.get_state()) {
      Some(texture) =>
        texture.draw(
          @graphics.DrawArgument::new(pos=self.base.position + parentpos),
        )
      None => ()
    }
    match self.animations.get(self.base.get_state()) {
      Some(animation) =>
        animation.draw(
          @graphics.DrawArgument::new(pos=self.base.position + parentpos),
          1.0,
        )
      None => ()
    }
  }
}

///|
pub impl UIButton for MapleButton with update(self : MapleButton) -> Unit {
  if self.base.active {
    match self.animations.get(self.base.get_state()) {
      Some(animation) => animation.update(timestep=6) |> ignore
      None => ()
    }
  }
}

///|
pub impl UIButton for MapleButton with bounds(self : MapleButton) -> @struct.Rectangle[
  Int,
] {
  let (origin, dimensions) = match self.textures.get(self.base.get_state()) {
    Some(texture) => (texture.get_origin(), texture.get_dimensions())
    None => {
      let animation = self.animations.get(self.base.get_state()).unwrap()
      (animation.get_origin(), animation.get_dimensions())
    }
  }
  let lt = self.base.position - origin
  let rb = lt + dimensions
  @struct.Rectangle::new(lt, rb)
}

///|
pub impl UIButton for MapleButton with width(self : MapleButton) -> Int {
  match self.textures.get(self.base.get_state()) {
    Some(texture) => texture.width()
    None => 0
  }
}

///|
pub impl UIButton for MapleButton with origin(self : MapleButton) -> Point[Int] {
  match self.textures.get(self.base.get_state()) {
    Some(texture) => texture.get_origin()
    None => @struct.Point::default()
  }
}
