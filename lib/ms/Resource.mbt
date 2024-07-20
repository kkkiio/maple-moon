type ResourceLoader

fn ui_loader() -> ResourceLoader = "resource" "ui_loader"

fn sound_loader() -> ResourceLoader = "resource" "sound_loader"

fn map_loader() -> ResourceLoader = "resource" "map_loader"

fn character_loader() -> ResourceLoader = "resource" "character_loader"

fn string_loader() -> ResourceLoader = "resource" "string_loader"

fn reactor_loader() -> ResourceLoader = "resource" "reactor_loader"

fn map001_loader() -> ResourceLoader = "resource" "map001_loader"

fn map_pretty_loader() -> ResourceLoader = "resource" "map_pretty_loader"

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
  @json.parse(as_jsonstring(self))!!.unwrap()
}

pub fn load_res(self : ResourceLoader, path : Array[String]) -> NxNode {
  if path.contains("") {
    abort("path contains empty part, path=\(path)")
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
  path : @immut/array.ImmutableVec[String]
}

pub fn op_get(self : NxNode, key : String) -> NxNode {
  {
    loader: self.loader,
    name: key,
    desc: self.desc.as_object().bind(fn(it) { it[key] }).or(
      @json.JsonValue::Null,
    ),
    path: self.path.push(key),
  }
}

pub fn get_bool(self : NxNode) -> Result[Bool, String] {
  self.get_int().map(fn(it) { it != 0 })
}

pub fn get_string(self : NxNode) -> String {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_string()
    @json.JsonValue::String(it) => it
    _ => ""
  }
}

pub fn get_int(self : NxNode) -> Result[Int, String] {
  self.get_float().map(fn(it) { it.to_int() })
}

pub fn get_float(self : NxNode) -> Result[Double, String] {
  match self.desc {
    @json.JsonValue::Number(it) => Ok(it)
    @json.JsonValue::Null => Ok(0.0)
    @json.JsonValue::String(it) =>
      try {
        Ok(@strconv.parse_double!(it))
      } catch {
        s => Err(s)
      }
    _ as a => Err("expect number, got\(a)")
  }
}

pub fn get_object(self : NxNode) -> Map[String, NxNode] {
  match self.desc.as_object() {
    Some(obj) => {
      let res = Map::new(capacity=obj.size())
      obj.each(
        fn(k, v) {
          res.set(
            k,
            { loader: self.loader, name: k, desc: v, path: self.path.push(k) },
          )
        },
      )
      res
    }
    None => Map::new()
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
    _ as a => abort("expect object, got\(a)")
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
    _ as a => Err("expect string, got\(a)")
  }
}

pub fn to_string(self : NxNode) -> String {
  let name = self.name
  let desc = self.desc
  "(\(name)=\(desc))"
}

fn load_bitmap(self : ResourceLoader, bid : Int) -> Bitmap = "resource" "load_bitmap"

type Bitmap

/// Global unique id
fn id(self : Bitmap) -> Int = "bitmap" "id"

fn width(self : Bitmap) -> Int = "bitmap" "width"

fn height(self : Bitmap) -> Int = "bitmap" "height"

fn loading(self : Bitmap) -> Bool = "bitmap" "loading"

fn join_path(parts : Array[String]) -> String {
  parts.join("/")
}

pub type ResPath Array[String] derive(Eq)

pub fn get_point(self : NxNode) -> Result[Point[Int], String] {
  match self.desc {
    @json.JsonValue::Array(arr) =>
      Ok(
        {
          x: arr[0].as_number().unwrap().to_int(),
          y: arr[1].as_number().unwrap().to_int(),
        },
      )
    @json.JsonValue::Null => Point::default() |> Ok
    _ as a => Err("expect array, got \(a)")
  }
}
