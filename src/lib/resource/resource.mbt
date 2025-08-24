///|
#external
priv type RawData

///|
fn as_moonjson(self : RawData) -> Json {
  @json.parse(as_jsonstring(self)) catch {
    _ => abort("failed to parse moonjson")
  }
}

///|
#external
type ImageLoader

///|
#external
priv type SyncResourceLoader

///|
impl @js.Cast for SyncResourceLoader with into(it) -> SyncResourceLoader? {
  @js.Value::cast(it)
}

///|
impl @js.Cast for SyncResourceLoader with from(it) -> @js.Value {
  @js.Value::cast_from(it)
}

///|
struct SyncLoader {
  name : String
  loader : SyncResourceLoader
  image_loader : ImageLoader
}

///|
pub async fn SyncLoader::load(
  name : String,
  data_url : String,
  image_loader : ImageLoader
) -> SyncLoader raise Error {
  let loader : SyncResourceLoader = SyncResourceLoader::make(data_url).wait()
    |> @js.Value::cast
  SyncLoader::new(name, loader, image_loader)
}

///|
fn SyncLoader::new(
  name : String,
  loader : SyncResourceLoader,
  image_loader : ImageLoader
) -> SyncLoader {
  { name, loader, image_loader }
}

///|
pub fn load_res(self : SyncLoader, path : Array[String]) -> NxNode {
  {
    loader_name: self.name,
    image_loader: Some(self.image_loader),
    name: path.last().unwrap(),
    desc: self.loader.load_desc(join_path(path)).as_moonjson(),
    path: path |> @immut/array.from_array,
  }
}

///|
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
pub fn name(self : NxNode) -> String {
  self.name
}

///|
pub fn value(self : NxNode) -> Json {
  self.desc
}

///|
pub fn path(self : NxNode) -> @immut/array.T[String] {
  self.path
}

///|
pub fn op_get(self : NxNode, name : String) -> NxNode {
  {
    ..self,
    name,
    desc: self.desc.as_object().bind(fn(it) { it.get(name) }).or(Json::null()),
    path: self.path.push(name),
  }
}

///|
pub fn contains(self : NxNode, name : String) -> Bool {
  match self.desc {
    Json::Object(it) => it.contains(name)
    _ => false
  }
}

///|
pub fn get_children_count(self : NxNode) -> Int {
  match self.desc {
    Json::Object(it) => it.size()
    _ => 0
  }
}

///|
pub fn get_bool(self : NxNode) -> Bool raise LoadError {
  self.get_int() != 0
}

///|
pub fn as_strict_bool(self : NxNode) -> Bool raise LoadError {
  self.as_int() != 0
}

///|
pub fn get_string(self : NxNode) -> String {
  match self.desc {
    Json::Number(it) => it.to_string()
    Json::String(it) => it
    _ => ""
  }
}

///|
pub fn get_int(self : NxNode) -> Int raise LoadError {
  self.get_float().to_int()
}

///|
pub(all) suberror LoadError String derive(Show)

///|
pub fn as_int(self : NxNode) -> Int raise LoadError {
  match self.desc {
    Json::Number(it) => it.to_int()
    _ as a => raise LoadError("expect number, got \{a}, path=\{self.path}")
  }
}

///|
pub fn get_int_field(
  self : NxNode,
  key : String,
  default? : Int
) -> Int raise LoadError {
  match self.desc.as_object().unwrap()[key] {
    Some(Json::Number(it)) => it.to_int()
    None =>
      match default {
        Some(it) => it
        None => raise LoadError("missing key \{key}")
      }
    _ as a => raise LoadError("expect number, got \{a}, key=\{key}")
  }
}

///|
pub fn get_float_field(
  self : NxNode,
  key : String,
  default? : Double
) -> Double raise LoadError {
  match self.desc.as_object().unwrap()[key] {
    Some(Json::Number(it)) => it
    None =>
      match default {
        Some(it) => it
        None => raise LoadError("missing key \{key}")
      }
    _ as a => raise LoadError("expect number, got \{a}, key=\{key}")
  }
}

