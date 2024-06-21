type ResourceLoader

fn ui_loader() -> ResourceLoader = "resource" "ui_loader"

fn sound_loader() -> ResourceLoader = "resource" "sound_loader"

fn map_loader() -> ResourceLoader = "resource" "map_loader"

fn character_loader() -> ResourceLoader = "resource" "character_loader"

fn string_loader() -> ResourceLoader = "resource" "string_loader"

type JsJson

extern "js" fn load_desc(self : ResourceLoader, nodepath : String) -> JsJson =
  #| (l,n) => {
  #|   return l.load(n)
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
  @json.parse(as_jsonstring(self)).unwrap()
}

pub fn load_res(self : ResourceLoader, nodepath : String) -> NxNode {
  { loader: self, desc: self.load_desc(nodepath).as_moonjson(), path: nodepath }
}

fn load_bitmap(self : ResourceLoader, bid : Int) -> Bitmap = "resource" "load_bitmap"

pub fn make_nodepath(parts : Array[String]) -> String {
  let total = parts.fold_left(fn(acc, it) { acc + it.length() }, init=0)
  let buf = Buffer::make(total + parts.length() - 1)
  parts.iteri(
    fn(i, it) {
      if i > 0 {
        buf.write_char('/')
      }
      buf.write_string(it)
    },
  )
  buf.to_string()
}

struct NxNode {
  loader : ResourceLoader
  desc : @json.JsonValue
  path : String
}

pub fn to_string(self : NxNode) -> String {
  self.desc.to_string()
}

pub fn op_get(self : NxNode, key : String) -> NxNode {
  {
    loader: self.loader,
    desc: self.desc.as_object().bind(fn(it) { it[key] }).or(
      @json.JsonValue::Null,
    ),
    path: self.path + "/\(key)",
  }
}

pub fn get_bool(self : NxNode) -> Bool {
  self.desc.as_number().map(fn(it) { it.to_int() != 0 }).or(false)
}

pub fn get_string(self : NxNode) -> String {
  match self.desc {
    @json.JsonValue::Number(it) => it.to_string()
    @json.JsonValue::String(it) => it
    _ => ""
  }
}

pub fn get_int(self : NxNode) -> Int {
  self.desc.as_number().map(fn(it) { it.to_int() }).or(0)
}

pub fn get_float(self : NxNode) -> Double {
  self.desc.as_number().or(0.0)
}

pub fn get_object(self : NxNode) -> Map[String, NxNode] {
  match self.desc.as_object() {
    Some(obj) => {
      let res = Map::new(capacity=obj.size())
      obj.iter(
        fn(k, v) {
          res.set(
            k,
            { loader: self.loader, desc: v, path: self.path + "/\(k)" },
          )
        },
      )
      res
    }
    None => Map::new()
  }
}

pub fn is_null(self : NxNode) -> Bool {
  match self.desc {
    @json.JsonValue::Null => true
    _ => false
  }
}

type Bitmap

/// Global unique id
fn id(self : Bitmap) -> Int = "bitmap" "id"

fn width(self : Bitmap) -> Int = "bitmap" "width"

fn height(self : Bitmap) -> Int = "bitmap" "height"

fn loading(self : Bitmap) -> Bool = "bitmap" "loading"
