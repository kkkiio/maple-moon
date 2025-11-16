///|
/// Represents a platform part on a maple map
struct Foothold {
  id : Int
  prev : Int
  next : Int
  layer : Int
  horizontal : @struct.Range[Int]
  vertical : @struct.Range[Int]
} derive(Default, Show)

///|
pub(all) struct NxFoothold {
  prev : Int
  next : Int
  x1 : Int
  x2 : Int
  y1 : Int
  y2 : Int
} derive(@json.FromJson)

///|
pub fn Foothold::load_from_resource(
  nx_foothold : NxFoothold,
  id : Int,
  ly : Int,
) -> Foothold {
  let horizontal = @struct.Range::new(nx_foothold.x1, nx_foothold.x2)
  let vertical = @struct.Range::new(nx_foothold.y1, nx_foothold.y2)
  {
    id,
    prev: nx_foothold.prev,
    next: nx_foothold.next,
    layer: ly,
    horizontal,
    vertical,
  }
}

///|
pub fn Foothold::id(self : Foothold) -> Int {
  self.id
}

///|
pub fn Foothold::prev(self : Foothold) -> Int {
  self.prev
}

///|
pub fn Foothold::next(self : Foothold) -> Int {
  self.next
}

///|
pub fn Foothold::layer(self : Foothold) -> Int {
  self.layer
}

///|
pub fn Foothold::horizontal(self : Foothold) -> @struct.Range[Int] {
  self.horizontal
}

///|
pub fn Foothold::vertical(self : Foothold) -> @struct.Range[Int] {
  self.vertical
}

///|
pub fn Foothold::l(self : Foothold) -> Int {
  self.horizontal.smaller()
}

///|
pub fn Foothold::r(self : Foothold) -> Int {
  self.horizontal.greater()
}

///|
pub fn Foothold::t(self : Foothold) -> Int {
  self.vertical.smaller()
}

///|
pub fn Foothold::b(self : Foothold) -> Int {
  self.vertical.greater()
}

///|
pub fn Foothold::x1(self : Foothold) -> Int {
  self.horizontal.first()
}

///|
pub fn Foothold::x2(self : Foothold) -> Int {
  self.horizontal.second()
}

///|
pub fn Foothold::y1(self : Foothold) -> Int {
  self.vertical.first()
}

///|
pub fn Foothold::y2(self : Foothold) -> Int {
  self.vertical.second()
}

///|
pub fn Foothold::is_wall(self : Foothold) -> Bool {
  self.id != 0 && self.horizontal.empty()
}

///|
pub fn Foothold::is_floor(self : Foothold) -> Bool {
  self.id != 0 && self.vertical.empty()
}

///|
pub fn Foothold::is_left_edge(self : Foothold) -> Bool {
  self.id != 0 && self.prev == 0
}

///|
pub fn Foothold::is_right_edge(self : Foothold) -> Bool {
  self.id != 0 && self.next == 0
}

///|
pub fn Foothold::hcontains(self : Foothold, x : Int) -> Bool {
  self.id != 0 && self.horizontal.contains(x)
}

///|
pub fn Foothold::vcontains(self : Foothold, y : Int) -> Bool {
  self.id != 0 && self.vertical.contains(y)
}

///|
pub fn Foothold::is_blocking(
  self : Foothold,
  vertical : @struct.Range[Int],
) -> Bool {
  self.is_wall() && self.vertical.overlaps(vertical)
}

///|
pub fn Foothold::hdelta(self : Foothold) -> Int {
  self.horizontal.delta()
}

///|
pub fn Foothold::vdelta(self : Foothold) -> Int {
  self.vertical.delta()
}

///|
pub fn Foothold::slope(self : Foothold) -> Double {
  if self.is_wall() {
    0.0
  } else {
    self.vdelta().to_double() / self.hdelta().to_double()
  }
}

///|
pub fn Foothold::ground_below(self : Foothold, x : Double) -> Double {
  if self.is_floor() {
    self.y1().to_double()
  } else {
    self.slope() * (x - self.x1().to_double()) + self.y1().to_double()
  }
}
