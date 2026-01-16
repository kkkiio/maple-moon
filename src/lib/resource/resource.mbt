///|
#external
type ImageLoader

///|
struct SyncLoader {}

///|
pub async fn SyncLoader::load(
  name : String,
  data_url : String,
  image_loader : ImageLoader,
) -> SyncLoader raise Error {
  ...
  // let loader : SyncResourceLoader = SyncResourceLoader::make(data_url).wait()
  //   |> @js.Value::cast
  // SyncLoader::new(name, loader, image_loader)
}

///|
pub fn SyncLoader::load_res(self : SyncLoader, path : Array[String]) -> NxNode {
  ...
  // {
  //   loader_name: self.name,
  //   image_loader: Some(self.image_loader),
  //   name: path.last().unwrap(),
  //   desc: self.loader.load_desc(join_path(path)).as_moonjson(),
  //   path: path |> @immut/array.from_array,
  // }
}

///|
#deprecated("use Json instead")
struct NxNode {
  loader_name : String
  image_loader : ImageLoader? // TODO: remove optional
  name : String
  desc : Json
  path : @immut/array.T[String]
}

///|
pub fn NxNode::from_test_value(value : Json) -> NxNode {
  {
    loader_name: "",
    image_loader: None,
    name: "",
    desc: value,
    path: @immut/array.from_array([]),
  }
}

///|
pub fn NxNode::name(self : NxNode) -> String {
  self.name
}

///|
pub fn NxNode::value(self : NxNode) -> Json {
  self.desc
}

///|
pub fn NxNode::path(self : NxNode) -> @immut/array.T[String] {
  self.path
}

///|
pub fn NxNode::op_get(self : NxNode, name : String) -> NxNode {
  {
    ..self,
    name,
    desc: self.desc
    .as_object()
    .bind(fn(it) { it.get(name) })
    .unwrap_or(Json::null()),
    path: self.path.push(name),
  }
}

///|
pub fn NxNode::contains(self : NxNode, name : String) -> Bool {
  match self.desc {
    Json::Object(it) => it.contains(name)
    _ => false
  }
}

///|
pub fn NxNode::get_children_count(self : NxNode) -> Int {
  match self.desc {
    Json::Object(it) => it.size()
    _ => 0
  }
}

///|
pub fn NxNode::get_bool(self : NxNode) -> Bool raise LoadError {
  self.get_int() != 0
}

///|
pub fn NxNode::as_strict_bool(self : NxNode) -> Bool raise LoadError {
  self.as_int() != 0
}

///|
pub fn NxNode::get_string(self : NxNode) -> String {
  match self.desc {
    Json::Number(it) => it.to_string()
    Json::String(it) => it
    _ => ""
  }
}

///|
pub fn NxNode::get_int(self : NxNode) -> Int raise LoadError {
  self.get_float().to_int()
}

///|
pub(all) suberror LoadError {
  LoadError(String)
} derive(Show)

///|
pub fn NxNode::as_int(self : NxNode) -> Int raise LoadError {
  match self.desc {
    Json::Number(it) => it.to_int()
    _ as a => raise LoadError("expect number, got \{a}, path=\{self.path}")
  }
}

///|
pub fn NxNode::get_int_field(
  self : NxNode,
  key : String,
  default? : Int,
) -> Int raise LoadError {
  match self.desc.as_object().unwrap().get(key) {
    Some(Json::Number(it, ..)) => it.to_int()
    None =>
      match default {
        Some(it) => it
        None => raise LoadError("missing key \{key}")
      }
    _ as a => raise LoadError("expect number, got \{a}, key=\{key}")
  }
}

///|
pub fn NxNode::get_float_field(
  self : NxNode,
  key : String,
  default? : Double,
) -> Double raise LoadError {
  match self.desc.as_object().unwrap().get(key) {
    Some(Json::Number(it, ..)) => it
    None =>
      match default {
        Some(it) => it
        None => raise LoadError("missing key \{key}")
      }
    _ as a => raise LoadError("expect number, got \{a}, key=\{key}")
  }
}

///|
pub fn NxNode::get_float(self : NxNode) -> Double raise LoadError {
  match self.desc {
    Json::Number(it) => it
    Json::Null => 0.0
    Json::String(it) =>
      @strconv.parse_double(it) catch {
        _ => raise LoadError("expect number, got \{it}, path=\{self.path}")
      }
    _ as a => raise LoadError("expect number, got \{a}, path=\{self.path}")
  }
}

///|
pub fn NxNode::iter(self : NxNode) -> Iter[NxNode] {
  match self.desc {
    Json::Object(it) =>
      it
      .iter()
      .map(fn(kv) {
        let (k, v) = kv
        { ..self, name: k, desc: v, path: self.path.push(k) }
      })
    _ => Iter::empty()
  }
}

///|
pub fn NxNode::is_null(self : NxNode) -> Bool {
  match self.desc {
    Json::Null => true
    _ => false
  }
}

