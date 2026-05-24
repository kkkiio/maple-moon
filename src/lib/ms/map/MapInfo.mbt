///|
using @struct {type Range}

///|
using @struct {type Point}

///|
struct NxSeat {
  x : Int
  y : Int
}

///|
pub impl @json.FromJson for NxSeat with fn from_json(json, path) -> NxSeat raise @json.JsonDecodeError {
  match json {
    { "x": Number(x, ..), "y": Number(y, ..), .. } =>
      { x: x.to_int(), y: y.to_int() }
    [Number(x, ..), Number(y, ..)] => { x: x.to_int(), y: y.to_int() }
    _ =>
      raise @json.JsonDecodeError(
        (path, "invalid nx seat, expected {x,y} or [x,y]"),
      )
  }
}

///|
struct NxLadder {
  x : Int
  y1 : Int
  y2 : Int
  l : Bool
}

///|
pub impl @json.FromJson for NxLadder with fn from_json(json, path) -> NxLadder raise @json.JsonDecodeError {
  match json {
    {
      "x": Number(x, ..),
      "y1": Number(y1, ..),
      "y2": Number(y2, ..),
      "l": Number(l, ..),
      ..
    } => { x: x.to_int(), y1: y1.to_int(), y2: y2.to_int(), l: l.to_int() != 0 }
    {
      "x": Number(x, ..),
      "y1": Number(y1, ..),
      "y2": Number(y2, ..),
      "l": String("true"),
      ..
    } => { x: x.to_int(), y1: y1.to_int(), y2: y2.to_int(), l: true }
    {
      "x": Number(x, ..),
      "y1": Number(y1, ..),
      "y2": Number(y2, ..),
      "l": String("false"),
      ..
    } => { x: x.to_int(), y1: y1.to_int(), y2: y2.to_int(), l: false }
    _ =>
      raise @json.JsonDecodeError(
        (path, "invalid nx ladder, expected fields x/y1/y2/l"),
      )
  }
}

///|
/// Define the Seat struct and its methods
struct Seat {
  pos : Point[Int]
}

///|
pub fn Seat::from_resource(src : NxSeat) -> Seat {
  { pos: Point::new(src.x, src.y) }
}

///|
pub fn Seat::inrange(self : Seat, position : Point[Int]) -> Bool {
  let hor = Range::symmetric(position.x, 10)
  let ver = Range::symmetric(position.y, 10)
  hor.contains(self.pos.x) && ver.contains(self.pos.y)
}

///|
pub fn Seat::getpos(self : Seat) -> Point[Int] {
  self.pos
}

///|
/// Define the Ladder struct and its methods
struct Ladder {
  x : Int
  y1 : Int
  y2 : Int
  ladder : Bool
}

///|
pub fn Ladder::from_resource(src : NxLadder) -> Ladder {
  { x: src.x, y1: src.y1, y2: src.y2, ladder: src.l }
}

///|
pub fn Ladder::is_ladder(self : Ladder) -> Bool {
  self.ladder
}

///|
pub fn Ladder::inrange(
  self : Ladder,
  position : Point[Int],
  upwards : Bool,
) -> Bool {
  let hor = Range::symmetric(position.x, 10)
  let ver = Range::new(self.y1, self.y2)
  let y = if upwards { position.y - 5 } else { position.y + 5 }
  hor.contains(self.x) && ver.contains(y)
}

///|
pub fn Ladder::felloff(self : Ladder, y : Int, downwards : Bool) -> Bool {
  let dy = if downwards { y + 1 } else { y - 1 }
  dy > self.y2 || y + 1 < self.y1
}

///|
pub fn Ladder::get_x(self : Ladder) -> Int {
  self.x
}

///|
/// Return the top y coordinate of the ladder or rope.
pub fn Ladder::get_top(self : Ladder) -> Int {
  self.y1
}

///|
/// Return the bottom y coordinate of the ladder or rope.
pub fn Ladder::get_bottom(self : Ladder) -> Int {
  self.y2
}

