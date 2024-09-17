typealias Linear = @utils.Linear

struct Camera {
  x : Linear
  y : Linear
  mut hbounds : @struct.Range[Int]
  mut vbounds : @struct.Range[Int]
  mut vwidth : Int
  mut vheight : Int
}

let y_offset : Int = 80

fn Camera::new() -> Camera {
  let camera = {
    x: Linear::default(),
    y: Linear::default(),
    hbounds: @struct.Range::default(),
    vbounds: @struct.Range::default(),
    vwidth: 0,
    vheight: 0,
  }
  camera.x.set(0.0)
  camera.y.set(0.0 + y_offset.to_double())
  let constants = @constants.constants
  camera.vwidth = constants.get_viewwidth()
  camera.vheight = constants.get_viewheight()
  camera
}

pub fn Camera::update(self : Camera, position : Point[Int]) -> Unit {
  let constants = @constants.constants
  let new_width = constants.get_viewwidth()
  let new_height = constants.get_viewheight()
  if self.vwidth != new_width || self.vheight != new_height {
    self.vwidth = new_width
    self.vheight = new_height
  }
  let mut next_x = self.x.get()
  let hdelta = self.vwidth.to_double() / 2.0 - position.x.to_double() - next_x
  if hdelta.abs() >= 5.0 {
    next_x += hdelta * (12.0 / self.vwidth.to_double())
  }
  let mut next_y = self.y.get()
  let vdelta = self.vheight.to_double() / 2.0 -
    position.y.to_double() +
    y_offset.to_double() -
    next_y
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

pub fn Camera::set_position(self : Camera, position : Point[Int]) -> Unit {
  let constants = @constants.constants
  let new_width = constants.get_viewwidth()
  let new_height = constants.get_viewheight()
  if self.vwidth != new_width || self.vheight != new_height {
    self.vwidth = new_width
    self.vheight = new_height
  }
  self.x.set(self.vwidth.to_double() / 2.0 - position.x.to_double())
  self.y.set(
    self.vheight.to_double() / 2.0 -
    position.y.to_double() +
    y_offset.to_double(),
  )
}

pub fn Camera::set_view(
  self : Camera,
  hborders : @struct.Range[Int],
  vborders : @struct.Range[Int]
) -> Unit {
  self.hbounds = -hborders
  self.vbounds = -vborders
}

pub fn Camera::position(self : Camera) -> Point[Int] {
  let shortx = self.x.get().round().to_int()
  let shorty = self.y.get().round().to_int()
  Point::new(shortx, shorty)
}

pub fn Camera::position_interpolated(
  self : Camera,
  alpha : Double
) -> Point[Int] {
  let interx = self.x.get(~alpha).round().to_int()
  let intery = self.y.get(~alpha).round().to_int()
  Point::new(interx, intery)
}

pub fn Camera::real_position(self : Camera, alpha : Double) -> Point[Double] {
  Point::new(self.x.get(~alpha), self.y.get(~alpha))
}
