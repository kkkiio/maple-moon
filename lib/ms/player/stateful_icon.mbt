enum StatefulIconState {
  NORMAL
  DISABLED
  MOUSEOVER
}

struct StatefulIcon {
  state : StatefulIconState
  ntx : @graphics.Texture
  dtx : @graphics.Texture
  motx : @graphics.Texture
}

pub fn StatefulIcon::new(
  ntx : @graphics.Texture,
  dtx : @graphics.Texture,
  motx : @graphics.Texture
) -> StatefulIcon {
  { state: NORMAL, ntx, dtx, motx }
}

pub fn StatefulIcon::get_texture(self : StatefulIcon) -> @graphics.Texture {
  match self.state {
    NORMAL => self.ntx
    DISABLED => self.dtx
    MOUSEOVER => self.motx
  }
}
