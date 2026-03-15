///|
#external
type ImageLoader

///|
#deprecated("use Json instead")
struct NxNode {
  name : String
  desc : Json
  path : @immut/array.T[String]
}

///|
pub fn NxNode::value(self : NxNode) -> Json {
  self.desc
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
pub(all) suberror LoadError {
  LoadError(String)
} derive(Show)

///|
pub fn NxNode::iter(self : NxNode) -> Iter[NxNode] {
  match self.desc {
    Json::Object(it) =>
      it
      .iter()
      .map(fn(kv) {
        let (k, v) = kv
        { name: k, desc: v, path: self.path.push(k) }
      })
    _ => Iter::empty()
  }
}

///|
fn join_path(parts : ArrayView[String]) -> String {
  parts.join("/")
}

///|
pub(all) struct ResPath(Array[String]) derive(Eq)

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