///|
/// Define the MapInfo struct and its methods
pub struct MapInfo {
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

///|
pub fn MapInfo::from_resource(
  src : Json,
  walls : Range[Int],
  borders : Range[Int],
) -> MapInfo {
  let info = match src {
    { "info": info, .. } => info
    _ => panic()
  }
  let seat = match src {
    { "seat": seat, .. } => seat
    _ => null
  }
  let ladder_rope = match src {
    { "ladderRope": ladder_rope, .. } => ladder_rope
    _ => null
  }
  let (map_walls, map_borders) = match info {
    {
      "VRLeft": Json::Number(vrLeft, ..),
      "VRRight": Json::Number(vrRight, ..),
      "VRTop": Json::Number(vrTop, ..),
      "VRBottom": Json::Number(vrBottom, ..),
      ..
    } =>
      (
        Range::new(vrLeft.to_int(), vrRight.to_int()),
        Range::new(vrTop.to_int(), vrBottom.to_int()),
      )
    _ => (walls, borders)
  }
  guard info is Object(info_obj) else { panic() }
  let bgmpath = json_get_string(info_obj, "bgm")
  let bgm = match bgmpath.to_array().search('/') {
    Some(split) =>
      bgmpath.view(start_offset=0, end_offset=split) +
      ".img/" +
      bgmpath.view(start_offset=split + 1)
    None => bgmpath
  }
  let seats = Array::new()
  if seat is Object(seat_obj) {
    for _, it in seat_obj {
      let nx_seat : NxSeat = @json.from_json(it) catch { _ => panic() }
      seats.push(Seat::from_resource(nx_seat))
    }
  }
  let ladders = Array::new()
  if ladder_rope is Object(ladder_obj) {
    for _, it in ladder_obj {
      let nx_ladder : NxLadder = @json.from_json(it) catch { _ => panic() }
      ladders.push(Ladder::from_resource(nx_ladder))
    }
  }
  {
    field_limit: json_get_int(info_obj, "fieldLimit"),
    cloud: json_get_bool(info_obj, "cloud"),
    bgm: bgm.to_owned(),
    map_desc: json_get_string(info_obj, "mapDesc"),
    map_name: json_get_string(info_obj, "mapName"),
    street_name: json_get_string(info_obj, "streetName"),
    map_mark: json_get_string(info_obj, "mapMark"),
    swim: json_get_bool(info_obj, "swim"),
    town: json_get_bool(info_obj, "town"),
    hide_minimap: json_get_bool(info_obj, "hideMinimap"),
    map_walls,
    map_borders,
    seats,
    ladders,
  }
}

///|
pub fn MapInfo::from_tiled_map(
  map : @tiled.TiledMap,
  walls : Range[Int],
  borders : Range[Int],
) -> MapInfo raise {
  let map_walls = match
    (tiled_map_int(map, "VRLeft"), tiled_map_int(map, "VRRight")) {
    (Some(left), Some(right)) => Range::new(left, right)
    _ => walls
  }
  let map_borders = match
    (tiled_map_int(map, "VRTop"), tiled_map_int(map, "VRBottom")) {
    (Some(top), Some(bottom)) => Range::new(top, bottom)
    _ => borders
  }
  let bgm = normalize_bgm_path(tiled_map_string_or_default(map, "bgm", ""))
  {
    field_limit: tiled_map_int_or_default(map, "fieldLimit", 0),
    cloud: tiled_map_bool_or_default(map, "cloud", false),
    bgm,
    map_desc: tiled_map_string_or_default(map, "mapDesc", ""),
    map_name: tiled_map_string_or_default(map, "mapName", ""),
    street_name: tiled_map_string_or_default(map, "streetName", ""),
    map_mark: tiled_map_string_or_default(map, "mapMark", ""),
    swim: tiled_map_bool_or_default(map, "swim", false),
    town: tiled_map_bool_or_default(map, "town", false),
    hide_minimap: tiled_map_bool_or_default(map, "hideMinimap", false),
    map_walls,
    map_borders,
    seats: from_tiled_seats(map),
    ladders: from_tiled_ladders(map),
  }
}

///|
fn normalize_bgm_path(bgmpath : String) -> String {
  match bgmpath.to_array().search('/') {
    Some(split) =>
      (bgmpath.view(start_offset=0, end_offset=split) +
      ".img/" +
      bgmpath.view(start_offset=split + 1)).to_owned()
    None => bgmpath
  }
}

///|
fn from_tiled_seats(map : @tiled.TiledMap) -> Array[Seat] raise {
  guard map.object_layer("seat") is Some(layer) else { return [] }
  let seats = []
  for obj in layer.objects {
    guard obj.point else {
      fail("seat object must be point, object_id=\{obj.id}")
    }
    seats.push({ pos: Point::new(obj.x.to_int(), obj.y.to_int()) })
  }
  seats
}

///|
fn from_tiled_ladders(map : @tiled.TiledMap) -> Array[Ladder] raise {
  guard map.object_layer("ladderRope") is Some(layer) else { return [] }
  let ladders = []
  for obj in layer.objects {
    let l = mapinfo_object_bool_required(obj, "l")
    let (x, y1, y2) = if obj.polyline.length() >= 2 {
      let p1 = obj.polyline[0]
      let p2 = obj.polyline[1]
      let x1 = (obj.x + p1.x).to_int()
      let x2 = (obj.x + p2.x).to_int()
      if x1 != x2 {
        fail("ladder polyline must be vertical, object_id=\{obj.id}")
      }
      let y1 = (obj.y + p1.y).to_int()
      let y2 = (obj.y + p2.y).to_int()
      (x1, @cmp.minimum(y1, y2), @cmp.maximum(y1, y2))
    } else {
      (
        obj.x.to_int(),
        mapinfo_object_int_required(obj, "y1"),
        mapinfo_object_int_required(obj, "y2"),
      )
    }
    ladders.push({ x, y1, y2, ladder: l })
  }
  ladders
}

///|
fn tiled_map_int_or_default(
  map : @tiled.TiledMap,
  name : String,
  default : Int,
) -> Int raise {
  tiled_map_int(map, name).unwrap_or(default)
}

///|
fn tiled_map_int(map : @tiled.TiledMap, name : String) -> Int? raise {
  match map.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => Some(value)
    Some(@tiled.TiledPropertyValue::Float(value)) => Some(value.to_int())
    Some(_) => fail("map property '\{name}' must be int")
    None => None
  }
}