///|
pub fn NxNode::as_string(self : NxNode) -> String raise LoadError {
  match self.desc {
    Json::String(it) => it
    _ as a => raise LoadError("expect string, got \{a}, path=\{self.path}")
  }
}

///|
pub fn NxNode::get_bitmap(self : NxNode) -> Bitmap? {
  try {
    match self.desc {
      { "__i": Json::String(path), .. } =>
        Some({
          // image: self.image_loader.unwrap().load_image_by_path(path),
          image: panic(),
          width: self["__w"].as_int(),
          height: self["__h"].as_int(),
        })
      { "__b": Json::Number(bid), .. } =>
        Some({
          image: self.image_loader.unwrap().load_image(bid.to_int()),
          width: self["__w"].as_int(),
          height: self["__h"].as_int(),
        })
      _ => None
    }
  } catch {
    _ => None
  }
}

///|
pub fn NxNode::get_image_loader(self : NxNode) -> ImageLoader {
  self.image_loader.unwrap()
}

///|
pub(all) struct Bitmap {
  image : Image
  width : Int
  height : Int
}

///|
pub impl ToJson for Bitmap with to_json(self) -> Json {
  {}
}

///|
fn join_path(parts : Array[String]) -> String {
  parts.join("/")
}

///|
pub(all) struct ResPath(Array[String]) derive(Eq)

///|
pub fn NxNode::as_point(self : NxNode) -> @struct.Point[Int] raise LoadError {
  match self.value() {
    [Json::Number(x, ..), Json::Number(y, ..)] =>
      { x: x.to_int(), y: y.to_int() }
    Json::Null => @struct.Point::default()
    _ as a => raise LoadError("expect array, got \{a}, path=\{self.path}")
  }
}

///|
pub fn NxNode::as_rectangle(self : NxNode) -> @struct.Rectangle[Int] raise {
  let left_top = self["lt"].as_point()
  let right_bottom = self["rb"].as_point()
  @struct.Rectangle::new(left_top, right_bottom)
}

///|
/// Array of T which json key is index
pub struct MapBasedArray[T](Array[T]) derive(Show)

///|
pub impl[T : @json.FromJson] @json.FromJson for MapBasedArray[T] with from_json(
  json,
  path,
) -> MapBasedArray[T] raise {
  parse_map_based_array(json, path~) |> MapBasedArray
}

///|
pub fn[T : @json.FromJson] parse_map_based_array(
  json : Json,
  path~ : @json.JsonPath,
) -> Array[T] raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError(
      (path, "parse_map_based_array: expected object"),
    )
  }
  let mut i = 0
  let array = Array::new()
  while true {
    let key = i.to_string()
    if obj.get(key) is Some(value) {
      let item = @json.from_json(value, path=path.add_key(key))
      array.push(item)
    } else {
      break
    }
    i += 1
  }
  array
}

///|
pub struct Nullable[T](T?) derive(Show)

///|
pub impl[T : @json.FromJson] @json.FromJson for Nullable[T] with from_json(
  json,
  path,
) {
  if json is Null {
    None
  } else {
    Some(@json.from_json(json, path~))
  }
}

///|
pub struct IntMap[T](Map[Int, T]) derive(Show)

///|
pub impl[T : @json.FromJson] @json.FromJson for IntMap[T] with from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let map = {}
  for key, value in obj {
    let k = @strconv.parse_int(key) catch {
      _ => raise @json.JsonDecodeError((path, "expect numberic string key"))
    }
    let value : T = @json.from_json(value, path=path.add_key(key))
    map[k] = value
  }
  map
}

///|
pub(all) struct EnumMap[K, V](Map[K, V]) derive(Show)

///|
pub impl[K, V] Default for EnumMap[K, V] with default() -> EnumMap[K, V] {
  EnumMap(Map::new())
}

///|
pub impl[K : ToJson, V : ToJson] ToJson for EnumMap[K, V] with to_json(self) -> Json {
  let map = Map::new(capacity=self.0.length())
  for key, value in self.0 {
    guard key.to_json() is String(key) else { abort("expect string") }
    map.set(key, value.to_json())
  }
  Json::object(map)
}

///|
pub impl[K : Eq + Hash + @json.FromJson, V : @json.FromJson] @json.FromJson for EnumMap[
  K,
  V,
] with from_json(json, path) {
  parse_enum_map(json, path~) |> EnumMap
}

///|
pub fn[K : Eq + Hash + @json.FromJson, V : @json.FromJson] parse_enum_map(
  json : Json,
  path~ : @json.JsonPath,
) -> Map[K, V] raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let map = {}
  for key, value in obj {
    let k : K = @json.from_json(Json::string(key), path=path.add_key(key))
    let value : V = @json.from_json(value, path=path.add_key(key))
    map[k] = value
  }
  map
}
