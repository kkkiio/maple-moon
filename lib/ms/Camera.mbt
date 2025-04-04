///|
typealias Linear = @utils.Linear

///| View on stage which follows the player object.
struct Camera {
  /// Movement variables.
  x : Linear
  y : Linear
  /// View limits.
  mut hbounds : @struct.Range[Int]
  mut vbounds : @struct.Range[Int]
  vwidth : Int
  vheight : Int
}

///| offset y to see more above the player
let y_offset : Int = 80

///|
fn Camera::new() -> Camera {
  let constants = @constants.constants
  {
    x: Linear::new(0.0),
    y: Linear::new(0.0 + y_offset.to_double()),
    hbounds: @struct.Range::default(),
    vbounds: @struct.Range::default(),
    vwidth: constants.get_viewwidth(),
    vheight: constants.get_viewheight(),
  }
}

///|
pub fn Camera::update(self : Camera, position : @struct.Point[Int]) -> Unit {
  let mut next_x = self.x.get()
  let hdelta = (self.vwidth / 2 - position.x).to_double() - next_x
  if hdelta.abs() >= 5.0 {
    next_x += hdelta * (12.0 / self.vwidth.to_double())
  }
  let mut next_y = self.y.get()
  let vdelta = (self.vheight / 2 - position.y + y_offset).to_double() - next_y
  if vdelta.abs() >= 5.0 {
    next_y += vdelta * (12.0 / self.vheight.to_double())
  }
  if next_x > self.hbounds.first().to_double() ||
    self.hbounds.length() < self.vwidth {
    next_x = self.hbounds.first().to_double()
  } else if next_x < self.hbounds.second().to_double() + self.vwidth.to_double() {
    next_x = self.hbounds.second().to_double() + self.vwidth.to_double()
  }
  if next_y > self.vbounds.first().to_double() ||
    self.vbounds.length() < self.vheight {
    next_y = self.vbounds.first().to_double()
  } else if next_y <
    self.vbounds.second().to_double() + self.vheight.to_double() {
    next_y = self.vbounds.second().to_double() + self.vheight.to_double()
  }
  self.x.set(next_x)
  self.y.set(next_y)
}

///|
pub fn Camera::set_position(
  self : Camera,
  position : @struct.Point[Int]
) -> Unit {
  self.x.set((self.vwidth / 2 - position.x).to_double())
  self.y.set((self.vheight / 2 - position.y + y_offset).to_double())
}

///| Updates the view's boundaries. Determined by mapinfo or footholds.
pub fn set_view(
  self : Camera,
  hborders : @struct.Range[Int],
  vborders : @struct.Range[Int]
) -> Unit {
  self.hbounds = -hborders
  self.vbounds = -vborders
}

///|
pub fn Camera::get_position(
  self : Camera,
  alpha? : Double
) -> @struct.Point[Int] {
  let interx = self.x.get(alpha?).round().to_int()
  let intery = self.y.get(alpha?).round().to_int()
  @struct.Point::new(interx, intery)
}

///|
pub fn Camera::real_position(
  self : Camera,
  alpha : Double
) -> @struct.Point[Double] {
  @struct.Point::new(self.x.get(alpha~), self.y.get(alpha~))
}