///|
fn tiled_map_bool_or_default(
  map : @tiled.TiledMap,
  name : String,
  default : Bool,
) -> Bool raise {
  match map.property(name) {
    Some(@tiled.TiledPropertyValue::Bool(value)) => value
    Some(@tiled.TiledPropertyValue::Int(value)) => value != 0
    Some(@tiled.TiledPropertyValue::String("true")) => true
    Some(@tiled.TiledPropertyValue::String("false")) => false
    Some(_) => fail("map property '\{name}' must be bool")
    None => default
  }
}

///|
fn tiled_map_string_or_default(
  map : @tiled.TiledMap,
  name : String,
  default : String,
) -> String raise {
  match map.property(name) {
    Some(@tiled.TiledPropertyValue::String(value)) => value
    Some(@tiled.TiledPropertyValue::Int(value)) => value.to_string()
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_string()
    Some(_) => fail("map property '\{name}' must be string")
    None => default
  }
}

///|
fn mapinfo_object_int_required(
  obj : @tiled.TiledObject,
  name : String,
) -> Int raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => value
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_int()
    Some(_) =>
      fail("object property '\{name}' must be int, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn mapinfo_object_bool_required(
  obj : @tiled.TiledObject,
  name : String,
) -> Bool raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Bool(value)) => value
    Some(@tiled.TiledPropertyValue::Int(value)) => value != 0
    Some(@tiled.TiledPropertyValue::String("true")) => true
    Some(@tiled.TiledPropertyValue::String("false")) => false
    Some(_) =>
      fail("object property '\{name}' must be bool, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn json_get_int(obj : Map[String, Json], key : String) -> Int {
  match obj.get(key) {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }
}

