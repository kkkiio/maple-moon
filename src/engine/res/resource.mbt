///|
/// Decode an NX object whose decimal string keys form a zero-based array.
///
/// Decoding stops at the first missing index, matching NX map-based array
/// semantics.
///
/// # Example
/// ```moonbit nocheck
/// let values : MapBasedArray[Int] = try! @json.from_json({ "0": 7, "1": 9 })
/// ignore(values)
/// ```
pub struct MapBasedArray[T](Array[T]) derive(Debug)

///|
pub impl[T : @json.FromJson] @json.FromJson for MapBasedArray[T] with fn from_json(
  json,
  path,
) -> MapBasedArray[T] raise {
  parse_map_based_array(json, path~) |> MapBasedArray
}

///|
/// Decode an NX map-based array into a plain MoonBit array.
///
/// # Example
/// ```moonbit nocheck
/// let values : Array[Int] = try! parse_map_based_array(
///   { "0": 7, "1": 9 },
///   path=@json.JsonPath::root(),
/// )
/// assert_eq(values.length(), 2)
/// ```
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
/// Decode JSON `null` as `None` and every other value as `Some(T)`.
///
/// # Example
/// ```moonbit nocheck
/// let value : Nullable[Int] = try! @json.from_json(null)
/// ignore(value)
/// ```
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
/// Decode an object with decimal string keys into an integer-keyed map.
///
/// # Example
/// ```moonbit nocheck
/// let values : IntMap[String] = try! @json.from_json({ "100": "Slime" })
/// ignore(values)
/// ```
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
/// A public map wrapper whose keys encode through their JSON representation.
///
/// # Example
/// ```moonbit nocheck
/// let values : EnumMap[Int, String] = EnumMap(Map([(1, "one")]))
/// ignore(values)
/// ```
/// The wrapped key/value map.
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
/// Decode an object into a map using `K`'s JSON decoder for every object key.
///
/// # Example
/// ```moonbit nocheck
/// let values : Map[Int, String] = try! parse_enum_map(
///   { "1": "one" },
///   path=@json.JsonPath::root(),
/// )
/// assert_eq(values.get(1), Some("one"))
/// ```
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
