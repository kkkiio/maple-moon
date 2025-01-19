///|
enum StatefulIconState {
  NORMAL
  DISABLED
  MOUSEOVER
}

///|
struct StatefulIcon {
  state : StatefulIconState
  ntx : @graphics.Texture
  dtx : @graphics.Texture
  motx : @graphics.Texture
  icon_model : @inventory.IconModel
}

///|
pub fn StatefulIcon::new(
  ntx : @graphics.Texture,
  dtx : @graphics.Texture,
  motx : @graphics.Texture
) -> StatefulIcon {
  { state: NORMAL, ntx, dtx, motx, icon_model: @inventory.IconModel::new(None) }
}

///|
pub fn StatefulIcon::draw(
  self : StatefulIcon,
  position : @struct.Point[Int]
) -> Unit {
  self.icon_model.draw(position, self.get_texture())
}

///|
pub fn StatefulIcon::get_texture(self : StatefulIcon) -> @graphics.Texture {
  match self.state {
    NORMAL => self.ntx
    DISABLED => self.dtx
    MOUSEOVER => self.motx
  }
}