///|
fn json_get_bool(obj : Map[String, Json], key : String) -> Bool {
  match obj.get(key) {
    Some(Number(n, ..)) => n.to_int() != 0
    Some(String("true")) => true
    Some(String("false")) => false
    _ => false
  }
}

///|
fn json_get_string(obj : Map[String, Json], key : String) -> String {
  match obj.get(key) {
    Some(String(s)) => s
    Some(Number(n, ..)) => n.to_string()
    _ => ""
  }
}

///|
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

///|
pub fn MapInfo::is_underwater(self : MapInfo) -> Bool {
  self.swim
}

///|
pub fn MapInfo::get_bgm(self : MapInfo) -> String {
  self.bgm
}

///|
pub fn MapInfo::get_walls(self : MapInfo) -> Range[Int] {
  self.map_walls
}

///|
pub fn MapInfo::get_borders(self : MapInfo) -> Range[Int] {
  self.map_borders
}

///|
pub fn MapInfo::findseat(self : MapInfo, position : Point[Int]) -> Seat? {
  self.seats.iter().find_first(fn(seat) { seat.inrange(position) })
}

///|
pub fn MapInfo::find_ladder(
  self : MapInfo,
  position : Point[Int],
  upwards : Bool,
) -> Ladder? {
  self.ladders
  .iter()
  .find_first(fn(ladder) { ladder.inrange(position, upwards) })
}

///|
pub fn MapInfo::get_full_name(self : MapInfo) -> String {
  self.street_name + " : " + self.map_name
}

///|
pub fn get_map_category(map_id : Int) -> String {
  if map_id < 100000000 {
    return "maple"
  }
  if map_id < 200000000 {
    return "victoria"
  }
  if map_id < 300000000 {
    return "ossyria"
  }
  if map_id < 540000000 {
    return "elin"
  }
  if map_id < 600000000 {
    return "singapore"
  }
  if map_id < 670000000 {
    return "MasteriaGL"
  }
  if map_id < 682000000 {
    let prefix3 = map_id / 1000000 * 1000000
    let prefix4 = map_id / 100000 * 100000
    if prefix3 == 674000000 || prefix4 == 680100000 || prefix4 == 889100000 {
      return "etc"
    }
    if prefix3 == 677000000 {
      return "Episode1GL"
    }
    return "weddingGL"
  }
  if map_id < 683000000 {
    return "HalloweenGL"
  }
  if map_id < 800000000 {
    return "event"
  }
  if map_id < 900000000 {
    return "jp"
  }
  return "etc"
}

///|
test "map info from resource tolerates missing optional fields" {
  let src : Json = {
    "info": {
      "bgm": "Bgm15/Nautilus",
      "cloud": 0,
      "fieldLimit": 4,
      "hideMinimap": 0,
      "mapMark": "Nautilus",
      "swim": 0,
      "town": 0,
    },
    "ladderRope": { "0": { "x": 10, "y1": 0, "y2": 100, "l": 1 } },
  }
  let info = MapInfo::from_resource(
    src,
    Range::new(-10, 10),
    Range::new(-20, 20),
  )
  inspect(info.get_full_name(), content=" : ")
  inspect(info.find_ladder(Point::new(10, 50), true) is Some(_), content="true")
}

///|
test "map info seat supports [x, y] nx format" {
  let src : Json = {
    "info": {
      "bgm": "Bgm15/Nautilus",
      "cloud": 0,
      "fieldLimit": 4,
      "hideMinimap": 0,
      "mapMark": "Nautilus",
      "swim": 0,
      "town": 0,
    },
    "seat": { "0": [1350, -62] },
  }
  let info = MapInfo::from_resource(
    src,
    Range::new(-10, 10),
    Range::new(-20, 20),
  )
  inspect(info.findseat(Point::new(1350, -62)) is Some(_), content="true")
}
