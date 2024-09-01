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

extern "js" fn name(self : ResourceLoader) -> String =
  #| (l) => {
  #|   return l.name
  #| }

extern "js" fn as_jsonstring(v : JsJson) -> String =
  #|(v)=> {
  #|  return JSON.stringify(v);
  #|}

fn as_moonjson(self : JsJson) -> @json.JsonValue {
  @json.parse?(as_jsonstring(self)).unwrap()
}

pub fn load_res(self : Loader, path : Array[String]) -> NxNode {
  if path.contains("") {
    abort("path contains empty part, path=\{path}")
  }
  {
    loader: self,
    name: path[path.length() - 1],
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

pub fn get_bool(self : NxNode) -> Result[Bool, Error] {
  self.get_int().map(fn(it) { it != 0 })
}

pub fn get_string(self : NxNode) -> String {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_string()
    @json.JsonValue::String(it) => it
    _ => ""
  }
}

pub fn get_int(self : NxNode) -> Result[Int, Error] {
  self.get_float().map(fn(it) { it.to_int() })
}

pub fn req_int(self : NxNode) -> Int! {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_int()
    _ as a => fail!("expect number, got\{a}")
  }
}

pub fn get_float(self : NxNode) -> Result[Double, Error] {
  match self.desc {
    @json.JsonValue::Number(it) => Ok(it)
    @json.JsonValue::Null => Ok(0.0)
    @json.JsonValue::String(it) =>
      try {
        Ok(@strconv.parse_double!(it))
      } catch {
        s => Err(s)
      }
    _ as a => Err(Failure("expect number, got\{a}"))
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

pub fn is_null(self : NxNode) -> Bool {
  match self.desc {
    @json.JsonValue::Null => true
    _ => false
  }
}

pub fn as_string(self : NxNode) -> Result[String, String] {
  match self.desc {
    @json.JsonValue::String(it) => Ok(it)
    _ as a => Err("expect string, got\{a}")
  }
}

pub fn to_string(self : NxNode) -> String {
  let name = self.name
  let desc = self.desc
  "(\{name}=\{desc})"
}

pub fn get_bitmap(self : NxNode) -> Bitmap? {
  self["__b"]
  .get_int()
  .to_option()
  .map(
    fn(bid) {
      {
        image: self.loader.loader.load_bitmap(bid),
        id: self.loader.name + "/" + bid.to_string(),
        width: self["__w"].get_int().unwrap(),
        height: self["__h"].get_int().unwrap(),
      }
    },
  )
}

fn load_bitmap(self : ResourceLoader, bid : Int) -> @graphics.Image = "resource" "load_bitmap"

struct Bitmap {
  image : @graphics.Image
  id : String
  width : Int
  height : Int
}

pub fn image(self : Bitmap) -> @graphics.Image {
  self.image
}

/// Global unique id
pub fn id(self : Bitmap) -> String {
  self.id
}

pub fn width(self : Bitmap) -> Int {
  self.width
}

pub fn height(self : Bitmap) -> Int {
  self.height
}

fn join_path(parts : Array[String]) -> String {
  parts.join("/")
}

pub type ResPath Array[String] derive(Eq)
