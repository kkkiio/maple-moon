type ResourceLoader

fn get_resource_loader(name : Js_string) -> ResourceLoader = "resource" "get_loader"

struct Loader {
  name : String
  loader : ResourceLoader
}

pub fn Loader::new(name : String) -> Loader {
  { name, loader: get_resource_loader(name.to_js_string()) }
}

pub fn ui_loader() -> Loader {
  { name: "ui", loader: get_resource_loader("ui".to_js_string()) }
}

pub fn sound_loader() -> Loader {
  { name: "sound", loader: get_resource_loader("sound".to_js_string()) }
}

pub fn map_loader() -> Loader {
  { name: "map", loader: get_resource_loader("map".to_js_string()) }
}

pub fn character_loader() -> Loader {
  { name: "character", loader: get_resource_loader("character".to_js_string()) }
}

pub fn string_loader() -> Loader {
  { name: "string", loader: get_resource_loader("string".to_js_string()) }
}

pub fn reactor_loader() -> Loader {
  { name: "reactor", loader: get_resource_loader("reactor".to_js_string()) }
}

pub fn map001_loader() -> Loader {
  { name: "map001", loader: get_resource_loader("map001".to_js_string()) }
}

pub fn map_pretty_loader() -> Loader {
  {
    name: "map_pretty",
    loader: get_resource_loader("map_pretty".to_js_string()),
  }
}

type JsJson

extern "js" fn load_desc(self : ResourceLoader, path : String) -> JsJson =
  #| (l,p) => {
  #|   return l.loadDesc(p)
  #| }

extern "js" fn as_jsonstring(v : JsJson) -> String =
  #|(v)=> {
  #|  return JSON.stringify(v);
  #|}

fn as_moonjson(self : JsJson) -> @json.JsonValue {
  @json.parse?(as_jsonstring(self)).unwrap()
}

pub fn load_res(self : Loader, path : Array[String]) -> NxNode {
  {
    loader: self,
    name: path.last().unwrap(),
    desc: self.loader.load_desc(join_path(path)).as_moonjson(),
    path: path |> @immut/array.from_array,
  }
}

struct NxNode {
  loader : Loader
  name : String
  desc : @json.JsonValue
  path : @immut/array.T[String]
}

pub fn name(self : NxNode) -> String {
  self.name
}

pub fn value(self : NxNode) -> @json.JsonValue {
  self.desc
}

pub fn path(self : NxNode) -> @immut/array.T[String] {
  self.path
}

pub fn get_loader(self : NxNode) -> Loader {
  self.loader
}

pub fn op_get(self : NxNode, key : String) -> NxNode {
  {
    loader: self.loader,
    name: key,
    desc: self.desc
    .as_object()
    .bind(fn(it) { it[key] })
    .or(@json.JsonValue::Null),
    path: self.path.push(key),
  }
}

pub fn get_children_count(self : NxNode) -> Int {
  match self.desc {
    @json.JsonValue::Object(it) => it.size()
    _ => 0
  }
}

pub fn get_bool(self : NxNode) -> Bool!LoadError {
  self.get_int!() != 0
}

pub fn as_strict_bool(self : NxNode) -> Bool!LoadError {
  self.as_strict_int!() != 0
}

pub fn get_string(self : NxNode) -> String {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_string()
    @json.JsonValue::String(it) => it
    _ => ""
  }
}

pub fn get_int(self : NxNode) -> Int!LoadError {
  self.get_float!().to_int()
}

pub type! LoadError {
  TypeMismatch(String)
  ParseNumber(@strconv.StrConvError)
}

pub fn as_strict_int(self : NxNode) -> Int!LoadError {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_int()
    _ as a => raise TypeMismatch("expect number, got \{a}, path=\{self.path}")
  }
}

pub fn get_float(self : NxNode) -> Double!LoadError {
  match self.desc {
    @json.JsonValue::Number(it) => it
    @json.JsonValue::Null => 0.0
    @json.JsonValue::String(it) =>
      try {
        @strconv.parse_double!(it)
      } catch {
        e => raise ParseNumber(e)
      }
    _ as a => raise TypeMismatch("expect number, got \{a}, path=\{self.path}")
  }
}

pub fn each(self : NxNode, f : (NxNode) -> Unit) -> Unit {
  match self.desc {
    @json.JsonValue::Object(it) =>
      it.each(
        fn(k, v) {
          f({ loader: self.loader, name: k, desc: v, path: self.path.push(k) })
        },
      )
    @json.JsonValue::Null => ()
    _ as a => abort("expect object, got\{a}")
  }
}

pub fn iter(self : NxNode) -> Iter[NxNode] {
  match self.desc {
    @json.JsonValue::Object(it) =>
      it
      .iter()
      .map(
        fn(kv) {
          let (k, v) = kv
          { loader: self.loader, name: k, desc: v, path: self.path.push(k) }
        },
      )
    _ => Iter::empty()
  }
}

pub fn is_null(self : NxNode) -> Bool {
  match self.desc {
    @json.JsonValue::Null => true
    _ => false
  }
}

pub fn as_string(self : NxNode) -> String!LoadError {
  match self.desc {
    @json.JsonValue::String(it) => it
    _ as a => raise TypeMismatch("expect string, got \{a}")
  }
}

pub fn to_string(self : NxNode) -> String {
  let name = self.name
  let desc = self.desc
  "(\{name}=\{desc})"
}

pub fn get_bitmap(self : NxNode) -> Bitmap? {
  self["__b"]
  .as_strict_int?()
  .to_option()
  .map(
    fn(bid) {
      {
        image: self.loader.loader.load_bitmap(bid),
        id: self.loader.name + "/" + bid.to_string(),
        width: self["__w"].as_strict_int?().unwrap(),
        height: self["__h"].as_strict_int?().unwrap(),
      }
    },
  )
}

fn load_bitmap(self : ResourceLoader, bid : Int) -> Image = "resource" "load_bitmap"

pub struct Bitmap {
  image : Image
  id : String
  width : Int
  height : Int
}

pub fn to_string(self : Bitmap) -> String {
  "{id=\{self.id}, width=\{self.width}, height=\{self.height}}"
}

fn join_path(parts : Array[String]) -> String {
  parts.join("/")
}

pub type ResPath Array[String] derive(Eq)

pub fn as_point(self : NxNode) -> @struct.Point[Int]!LoadError {
  match self.value() {
    @json.JsonValue::Array(arr) =>
      {
        x: arr[0].as_number().unwrap().to_int(),
        y: arr[1].as_number().unwrap().to_int(),
      }
    @json.JsonValue::Null => @struct.Point::default()
    _ as a => raise TypeMismatch("expect array, got \{a}")
  }
}

pub fn as_rectangle(self : NxNode) -> @struct.Rectangle[Int]! {
  let left_top = self["lt"].as_point!()
  let right_bottom = self["rb"].as_point!()
  @struct.Rectangle::new(left_top, right_bottom)
}
