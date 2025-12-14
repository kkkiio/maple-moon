///|
const BASE_URL : String = "https://maple-res.kkkiiox.work"

///|
/// fill `__off` for each frame json from the spritesheet json and return the new json.
/// the `__off` is the offset (x,y) of the frame in the spritesheet.
/// maybe cache the spritesheet json under the `/tmp/` directory
/// 
/// for example, before:
/// {
/// 			"__h": 14,
/// 			"__w": 8,
/// 			"group": "skin",
/// 			"map": { "hand": [-5, 5], "navel": [-11, 1] },
/// 			"origin": [6, 8],
/// 			"z": "armOverHair",
/// 			"__i": "/Character/Body/spritesheets/00002000.img#36"
/// 		}
/// after:
/// {
/// 			"__h": 14,
/// 			"__w": 8,
/// 			"group": "skin",
/// 			"map": { "hand": [-5, 5], "navel": [-11, 1] },
/// 			"origin": [6, 8],
/// 			"z": "armOverHair",
/// 			"__i": "/Character/Body/spritesheets/00002000.img.png"
/// 			"__off": [444, 244]
/// 		}
/// we can get the offset from the `jq '.frames."36.png".frame' http://maple-res.kkkiiox.work/Character/Body/spritesheets/00002000.img.json`
async fn fill_offset_from_spritesheet_json(frame_json : Json) -> Json? {
  guard frame_json is { "__i": String(spritesheet_path), .. } &&
    spritesheet_path.contains("#") else {
    return None
  }

  // split path and frame key
  guard spritesheet_path.split("#").to_array() is [sheet_name, frame_name] else {
    return None
  }
  let image_path = sheet_name + ".png"
  let frame_key = frame_name + ".png"

  // build remote url and local cache path
  let path = sheet_name.to_string() + ".json"
  let path = if path.has_prefix("/") { path } else { "/" + path }
  let spritesheet_json_url = BASE_URL + path
  let sanitized = sheet_name.replace(old="/", new="_")
  let cache_path = "/tmp/resprite" + sanitized.to_string() + ".json"

  // load spritesheet json from cache or remote
  let cached = Some(@json.parse(@fs.read_file_to_string(cache_path))) catch {
    _ => None
  }
  let sheet_json = match cached {
    Some(json) => json
    None => {
      let fetched = fetch_string(spritesheet_json_url)
      let j = @json.parse(fetched) catch {
        e =>
          fail(
            "failed to parse spritesheet json, error=\{e}, path=\{spritesheet_json_url}",
          )
      }
      @fs.write_string_to_file(cache_path, fetched) catch {
        _ => ()
      }
      j
    }
  }
  guard sheet_json is { "frames": Object(frames), .. } else {
    fail("missing frames in spritesheet json, path=\{spritesheet_json_url}")
  }
  guard frames.get(frame_key.to_string()) is Some(v) else {
    fail(
      "missing frame in spritesheet json, path=\{spritesheet_json_url}, frame_key=\{frame_key}",
    )
  }
  match v {
    { "frame": { "x": Number(x, ..), "y": Number(y, ..), .. }, .. } => {
      let new_obj = {}
      for k, v in frame_json.as_object().unwrap() {
        new_obj[k] = v
      }
      new_obj["__off"] = Json::array([Json::number(x), Json::number(y)])
      new_obj["__i"] = Json::string(image_path.to_string())
      Some(Json::object(new_obj))
    }
    _ => None
  }
}

///|
extern "js" fn fetch_string_ffi(url : String) -> String =
  #| (url) => fetch(url).then(it => it.text()).catch(err => JSON.stringify(err))

///|
let cache_map : Map[String, @js.Promise] = Map::new()

///|
async fn fetch_string(url : String) -> String {
  if cache_map.get(url) is Some(s) {
    return s.wait() |> @js.Value::cast
  }
  let p : @js.Promise = @js.Value::cast_from(fetch_string_ffi(url)).cast()
  cache_map.set(url, p)
  let fetched = p.wait() |> @js.Value::cast
  // println("path=\{url}, fetched=\{fetched}")
  fetched
}

///|
/// replace the json with the new json in preorder. 
/// if process returns Some(new_json), which means the replace is done, return the new json.
/// otherwise, continue to replace the children nodes.
async fn preorder_replace(json : Json, process : async (Json) -> Json?) -> Json {
  if process(json) is Some(new_json) {
    return new_json
  }
  match json {
    Object(obj) => {
      let fs : Array[async () -> (String, Json)] = obj
        .iter()
        .map(fn(it) {
          async fn() {
            let (key, value) = it
            (key, preorder_replace(value, process))
          }
        })
        .to_array()
      let rs : Array[(String, Json)] = @js.async_all(fs) catch {
        e => {
          let jserr = @js.Value::cast_from(e)
          fail("failed to preorder replace, error=\{jserr.to_json_string()}")
        }
      }
      for it in rs {
        let (key, value) = it
        let new_json = preorder_replace(value, process)
        obj[key] = new_json
      }
      json
    }
    Array(arr) => {
      for index, value in arr {
        let new_json = preorder_replace(value, process)
        arr[index] = new_json
      }
      json
    }
    _ => json
  }
}

///|
async fn process_file(path : String) -> Unit {
  let data = @fs.read_file_to_string(path)
  let data_json = @json.parse(data)
  let new_json = preorder_replace(data_json, fill_offset_from_spritesheet_json)
  let new_json_string = new_json.stringify()
  @fs.write_string_to_file(path, new_json_string)
}

///|
fn main {
  let args = @sys.get_cli_args()
  println(args)
  let path = args[1]
  @js.async_run(fn() {
    process_file(path) catch {
      e => {
        println(e)
        @sys.exit(1)
      }
    }
  })
}
