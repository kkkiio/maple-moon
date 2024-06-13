// Define the Seat struct and its methods
struct Seat {
  pos : Point[Int]
}

pub fn Seat::from_resource(src : NxNode) -> Seat {
  { pos: Point::from_resource(src) }
}

pub fn inrange(self : Seat, position : Point[Int]) -> Bool {
  let hor = Range::symmetric(position.x, 10)
  let ver = Range::symmetric(position.y, 10)
  hor.contains(self.pos.x) && ver.contains(self.pos.y)
}

pub fn getpos(self : Seat) -> Point[Int] {
  self.pos
}

// Define the Ladder struct and its methods
struct Ladder {
  x : Int
  y1 : Int
  y2 : Int
  ladder : Bool
}

pub fn Ladder::from_resource(src : NxNode) -> Ladder {
  {
    x: src["x"].get_int(),
    y1: src["y1"].get_int(),
    y2: src["y2"].get_int(),
    ladder: src["l"].get_bool(),
  }
}

pub fn is_ladder(self : Ladder) -> Bool {
  self.ladder
}

pub fn inrange(self : Ladder, position : Point[Int], upwards : Bool) -> Bool {
  let hor = Range::symmetric(position.x, 10)
  let ver = Range::new(self.y1, self.y2)
  let y = if upwards { position.y - 5 } else { position.y + 5 }
  hor.contains(self.x) && ver.contains(y)
}

pub fn felloff(self : Ladder, y : Int, downwards : Bool) -> Bool {
  let dy = if downwards { y + 1 } else { y - 1 }
  dy > self.y2 || y + 1 < self.y1
}

pub fn get_x(self : Ladder) -> Int {
  self.x
}

// Define the MapInfo struct and its methods
struct MapInfo {
  field_limit : Int
  cloud : Bool
  bgm : String
  map_desc : String
  map_name : String
  street_name : String
  map_mark : String
  swim : Bool
  town : Bool
  hide_minimap : Bool
  map_walls : Range[Int]
  map_borders : Range[Int]
  seats : Array[Seat]
  ladders : Array[Ladder]
}

pub fn MapInfo::from_resource(
  src : NxNode,
  walls : Range[Int],
  borders : Range[Int]
) -> MapInfo {
  let info = src["info"]
  let (map_walls, map_borders) = match info["VRLeft"].desc.as_number() {
    Some(_) =>
      (
        Range::new(info["VRLeft"].get_int(), info["VRRight"].get_int()),
        Range::new(info["VRTop"].get_int(), info["VRBottom"].get_int()),
      )
    None => (walls, borders)
  }
  let bgmpath = info["bgm"].get_string()
  let split = bgmpath.to_array().search('/').unwrap()
  let bgm = bgmpath.substring(start=0, end=split) + ".img/" + bgmpath.substring(
      start=split + 1,
    )
  let seats = src["seat"].get_array().map(Seat::from_resource)
  let ladders = src["ladderRope"].get_array().map(Ladder::from_resource)
  {
    field_limit: info["fieldLimit"].get_int(),
    cloud: info["cloud"].get_bool(),
    bgm,
    map_desc: info["mapDesc"].get_string(),
    map_name: info["mapName"].get_string(),
    street_name: info["streetName"].get_string(),
    map_mark: info["mapMark"].get_string(),
    swim: info["swim"].get_bool(),
    town: info["town"].get_bool(),
    hide_minimap: info["hideMinimap"].get_bool(),
    map_walls,
    map_borders,
    seats,
    ladders,
  }
}

pub fn MapInfo::new() -> MapInfo {
  {
    field_limit: 0,
    cloud: false,
    bgm: "",
    map_desc: "",
    map_name: "",
    street_name: "",
    map_mark: "",
    swim: false,
    town: false,
    hide_minimap: false,
    map_walls: Range::default(),
    map_borders: Range::default(),
    seats: Array::new(),
    ladders: Array::new(),
  }
}

pub fn is_underwater(self : MapInfo) -> Bool {
  self.swim
}

pub fn get_bgm(self : MapInfo) -> String {
  self.bgm
}

pub fn get_walls(self : MapInfo) -> Range[Int] {
  self.map_walls
}

pub fn get_borders(self : MapInfo) -> Range[Int] {
  self.map_borders
}

pub fn findseat(self : MapInfo, position : Point[Int]) -> Seat? {
  self.seats.as_iter().find_first(fn(seat) { seat.inrange(position) })
}

pub fn findladder(
  self : MapInfo,
  position : Point[Int],
  upwards : Bool
) -> Ladder? {
  self.ladders.as_iter().find_first(
    fn(ladder) { ladder.inrange(position, upwards) },
  )
}
