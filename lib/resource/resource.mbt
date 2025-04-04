///|
priv extern type RawData

///|
fn as_moonjson(self : RawData) -> @json.JsonValue {
  @json.parse?(as_jsonstring(self)).unwrap()
}

///|
priv extern type ImageLoader

///|
priv extern type ResourceLoader

///|
/// @alert deprecated "Use `AsyncLoader` instead"
struct SyncLoader {
  name : String
  loader : ResourceLoader
}

///|
pub fn SyncLoader::new(name : String) -> SyncLoader {
  { name, loader: get_resource_loader(name) }
}

///|
pub fn string_loader() -> SyncLoader {
  { name: "string", loader: get_resource_loader("string") }
}

///|
pub fn load_res(self : SyncLoader, path : Array[String]) -> NxNode {
  {
    loader_name: self.name,
    image_loader: Some(self.loader.get_image_loader()),
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
  desc : @json.JsonValue
  path : @immut/array.T[String]
}

///|
pub fn NxNode::from_test_value(value : @json.JsonValue) -> NxNode {
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
pub fn value(self : NxNode) -> @json.JsonValue {
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
    desc: self.desc
    .as_object()
    .bind(fn(it) { it[name] })
    .or(@json.JsonValue::Null),
    path: self.path.push(name),
  }
}

///|
pub fn contains(self : NxNode, name : String) -> Bool {
  match self.desc {
    @json.JsonValue::Object(it) => it.contains(name)
    _ => false
  }
}

///|
pub fn get_children_count(self : NxNode) -> Int {
  match self.desc {
    @json.JsonValue::Object(it) => it.size()
    _ => 0
  }
}

///|
pub fn get_bool(self : NxNode) -> Bool!LoadError {
  self.get_int!() != 0
}

///|
pub fn as_strict_bool(self : NxNode) -> Bool!LoadError {
  self.as_int!() != 0
}

///|
pub fn get_string(self : NxNode) -> String {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_string()
    @json.JsonValue::String(it) => it
    _ => ""
  }
}

///|
pub fn get_int(self : NxNode) -> Int!LoadError {
  self.get_float!().to_int()
}

///|
pub(all) type! LoadError String derive(Show)

///|
pub fn as_int(self : NxNode) -> Int!LoadError {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_int()
    _ as a => raise LoadError("expect number, got \{a}, path=\{self.path}")
  }
}

///|
pub fn get_int_field(
  self : NxNode,
  key : String,
  default? : Int
) -> Int!LoadError {
  match self.desc.as_object().unwrap()[key] {
    Some(@json.JsonValue::Number(it)) => it.to_int()
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
) -> Double!LoadError {
  match self.desc.as_object().unwrap()[key] {
    Some(@json.JsonValue::Number(it)) => it
    None =>
      match default {
        Some(it) => it
        None => raise LoadError("missing key \{key}")
      }
    _ as a => raise LoadError("expect number, got \{a}, key=\{key}")
  }
}

///|
pub fn get_float(self : NxNode) -> Double!LoadError {
  match self.desc {
    @json.JsonValue::Number(it) => it
    @json.JsonValue::Null => 0.0
    @json.JsonValue::String(it) =>
      try {
        @strconv.parse_double!(it)
      } catch {
        _ => raise LoadError("expect number, got \{it}, path=\{self.path}")
      }
    _ as a => raise LoadError("expect number, got \{a}, path=\{self.path}")
  }
}

///|
pub fn iter(self : NxNode) -> Iter[NxNode] {
  match self.desc {
    @json.JsonValue::Object(it) =>
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
      @json.JsonValue::Object(it) =>
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
    @json.JsonValue::Null => true
    _ => false
  }
}

///|
pub fn as_string(self : NxNode) -> String!LoadError {
  match self.desc {
    @json.JsonValue::String(it) => it
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
  @string.concat(parts, separator="/")
}

///|
pub(all) type ResPath Array[String] derive(Eq)

///|
pub fn as_point(self : NxNode) -> @struct.Point[Int]!LoadError {
  match self.value() {
    [Json::Number(x), Json::Number(y)] => { x: x.to_int(), y: y.to_int() }
    @json.JsonValue::Null => @struct.Point::default()
    _ as a => raise LoadError("expect array, got \{a}, path=\{self.path}")
  }
}

///|
pub fn as_rectangle(self : NxNode) -> @struct.Rectangle[Int]! {
  let left_top = self["lt"].as_point!()
  let right_bottom = self["rb"].as_point!()
  @struct.Rectangle::new(left_top, right_bottom)
}
