// Represents a platform part on a maple map
struct Foothold {
  m_id : Int
  m_prev : Int
  m_next : Int
  m_layer : Int
  m_horizontal : @struct.Range[Int]
  m_vertical : @struct.Range[Int]
} derive(Default)

pub fn Foothold::from_resource(
  src : @resource.NxNode,
  id : Int,
  ly : Int
) -> Foothold {
  let m_id = id
  let m_prev = src["prev"].get_int?().unwrap()
  let m_next = src["next"].get_int?().unwrap()
  let m_layer = ly
  let m_horizontal = @struct.Range::new(
    src["x1"].get_int?().unwrap(),
    src["x2"].get_int?().unwrap(),
  )
  let m_vertical = @struct.Range::new(
    src["y1"].get_int?().unwrap(),
    src["y2"].get_int?().unwrap(),
  )
  { m_id, m_prev, m_next, m_layer, m_horizontal, m_vertical }
}

pub fn id(self : Foothold) -> Int {
  self.m_id
}

pub fn prev(self : Foothold) -> Int {
  self.m_prev
}

pub fn next(self : Foothold) -> Int {
  self.m_next
}

pub fn layer(self : Foothold) -> Int {
  self.m_layer
}

pub fn horizontal(self : Foothold) -> @struct.Range[Int] {
  self.m_horizontal
}

pub fn vertical(self : Foothold) -> @struct.Range[Int] {
  self.m_vertical
}

pub fn l(self : Foothold) -> Int {
  self.m_horizontal.smaller()
}

pub fn r(self : Foothold) -> Int {
  self.m_horizontal.greater()
}

pub fn t(self : Foothold) -> Int {
  self.m_vertical.smaller()
}

pub fn b(self : Foothold) -> Int {
  self.m_vertical.greater()
}

pub fn x1(self : Foothold) -> Int {
  self.m_horizontal.first()
}

pub fn x2(self : Foothold) -> Int {
  self.m_horizontal.second()
}

pub fn y1(self : Foothold) -> Int {
  self.m_vertical.first()
}

pub fn y2(self : Foothold) -> Int {
  self.m_vertical.second()
}

pub fn is_wall(self : Foothold) -> Bool {
  self.m_id != 0 && self.m_horizontal.empty()
}

pub fn is_floor(self : Foothold) -> Bool {
  self.m_id != 0 && self.m_vertical.empty()
}

pub fn is_left_edge(self : Foothold) -> Bool {
  self.m_id != 0 && self.m_prev == 0
}

pub fn is_right_edge(self : Foothold) -> Bool {
  self.m_id != 0 && self.m_next == 0
}

pub fn hcontains(self : Foothold, x : Int) -> Bool {
  self.m_id != 0 && self.m_horizontal.contains(x)
}

pub fn vcontains(self : Foothold, y : Int) -> Bool {
  self.m_id != 0 && self.m_vertical.contains(y)
}

pub fn is_blocking(self : Foothold, vertical : @struct.Range[Int]) -> Bool {
  self.is_wall() && self.m_vertical.overlaps(vertical)
}

pub fn hdelta(self : Foothold) -> Int {
  self.m_horizontal.delta()
}

pub fn vdelta(self : Foothold) -> Int {
  self.m_vertical.delta()
}

pub fn slope(self : Foothold) -> Double {
  if self.is_wall() {
    0.0
  } else {
    self.vdelta().to_double() / self.hdelta().to_double()
  }
}

pub fn ground_below(self : Foothold, x : Double) -> Double {
  if self.is_floor() {
    self.y1().to_double()
  } else {
    self.slope() * (x - self.x1().to_double()) + self.y1().to_double()
  }
}
