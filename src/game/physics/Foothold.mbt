///|
/// Represents a platform part on a maple map
struct Foothold {
  id : Int
  prev : Int
  next : Int
  layer : Int
  horizontal : @struct.Range[Int]
  vertical : @struct.Range[Int]
} derive(Default, Debug)

///|
/// Raw foothold node from map JSON.
pub(all) struct NxFoothold {
  prev : Int
  next : Int
  x1 : Int
  x2 : Int
  y1 : Int
  y2 : Int
} derive(@json.FromJson)

///|
/// Build a runtime foothold from raw map data.
pub fn Foothold::new(
  nx_foothold : NxFoothold,
  id : Int,
  layer : Int,
) -> Foothold {
  let horizontal = @struct.Range::new(nx_foothold.x1, nx_foothold.x2)
  let vertical = @struct.Range::new(nx_foothold.y1, nx_foothold.y2)
  {
    id,
    prev: nx_foothold.prev,
    next: nx_foothold.next,
    layer,
    horizontal,
    vertical,
  }
}

///|
/// Return foothold id.
pub fn Foothold::id(self : Foothold) -> Int {
  self.id
}

///|
/// Return previous foothold id in chain.
pub fn Foothold::prev(self : Foothold) -> Int {
  self.prev
}

///|
/// Return next foothold id in chain.
pub fn Foothold::next(self : Foothold) -> Int {
  self.next
}

///|
/// Return layer index.
pub fn Foothold::layer(self : Foothold) -> Int {
  self.layer
}

///|
/// Return horizontal range [x1, x2].
pub fn Foothold::horizontal(self : Foothold) -> @struct.Range[Int] {
  self.horizontal
}

///|
/// Return vertical range [y1, y2].
pub fn Foothold::vertical(self : Foothold) -> @struct.Range[Int] {
  self.vertical
}

///|
/// Return the smaller x endpoint.
pub fn Foothold::l(self : Foothold) -> Int {
  self.horizontal.smaller()
}

///|
/// Return the greater x endpoint.
pub fn Foothold::r(self : Foothold) -> Int {
  self.horizontal.greater()
}

///|
/// Return the smaller y endpoint.
pub fn Foothold::t(self : Foothold) -> Int {
  self.vertical.smaller()
}

///|
/// Return the greater y endpoint.
pub fn Foothold::b(self : Foothold) -> Int {
  self.vertical.greater()
}

///|
/// Return original x1 endpoint from resource.
pub fn Foothold::x1(self : Foothold) -> Int {
  self.horizontal.first()
}

///|
/// Return original x2 endpoint from resource.
pub fn Foothold::x2(self : Foothold) -> Int {
  self.horizontal.second()
}

///|
/// Return original y1 endpoint from resource.
pub fn Foothold::y1(self : Foothold) -> Int {
  self.vertical.first()
}

///|
/// Return original y2 endpoint from resource.
pub fn Foothold::y2(self : Foothold) -> Int {
  self.vertical.second()
}

///|
/// True when this foothold is a vertical wall.
pub fn Foothold::is_wall(self : Foothold) -> Bool {
  self.id != 0 && self.horizontal.empty()
}

///|
/// True when this foothold is a horizontal floor.
pub fn Foothold::is_floor(self : Foothold) -> Bool {
  self.id != 0 && self.vertical.empty()
}

///|
/// True when this foothold is the left edge of a chain.
pub fn Foothold::is_left_edge(self : Foothold) -> Bool {
  self.id != 0 && self.prev == 0
}

///|
/// True when this foothold is the right edge of a chain.
pub fn Foothold::is_right_edge(self : Foothold) -> Bool {
  self.id != 0 && self.next == 0
}

///|
/// Check whether x is inside horizontal range.
pub fn Foothold::hcontains(self : Foothold, x : Int) -> Bool {
  self.id != 0 && self.horizontal.contains(x)
}

///|
/// Check whether y is inside vertical range.
pub fn Foothold::vcontains(self : Foothold, y : Int) -> Bool {
  self.id != 0 && self.vertical.contains(y)
}

///|
/// True when this wall overlaps the given vertical range.
pub fn Foothold::is_blocking(
  self : Foothold,
  vertical : @struct.Range[Int],
) -> Bool {
  self.is_wall() && self.vertical.overlaps(vertical)
}

///|
/// Horizontal length (x2 - x1).
pub fn Foothold::hdelta(self : Foothold) -> Int {
  self.horizontal.delta()
}

///|
/// Vertical delta (y2 - y1).
pub fn Foothold::vdelta(self : Foothold) -> Int {
  self.vertical.delta()
}

///|
/// Slope of the foothold. Walls return 0.
pub fn Foothold::slope(self : Foothold) -> Double {
  if self.is_wall() {
    0.0
  } else {
    self.vdelta().to_double() / self.hdelta().to_double()
  }
}

///|
/// Compute y on this foothold at x.
pub fn Foothold::ground_below(self : Foothold, x : Double) -> Double {
  if self.is_floor() {
    self.y1().to_double()
  } else {
    self.slope() * (x - self.x1().to_double()) + self.y1().to_double()
  }
}
