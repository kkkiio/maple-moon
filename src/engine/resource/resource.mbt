///|
fn join_path(parts : ArrayView[String]) -> String {
  parts.join("/")
}

///|
pub(all) struct ResPath(Array[String]) derive(Eq)

///|
/// Array of T which json key is index
pub struct MapBasedArray[T](Array[T]) derive(Debug)

///|
pub impl[T : @json.FromJson] @json.FromJson for MapBasedArray[T] with fn from_json(
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
pub struct Nullable[T](T?) derive(Debug)

///|
pub impl[T : @json.FromJson] @json.FromJson for Nullable[T] with fn from_json(
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
pub struct IntMap[T](Map[Int, T]) derive(Debug)

///|
pub impl[T : @json.FromJson] @json.FromJson for IntMap[T] with fn from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let map = Map([])
  for key, value in obj {
    let k = @string.parse_int(key) catch {
      _ => raise @json.JsonDecodeError((path, "expect numberic string key"))
    }
    let value : T = @json.from_json(value, path=path.add_key(key))
    map[k] = value
  }
  map
}

///|
pub(all) struct EnumMap[K, V](Map[K, V]) derive(Debug)

///|
pub impl[K : Eq + Hash, V] Default for EnumMap[K, V] with fn default() -> EnumMap[
  K,
  V,
] {
  EnumMap(Map([]))
}

///|
pub impl[K : ToJson, V : ToJson] ToJson for EnumMap[K, V] with fn to_json(self) -> Json {
  let map = Map([], capacity=self.0.length())
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
] with fn from_json(json, path) {
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
  let map = Map([])
  for key, value in obj {
    let k : K = @json.from_json(Json::string(key), path=path.add_key(key))
    let value : V = @json.from_json(value, path=path.add_key(key))
    map[k] = value
  }
  map
}
