pub type ResourceLoader

pub fn ui_loader() -> ResourceLoader = "resource" "ui_loader"

pub fn sound_loader() -> ResourceLoader = "resource" "sound_loader"

pub fn map_loader() -> ResourceLoader = "resource" "map_loader"

pub fn character_loader() -> ResourceLoader = "resource" "character_loader"

pub fn string_loader() -> ResourceLoader = "resource" "string_loader"

pub fn reactor_loader() -> ResourceLoader = "resource" "reactor_loader"

pub fn map001_loader() -> ResourceLoader = "resource" "map001_loader"

pub fn map_pretty_loader() -> ResourceLoader = "resource" "map_pretty_loader"

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

pub fn load_res(self : ResourceLoader, path : Array[String]) -> NxNode {
  if path.contains("") {
    abort("path contains empty part, path=\{path}")
  }
  {
    loader: self,
    name: path[path.length() - 1],
    desc: self.load_desc(join_path(path)).as_moonjson(),
    path: path |> @immut/array.from_array,
  }
}

struct NxNode {
  loader : ResourceLoader
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

pub fn get_loader(self : NxNode) -> ResourceLoader {
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

pub fn load_bitmap(self : ResourceLoader, bid : Int) -> Bitmap = "resource" "load_bitmap"

pub type Bitmap

/// Global unique id
pub fn id(self : Bitmap) -> Int = "bitmap" "id"

pub fn width(self : Bitmap) -> Int = "bitmap" "width"

pub fn height(self : Bitmap) -> Int = "bitmap" "height"

pub fn loading(self : Bitmap) -> Bool = "bitmap" "loading"

fn join_path(parts : Array[String]) -> String {
  parts.join("/")
}

pub type ResPath Array[String] derive(Eq)
