/// Represents a platform part on a maple map
struct Foothold {
  id : Int
  prev : Int
  next : Int
  layer : Int
  horizontal : @struct.Range[Int]
  vertical : @struct.Range[Int]
} derive(Default)

pub fn Foothold::load_from_resource(
  src : @resource.NxNode,
  id : Int,
  ly : Int
) -> Foothold!@resource.LoadError {
  match src.value() {
    {
      "prev": Json::Number(prev),
      "next": Json::Number(next),
      "x1": Json::Number(x1),
      "x2": Json::Number(x2),
      "y1": Json::Number(y1),
      "y2": Json::Number(y2),
    } => {
      let horizontal = @struct.Range::new(x1.to_int(), x2.to_int())
      let vertical = @struct.Range::new(y1.to_int(), y2.to_int())
      {
        id,
        prev: prev.to_int(),
        next: next.to_int(),
        layer: ly,
        horizontal,
        vertical,
      }
    }
    _ => raise @resource.LoadError("invalid foothold")
  }
}

pub fn id(self : Foothold) -> Int {
  self.id
}

pub fn prev(self : Foothold) -> Int {
  self.prev
}

pub fn next(self : Foothold) -> Int {
  self.next
}

pub fn layer(self : Foothold) -> Int {
  self.layer
}

pub fn horizontal(self : Foothold) -> @struct.Range[Int] {
  self.horizontal
}

pub fn vertical(self : Foothold) -> @struct.Range[Int] {
  self.vertical
}

pub fn l(self : Foothold) -> Int {
  self.horizontal.smaller()
}

pub fn r(self : Foothold) -> Int {
  self.horizontal.greater()
}

pub fn t(self : Foothold) -> Int {
  self.vertical.smaller()
}

pub fn b(self : Foothold) -> Int {
  self.vertical.greater()
}

pub fn x1(self : Foothold) -> Int {
  self.horizontal.first()
}

pub fn x2(self : Foothold) -> Int {
  self.horizontal.second()
}

pub fn y1(self : Foothold) -> Int {
  self.vertical.first()
}

pub fn y2(self : Foothold) -> Int {
  self.vertical.second()
}

pub fn is_wall(self : Foothold) -> Bool {
  self.id != 0 && self.horizontal.empty()
}

pub fn is_floor(self : Foothold) -> Bool {
  self.id != 0 && self.vertical.empty()
}

pub fn is_left_edge(self : Foothold) -> Bool {
  self.id != 0 && self.prev == 0
}

pub fn is_right_edge(self : Foothold) -> Bool {
  self.id != 0 && self.next == 0
}

pub fn hcontains(self : Foothold, x : Int) -> Bool {
  self.id != 0 && self.horizontal.contains(x)
}

pub fn vcontains(self : Foothold, y : Int) -> Bool {
  self.id != 0 && self.vertical.contains(y)
}

pub fn is_blocking(self : Foothold, vertical : @struct.Range[Int]) -> Bool {
  self.is_wall() && self.vertical.overlaps(vertical)
}

pub fn hdelta(self : Foothold) -> Int {
  self.horizontal.delta()
}

pub fn vdelta(self : Foothold) -> Int {
  self.vertical.delta()
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
