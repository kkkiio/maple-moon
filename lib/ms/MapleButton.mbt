/// A standard maplestory-button with 4 states and a texture for each state.
struct MapleButton {
  base : ButtonBase
  textures : @immut/hashmap.T[ButtonState, Texture]
  animations : @immut/hashmap.T[ButtonState, Animation]
}

pub fn get_button_base(self : MapleButton) -> ButtonBase {
  self.base
}

pub fn send_cursor(
  self : MapleButton,
  _b : Bool,
  _p : Point[Int]
) -> CursorState {
  CursorState::IDLE
}

pub fn MapleButton::from_resource_with_pos(
  src : NxNode,
  pos : Point[Int]
) -> MapleButton {
  let base = ButtonBase::default()
  let normal = src["normal"]
  let textures = {  }
  let animations = {  }
  if normal.get_children_count() > 1 {
    animations[ButtonState::NORMAL] = Animation::from_resource(normal)
  } else {
    textures[ButtonState::NORMAL] = Texture::from_resource(normal["0"])
  }
  textures[ButtonState::PRESSED] = Texture::from_resource(src["pressed"]["0"])
  textures[ButtonState::MOUSEOVER] = Texture::from_resource(
    src["mouseOver"]["0"],
  )
  textures[ButtonState::DISABLED] = Texture::from_resource(src["disabled"]["0"])
  base.active = true
  base.position = pos
  base.state = ButtonState::NORMAL
  {
    base,
    textures: @immut/hashmap.from_iter(textures.iter()),
    animations: @immut/hashmap.from_iter(animations.iter()),
  }
}

pub fn MapleButton::from_resource_with_x_y(
  src : NxNode,
  x : Int,
  y : Int
) -> MapleButton {
  MapleButton::from_resource_with_pos(src, Point::new(x, y))
}

pub fn MapleButton::from_resource(src : NxNode) -> MapleButton {
  MapleButton::from_resource_with_pos(src, Point::default())
}

pub fn draw(self : MapleButton, parentpos : Point[Int]) -> Unit {
  if self.base.active {
    match self.textures[self.base.state] {
      Some(texture) =>
        texture.draw(DrawArgument::from_point(self.base.position + parentpos))
      None => ()
    }
    match self.animations[self.base.state] {
      Some(animation) =>
        animation.draw(
          DrawArgument::from_point(self.base.position + parentpos),
          1.0,
        )
      None => ()
    }
  }
}

pub fn update(self : MapleButton) -> Unit {
  if self.base.active {
    match self.animations[self.base.state] {
      Some(animation) => animation.update(timestep=6) |> ignore
      None => ()
    }
  }
}

pub fn bounds(self : MapleButton, parentpos : Point[Int]) -> Rectangle[Int] {
  let (lt, rb) = match self.textures[self.base.state] {
    Some(texture) =>
      (
        parentpos + self.base.position - texture.get_origin(),
        parentpos +
        self.base.position -
        texture.get_origin() +
        texture.get_dimensions(),
      )
    None =>
      (
        parentpos +
        self.base.position -
        self.animations[self.base.state].unwrap().get_origin(),
        parentpos +
        self.base.position -
        self.animations[self.base.state].unwrap().get_origin() +
        self.animations[self.base.state].unwrap().get_dimensions(),
      )
  }
  Rectangle::new(lt, rb)
}

pub fn width(self : MapleButton) -> Int {
  match self.textures[self.base.state] {
    Some(texture) => texture.width()
    None => 0
  }
}

pub fn origin(self : MapleButton) -> Point[Int] {
  match self.textures[self.base.state] {
    Some(texture) => texture.get_origin()
    None => Point::default()
  }
}

pub fn in_combobox(self : MapleButton, _p : Point[Int]) -> Bool {
  false
}