///|
pub fn get_float(self : NxNode) -> Double raise LoadError {
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
pub fn iter(self : NxNode) -> Iter[NxNode] {
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
pub fn iter2(self : NxNode) -> Iter2[String, NxNode] {
  Iter2::new(fn(yield_) {
    match self.desc {
      Json::Object(it) =>
        it
        .iter2()
        .run(fn(k, v) {
          yield_(k, { ..self, name: k, desc: v, path: self.path.push(k) })
        })
      _ => IterContinue
    }
  })
}

///|
pub fn is_null(self : NxNode) -> Bool {
  match self.desc {
    Json::Null => true
    _ => false
  }
}

///|
pub fn as_string(self : NxNode) -> String raise LoadError {
  match self.desc {
    Json::String(it) => it
    _ as a => raise LoadError("expect string, got \{a}, path=\{self.path}")
  }
}

///|
pub fn get_bitmap(self : NxNode) -> Bitmap? {
  match self.desc {
    { "__i": Json::String(path), .. } =>
      Some({
        image: self.image_loader.unwrap().load_image_by_path(path),
        id: self.loader_name + "/" + path,
        width: self["__w"].as_int?().unwrap(),
        height: self["__h"].as_int?().unwrap(),
      })
    { "__b": Json::Number(bid), .. } =>
      Some({
        image: self.image_loader.unwrap().load_image(bid.to_int()),
        id: self.loader_name + "/" + bid.to_string(),
        width: self["__w"].as_int?().unwrap(),
        height: self["__h"].as_int?().unwrap(),
      })
    _ => None
  }
}

///|
pub fn NxNode::get_image_loader(self : NxNode) -> ImageLoader {
  self.image_loader.unwrap()
}

///|
pub enum BitmapResource {
  Bid(Int, Int, Int)
  Path(String, Int, Int)
} derive(ToJson)

///|
pub impl @json.FromJson for BitmapResource with from_json(json, path) -> BitmapResource raise @json.JsonDecodeError {
  match json {
    {
      "__i": Json::String(path),
      "__w": Json::Number(w),
      "__h": Json::Number(h),
      ..
    } => BitmapResource::Path(path, w.to_int(), h.to_int())
    {
      "__b": Json::Number(bid),
      "__w": Json::Number(w),
      "__h": Json::Number(h),
      ..
    } => BitmapResource::Bid(bid.to_int(), w.to_int(), h.to_int())
    _ => raise @json.JsonDecodeError((path, "expect bitmap resource"))
  }
}

///|
pub(all) struct Bitmap {
  image : Image
  id : String
  width : Int
  height : Int
}

// ///|
// pub fn to_string(self : Bitmap) -> String {
//   "{id=\{self.id}, width=\{self.width}, height=\{self.height}}"
// }

///|
pub impl ToJson for Bitmap with to_json(self) -> Json {
  { "id": self.id.to_json() }
}

///|
fn join_path(parts : Array[String]) -> String {
  parts.join("/")
}

///|
pub(all) type ResPath Array[String] derive(Eq)

///|
pub fn as_point(self : NxNode) -> @struct.Point[Int] raise LoadError {
  match self.value() {
    [Json::Number(x), Json::Number(y)] => { x: x.to_int(), y: y.to_int() }
    Json::Null => @struct.Point::default()
    _ as a => raise LoadError("expect array, got \{a}, path=\{self.path}")
  }
}

///|
pub fn as_rectangle(self : NxNode) -> @struct.Rectangle[Int] raise {
  let left_top = self["lt"].as_point()
  let right_bottom = self["rb"].as_point()
  @struct.Rectangle::new(left_top, right_bottom)
}

///| Array of T which json key is index
pub type MapBasedArray[T] Array[T] derive(Show)

///|
pub impl[T : @json.FromJson] @json.FromJson for MapBasedArray[T] with from_json(
  json,
  path
) -> MapBasedArray[T] raise {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError(
      (path, "MapBasedArray::from_json: expected object"),
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
  MapBasedArray(array)
}

///|
pub type Nullable[T] T? derive(Show)

///|
pub impl[T : @json.FromJson] @json.FromJson for Nullable[T] with from_json(
  json,
  path
) {
  if json is Null {
    None
  } else {
    Some(@json.from_json(json, path~))
  }
}

///|
pub type IntBool Bool

///|
pub impl @json.FromJson for IntBool with from_json(json, path) -> IntBool raise @json.JsonDecodeError {
  if json is Number(it) {
    it.to_int() != 0
  } else {
    raise @json.JsonDecodeError((path, "expect number"))
  }
}

///|
pub type IntMap[T] Map[Int, T] derive(Show)

///|
pub impl[T : @json.FromJson] @json.FromJson for IntMap[T] with from_json(
  json,
  path
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let map = {}
  for key, value in obj {
    guard @strconv.parse_int?(key) is Ok(key_int) else {
      raise @json.JsonDecodeError((path.add_key(key), "expect numberic key"))
    }
    let value : T = @json.from_json(value, path=path.add_key(key))
    map[key_int] = value
  }
  map
}
